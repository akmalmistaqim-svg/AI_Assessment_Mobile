import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dexa_assessment_mobile/models/announcement.dart';
import 'package:dexa_assessment_mobile/student/fastapi_student_repository.dart';
import 'package:dexa_assessment_mobile/student/student_app.dart';
import 'package:dexa_assessment_mobile/student/student_controller.dart';
import 'package:dexa_assessment_mobile/student/student_registration.dart';
import 'package:dexa_assessment_mobile/student/student_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'student_flow_test.dart' show TestRepository;

class SlowFeedRepository extends TestRepository {
  final feed = Completer<List<Announcement>>();
  int feeds = 0;
  int profiles = 0;
  @override
  Future<List<Announcement>> fetchAnnouncements(StudentSession session) {
    feeds++;
    return feed.future;
  }

  @override
  Future<StudentProfile> fetchProfile(StudentSession session) {
    profiles++;
    return super.fetchProfile(session);
  }
}

class RealHttp extends HttpOverrides {}

void main() {
  test('profile and classes appear while feed is pending; feed failure preserves profile', () async {
    final repo = SlowFeedRepository();
    final state = StudentController(repo);
    addTearDown(state.dispose);
    final pending = state.signIn('student@example.com', 'password');
    await Future<void>.delayed(Duration.zero);
    expect(state.profile?.id, 'student-a');
    expect(state.loading, isTrue);
    repo.feed.completeError(const StudentFailure(FailureKind.network));
    await pending;
    expect(state.profile?.id, 'student-a');
    expect(state.signedIn, isTrue);
    expect(state.loading, isFalse);
    expect(state.dataError, isNotNull);
  });

  test('slow old feed cannot enter the next account', () async {
    final repo = SlowFeedRepository();
    final state = StudentController(repo);
    addTearDown(state.dispose);
    final pending = state.signIn('student@example.com', 'password');
    await Future<void>.delayed(Duration.zero);
    state.signOut();
    repo.feed.complete(const [
      Announcement(
        id: 'private',
        title: 'Old task',
        date: '',
        category: '',
        summary: '',
        content: '',
      ),
    ]);
    await pending;
    expect(state.announcements, isEmpty);
    expect(state.profile, isNull);
    expect(state.signedIn, isFalse);
  });

  testWidgets('tabs respond during feed loading and do not fetch again', (
    t,
  ) async {
    final repo = SlowFeedRepository();
    await t.pumpWidget(StudentApp(repository: repo));
    await t.enterText(
      find.byKey(const Key('student-account')),
      'student@example.com',
    );
    await t.enterText(find.byKey(const Key('student-password')), 'password');
    await t.ensureVisible(find.byKey(const Key('student-sign-in')));
    await t.tap(find.byKey(const Key('student-sign-in')));
    await t.pump();
    await t.pump(const Duration(seconds: 1));
    expect(find.text('Selamat datang,'), findsOneWidget);
    for (final label in [
      'Profil',
      'Kelas Saya',
      'Notifikasi',
      'Beranda',
      'Profil',
    ]) {
      await t.tap(find.widgetWithText(NavigationDestination, label));
      await t.pump(const Duration(milliseconds: 400));
    }
    expect(find.text('Profil saya'), findsOneWidget);
    expect(repo.feeds, 1);
    expect(repo.profiles, 1);
    expect(repo.loginCalls, 1);
    repo.feed.complete([]);
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
  });

  testWidgets('network login failure keeps password for an explicit retry', (
    t,
  ) async {
    final repo = TestRepository()
      ..loginFailure = const StudentFailure(FailureKind.network);
    await t.pumpWidget(StudentApp(repository: repo));
    await t.enterText(
      find.byKey(const Key('student-account')),
      'student@example.com',
    );
    await t.enterText(find.byKey(const Key('student-password')), 'password');
    await t.ensureVisible(find.byKey(const Key('student-sign-in')));
    await t.tap(find.byKey(const Key('student-sign-in')));
    await t.pumpAndSettle();
    expect(
      t
          .widget<TextFormField>(find.byKey(const Key('student-password')))
          .controller!
          .text,
      'password',
    );
    expect(repo.loginCalls, 1);
    repo.loginFailure = null;
    await t.tap(find.byKey(const Key('student-sign-in')));
    await t.pumpAndSettle();
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  group('real HTTP scheduling', () {
    late HttpServer server;
    late FastApiStudentRepository repo;
    late HttpOverrides? previous;
    setUp(() async {
      previous = HttpOverrides.current;
      HttpOverrides.global = RealHttp();
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      repo = FastApiStudentRepository(
        baseUri: Uri.parse('http://127.0.0.1:${server.port}'),
        allowInsecureDevelopment: true,
      );
    });
    tearDown(() async {
      await server.close(force: true);
      HttpOverrides.global = previous;
    });

    test(
      'one shared classes request and at most three concurrent task requests',
      () async {
        var classCalls = 0;
        var active = 0;
        var maximum = 0;
        final firstBatch = Completer<void>();
        final release = Completer<void>();
        final classesRequested = Completer<void>();
        final releaseClasses = Completer<void>();
        server.listen((r) async {
          Object data;
          if (r.uri.path == '/auth/login') {
            data = {
              'access_token': 'qa-token',
              'token_type': 'Bearer',
              'user': {'id': 'student', 'role': 'MAHASISWA'},
            };
          } else if (r.uri.path == '/classes') {
            classCalls++;
            if (!classesRequested.isCompleted) classesRequested.complete();
            await releaseClasses.future;
            data = List.generate(5, (i) => {'id': 'c$i', 'name': 'Class $i'});
          } else {
            active++;
            maximum = maximum < active ? active : maximum;
            if (active == 3 && !firstBatch.isCompleted) firstBatch.complete();
            await release.future;
            active--;
            data = <Object>[];
          }
          r.response.write(jsonEncode(data));
          await r.response.close();
        });
        final session = await repo.signIn('student@example.com', 'password');
        final courses = repo.fetchClasses(session);
        final feed = repo.fetchAnnouncements(session);
        await classesRequested.future.timeout(const Duration(seconds: 3));
        releaseClasses.complete();
        try {
          await firstBatch.future.timeout(const Duration(seconds: 3));
          expect(classCalls, 1);
          expect(maximum, 3);
        } finally {
          release.complete();
        }
        expect(await courses, hasLength(5));
        expect(await feed, isEmpty);
        await repo.fetchClasses(session);
        expect(
          classCalls,
          2,
          reason: 'Refresh must fetch fresh data after completion.',
        );
      },
    );

    test(
      'offline registration reports connection failure before sending',
      () async {
        await server.close(force: true);
        await expectLater(
          repo.registerStudent(
            const StudentRegistration(
              name: 'Student',
              email: 'student@example.com',
              password: 'password',
            ),
          ),
          throwsA(
            isA<StudentFailure>().having(
              (e) => e.kind,
              'kind',
              FailureKind.network,
            ),
          ),
        );
      },
    );

    test(
      'lost registration response remains uncertain and is never retried',
      () async {
        var requests = 0;
        final received = Completer<void>();
        server.listen((r) async {
          await utf8.decoder.bind(r).join();
          requests++;
          received.complete();
        });
        repo = FastApiStudentRepository(
          baseUri: Uri.parse('http://127.0.0.1:${server.port}'),
          allowInsecureDevelopment: true,
          timeout: const Duration(milliseconds: 400),
        );
        final pending = expectLater(
          repo.registerStudent(
            const StudentRegistration(
              name: 'Student',
              email: 'student@example.com',
              password: 'password',
            ),
          ),
          throwsA(
            isA<StudentFailure>().having(
              (e) => e.kind,
              'kind',
              FailureKind.registrationUncertain,
            ),
          ),
        );
        await received.future.timeout(const Duration(seconds: 3));
        await pending;
        expect(requests, 1);
      },
    );
  });
}
