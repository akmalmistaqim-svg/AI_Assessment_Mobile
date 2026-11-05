import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dexa_assessment_mobile/student/fastapi_student_repository.dart';
import 'package:dexa_assessment_mobile/student/student_repository.dart';

class NativeHttp extends HttpOverrides {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late HttpServer server;
  late FastApiStudentRepository repo;
  late HttpOverrides? oldOverrides;
  final calls = <String>[];
  final bodies = <Map<String, dynamic>>[];
  String account = 'a';
  String role = 'MAHASISWA';
  int? forceStatus;
  String forceDetail = 'not for display';
  bool malformed = false, delay = false;
  final tokenHeaders = <String?>[];
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    oldOverrides = HttpOverrides.current;
    HttpOverrides.global = NativeHttp();
    calls.clear();
    bodies.clear();
    tokenHeaders.clear();
    account = 'a';
    role = 'MAHASISWA';
    forceStatus = null;
    forceDetail = 'not for display';
    malformed = false;
    delay = false;
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      calls.add('${request.method} ${request.uri.path}');
      tokenHeaders.add(request.headers.value(HttpHeaders.authorizationHeader));
      if (request.method == 'POST') {
        bodies.add(
          jsonDecode(await utf8.decoder.bind(request).join())
              as Map<String, dynamic>,
        );
      }
      if (delay) await Future<void>.delayed(const Duration(milliseconds: 200));
      if (forceStatus != null) {
        request.response.statusCode = forceStatus!;
        if (forceStatus == 302) {
          request.response.headers.set(
            HttpHeaders.locationHeader,
            '/must-not-follow',
          );
        }
        request.response.write(jsonEncode({'detail': forceDetail}));
      } else if (malformed) {
        request.response.write('<html>not json</html>');
      } else {
        final Object data;
        switch (request.uri.path) {
          case '/auth/login':
            data = {
              'access_token': 'test-token-$account',
              'token_type': 'Bearer',
              'user': {'id': account, 'role': role},
            };
          case '/auth/me':
            data = {
              'id': account,
              'role': role,
              'name': 'Student test',
              'email': 'a@example.invalid',
            };
          case '/classes/join':
            request.response.statusCode = 201;
            data = {
              'success': true,
              'classId': 'class-1',
              'className': 'Rekayasa Perangkat Lunak',
            };
          case '/classes':
            data = [
              {
                'id': 'class-1',
                'name': 'Rekayasa Perangkat Lunak',
                'subject': 'RPL-2026',
                'dosen': {'name': 'Dosen A'},
                'isArchived': false,
              },
              {'id': 'archived', 'name': 'Kelas lama', 'isArchived': true},
            ];
          case '/classes/class-1/assignments':
            data = [
              {
                'id': 'task-1',
                'title': 'Tugas diterbitkan',
                'status': 'PUBLISHED',
                'dueDate': '2026-11-01T10:00:00+07:00',
                'instructions': 'Instruksi tugas asli.',
              },
              {
                'id': 'task-2',
                'title': 'Tugas ditutup',
                'status': 'CLOSED',
                'dueDate': null,
              },
              {
                'id': 'draft',
                'title': 'Tidak boleh terlihat',
                'status': 'DRAFT',
              },
            ];
          case '/grades':
            Map<String, dynamic> grade(
              String id,
              String status,
              String releasedId,
            ) => {
              'id': id,
              'status': status,
              'finalScore': 88.5,
              'finalFeedback': 'Umpan balik dosen.',
              'createdAt': '2026-10-28T01:00:00Z',
              'submission': {
                'releasedGradeId': releasedId,
                'assignment': {
                  'title': 'Tugas diterbitkan',
                  'maxScore': 100,
                  'class': {'name': 'Rekayasa Perangkat Lunak'},
                },
              },
            };
            data = [
              grade('grade-1', 'RELEASED', 'grade-1'),
              grade('draft', 'DRAFT', 'draft'),
              grade('old', 'RELEASED', 'new'),
            ];
          default:
            request.response.statusCode = 404;
            data = {'detail': 'Unknown route'};
        }
        request.response.headers.contentType = ContentType.json;
        request.response.write(jsonEncode(data));
      }
      await request.response.close();
    });
    repo = FastApiStudentRepository(
      baseUri: Uri.parse('http://127.0.0.1:${server.port}'),
      allowInsecureDevelopment: true,
    );
  });
  tearDown(() async {
    await server.close(force: true);
    HttpOverrides.global = oldOverrides;
  });
  Matcher failure(FailureKind kind) =>
      isA<StudentFailure>().having((e) => e.kind, 'kind', kind);

  test(
    'real HTTP serialization matches FastAPI and uses Bearer headers',
    () async {
      final session = await repo.signIn(' A@EXAMPLE.INVALID ', ' password ');
      expect(bodies.single, {
        'email': 'a@example.invalid',
        'password': ' password ',
      });
      expect(tokenHeaders.first, null);
      expect(session.isStudent, true);
      final profile = await repo.fetchProfile(session);
      expect(profile.name, 'Student test');
      expect(profile.email, 'a@example.invalid');
      expect(profile.studentNumber, null);
      expect(profile.program, null);
      expect(tokenHeaders.last, 'Bearer test-token-a');
      final information = await repo.fetchAnnouncements(session);
      expect(information.map((i) => i.id), ['task:task-1', 'task:task-2']);
      expect(information.first.content, contains('Instruksi tugas asli.'));
      expect(information.last.category, 'Tugas ditutup');
      expect(calls.any((c) => c.contains('archived/assignments')), false);
      final notifications = await repo.fetchNotifications(session);
      expect(notifications.length, 1);
      expect(notifications.single.id, 'grade:grade-1');
      expect(notifications.single.content, contains('88.5/100'));
      expect(notifications.single.content, contains('Umpan balik dosen.'));
      expect(
        calls.any(
          (c) => c.contains('/notifications') || c.contains('/announcements'),
        ),
        false,
      );
    },
  );
  test(
    'classes and join use real contract, normalized code and bearer token',
    () async {
      final session = await repo.signIn('a@example.invalid', 'password');
      final courses = await repo.fetchClasses(session);
      expect(courses.length, 2);
      expect(courses.first.lecturer, 'Dosen A');
      expect(courses.first.subject, 'RPL-2026');
      expect(courses.last.archived, true);
      final joined = await repo.joinClass(session, ' rpl123 ');
      expect(joined.id, 'class-1');
      expect(bodies.last, {'enrollmentKey': 'RPL123'});
      expect(calls.last, 'POST /classes/join');
      expect(tokenHeaders.last, 'Bearer test-token-a');
      final tasks = await repo.fetchClassAssignments(session, courses.first);
      expect(tasks.map((t) => t.id), ['task:task-1', 'task:task-2']);
      expect(tasks.any((t) => t.title.contains('Tidak boleh')), false);
    },
  );
  test('join reports invalid, archived, duplicate, expired and unauthorized without leaking raw errors', () async {
    final session = await repo.signIn('a@example.invalid', 'password');
    await expectLater(
      repo.joinClass(session, ' '),
      throwsA(failure(FailureKind.invalidClassCode)),
    );
    expect(calls.length, 1);
    forceStatus = 404;
    await expectLater(
      repo.joinClass(session, 'wrong'),
      throwsA(failure(FailureKind.invalidClassCode)),
    );
    forceStatus = 400;
    forceDetail = 'Anda sudah terdaftar di kelas ini.';
    await expectLater(
      repo.joinClass(session, 'code'),
      throwsA(failure(FailureKind.alreadyEnrolled)),
    );
    forceDetail = 'Kelas ini sudah diarsipkan oleh dosen pengajar.';
    await expectLater(
      repo.joinClass(session, 'code'),
      throwsA(failure(FailureKind.archivedClass)),
    );
    forceDetail = 'internal text must never appear';
    await expectLater(
      repo.joinClass(session, 'code'),
      throwsA(failure(FailureKind.joinRejected)),
    );
    forceStatus = 401;
    await expectLater(
      repo.joinClass(session, 'code'),
      throwsA(failure(FailureKind.expired)),
    );
    forceStatus = 403;
    await expectLater(
      repo.joinClass(session, 'code'),
      throwsA(failure(FailureKind.accessDenied)),
    );
  });
  test(
    'local read receipts persist and are isolated by account and backend',
    () async {
      final a = await repo.signIn('a@example.invalid', 'password');
      await Future.wait([
        repo.markRead(a, 'grade:grade-1'),
        repo.markRead(a, 'grade:grade-2'),
      ]);
      final restored = FastApiStudentRepository(
        baseUri: repo.baseUri,
        allowInsecureDevelopment: true,
      );
      final again = await restored.signIn('a@example.invalid', 'password');
      expect((await restored.fetchNotifications(again)).single.isRead, true);
      account = 'b';
      final b = await repo.signIn('b@example.invalid', 'password');
      expect((await repo.fetchNotifications(b)).single.isRead, false);
      final preferences = await SharedPreferences.getInstance();
      final keys = preferences.getKeys();
      expect(keys.length, 1);
      expect(preferences.getStringList(keys.single)!.toSet(), {
        'grade:grade-1',
        'grade:grade-2',
      });
      expect(
        preferences.get(keys.single).toString(),
        isNot(contains('test-token')),
      );
      expect(keys.single, isNot(contains('dexa_read_notification_ids')));
    },
  );
  test('logout drops the bearer token immediately without network', () async {
    final session = await repo.signIn('a@example.invalid', 'password');
    await repo.signOut(session);
    await expectLater(
      repo.fetchProfile(session),
      throwsA(failure(FailureKind.expired)),
    );
    expect(calls, ['POST /auth/login']);
  });
  test(
    'rejects profile belonging to another account or non-student role',
    () async {
      final session = await repo.signIn('a@example.invalid', 'password');
      account = 'b';
      await expectLater(
        repo.fetchProfile(session),
        throwsA(failure(FailureKind.expired)),
      );
      account = 'a';
      role = 'DOSEN';
      await expectLater(
        repo.fetchProfile(session),
        throwsA(failure(FailureKind.forbidden)),
      );
    },
  );
  test('401, 403 and 429 become safe actionable failures', () async {
    forceStatus = 401;
    await expectLater(
      repo.signIn('a@example.invalid', 'wrong'),
      throwsA(failure(FailureKind.credentials)),
    );
    forceStatus = null;
    final session = await repo.signIn('a@example.invalid', 'password');
    forceStatus = 401;
    await expectLater(
      repo.fetchProfile(session),
      throwsA(failure(FailureKind.expired)),
    );
    forceStatus = 403;
    await expectLater(
      repo.fetchProfile(session),
      throwsA(failure(FailureKind.accessDenied)),
    );
    forceStatus = 429;
    await expectLater(
      repo.signIn('a@example.invalid', 'password'),
      throwsA(failure(FailureKind.rateLimited)),
    );
  });
  test(
    'rejects malformed responses and never follows redirects with credentials',
    () async {
      malformed = true;
      await expectLater(
        repo.signIn('a@example.invalid', 'password'),
        throwsA(failure(FailureKind.invalidResponse)),
      );
      malformed = false;
      forceStatus = 302;
      await expectLater(
        repo.signIn('a@example.invalid', 'password'),
        throwsA(failure(FailureKind.unavailable)),
      );
      expect(calls.where((c) => c.contains('must-not-follow')), isEmpty);
    },
  );
  test('network requests time out instead of hanging', () async {
    delay = true;
    final fastTimeout = FastApiStudentRepository(
      baseUri: repo.baseUri,
      timeout: const Duration(milliseconds: 30),
      allowInsecureDevelopment: true,
    );
    await expectLater(
      fastTimeout.signIn('a@example.invalid', 'password'),
      throwsA(failure(FailureKind.network)),
    );
  });
  test(
    'release rejects cleartext; credentials in URLs are never accepted',
    () async {
      final production = FastApiStudentRepository(baseUri: repo.baseUri);
      expect(production.isConfigured, false);
      await expectLater(
        production.signIn('a@example.invalid', 'password'),
        throwsA(failure(FailureKind.unavailable)),
      );
      expect(
        FastApiStudentRepository(
          baseUri: Uri.parse('https://user:password@example.invalid'),
        ).isConfigured,
        false,
      );
      expect(
        FastApiStudentRepository(
          baseUri: Uri.parse('https://example.invalid/api'),
        ).isConfigured,
        true,
      );
      expect(calls, isEmpty);
    },
  );
}
