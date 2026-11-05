import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:dexa_assessment_mobile/student/fastapi_student_repository.dart';
import 'package:dexa_assessment_mobile/student/student_assignment.dart';
import 'package:dexa_assessment_mobile/student/student_repository.dart';

class RealHttp extends HttpOverrides {}

Map<String, dynamic> assignmentJson() => {
  'id': 'task',
  'classId': 'class',
  'title': 'Tugas pengujian',
  'instructions': 'Jelaskan jawaban.',
  'submissionType': 'ANY',
  'status': 'PUBLISHED',
  'dueDate': '2099-01-01T12:00:00',
  'maxScore': 100,
  'allowLateSubmission': false,
  'class': {
    'name': 'Kelas uji',
    'enrollments': [
      {'userId': 'student', 'role': 'STUDENT'},
    ],
  },
  'rubric': {
    'criteria': [
      {'label': 'Analisis', 'maxScore': 100, 'description': 'Jelas'},
    ],
  },
  'submissions': [],
};
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late HttpServer server;
  late FastApiStudentRepository repo;
  late StudentSession session;
  late Map<String, dynamic> payload;
  late List<int> submitted;
  String? contentType, authorization;
  int responseCode = 201, postCount = 0;
  Object? responseBody;
  HttpOverrides? previous;
  setUp(() async {
    previous = HttpOverrides.current;
    HttpOverrides.global = RealHttp();
    payload = assignmentJson();
    submitted = [];
    responseCode = 201;
    postCount = 0;
    responseBody = null;
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      Object body;
      if (request.uri.path == '/auth/login') {
        await request.drain<void>();
        body = {
          'access_token': 'test-token',
          'token_type': 'Bearer',
          'user': {'id': 'student', 'role': 'MAHASISWA'},
        };
      } else if (request.method == 'GET') {
        body = payload;
      } else {
        postCount++;
        submitted = await request.fold<List<int>>([], (a, b) => a..addAll(b));
        contentType = request.headers.value('content-type');
        authorization = request.headers.value('authorization');
        request.response.statusCode = responseCode;
        body =
            responseBody ??
            {
              'success': true,
              'submissionId': 'submission',
              'versionId': 'version-1',
              'versionNumber': 1,
              'userId': 'student',
            };
      }
      request.response.headers.contentType = ContentType.json;
      request.response.write(jsonEncode(body));
      await request.response.close();
    });
    repo = FastApiStudentRepository(
      baseUri: Uri.parse('http://127.0.0.1:${server.port}'),
      allowInsecureDevelopment: true,
    );
    session = await repo.signIn('test@example.invalid', 'test-only');
  });
  tearDown(() async {
    await server.close(force: true);
    HttpOverrides.global = previous;
  });
  test(
    'authenticated text submission uses the existing endpoint and receipt',
    () async {
      final task = await repo.fetchAssignment(
        session,
        const AssignmentRef('class', 'task'),
      );
      expect(task.canSubmit, true);
      expect(task.rubric.single, contains('Analisis'));
      final receipt = await repo.submitAnswer(
        session,
        task,
        text: '  Jawaban mahasiswa.  ',
      );
      expect(jsonDecode(utf8.decode(submitted)), {
        'content': 'Jawaban mahasiswa.',
      });
      expect(authorization, 'Bearer test-token');
      expect(receipt.number, 1);
      expect(postCount, 1);
    },
  );
  test('multipart preserves PDF bytes and escapes filename headers', () async {
    final task = await repo.fetchAssignment(
      session,
      const AssignmentRef('class', 'task'),
    );
    final bytes = Uint8List.fromList([
      37,
      80,
      68,
      70,
      45,
      49,
      46,
      52,
      10,
      0,
      255,
      13,
      10,
    ]);
    await repo.submitAnswer(
      session,
      task,
      file: AnswerFile(name: 'jawaban"\r\n.pdf', bytes: bytes),
    );
    expect(contentType, startsWith('multipart/form-data;'));
    final raw = latin1.decode(submitted);
    expect(raw, contains('name="file"; filename="jawaban___.pdf"'));
    expect(raw, contains('Content-Type: application/pdf'));
    expect(raw, contains(latin1.decode(bytes)));
    expect(authorization, 'Bearer test-token');
  });
  test(
    'empty, oversized and disallowed formats are rejected before POST',
    () async {
      payload['submissionType'] = 'PDF';
      final task = await repo.fetchAssignment(
        session,
        const AssignmentRef('class', 'task'),
      );
      await expectLater(
        repo.submitAnswer(session, task, text: 'answer'),
        throwsA(
          isA<StudentFailure>().having(
            (e) => e.kind,
            'kind',
            FailureKind.answerFormat,
          ),
        ),
      );
      await expectLater(
        repo.submitAnswer(
          session,
          task,
          file: AnswerFile(name: 'a.pdf', bytes: Uint8List(0)),
        ),
        throwsA(
          isA<StudentFailure>().having(
            (e) => e.kind,
            'kind',
            FailureKind.emptyAnswer,
          ),
        ),
      );
      await expectLater(
        repo.submitAnswer(
          session,
          task,
          file: AnswerFile(name: 'a.pdf', bytes: Uint8List(maxAnswerBytes + 1)),
        ),
        throwsA(
          isA<StudentFailure>().having(
            (e) => e.kind,
            'kind',
            FailureKind.answerTooLarge,
          ),
        ),
      );
      await expectLater(
        repo.submitAnswer(
          session,
          task,
          file: AnswerFile(name: 'a.exe', bytes: Uint8List(4)),
        ),
        throwsA(
          isA<StudentFailure>().having(
            (e) => e.kind,
            'kind',
            FailureKind.answerFormat,
          ),
        ),
      );
      expect(postCount, 0);
    },
  );
  test(
    'deadline, closed state and assistant role prevent submission',
    () async {
      payload['dueDate'] = '2020-01-01T00:00:00';
      var task = await repo.fetchAssignment(
        session,
        const AssignmentRef('class', 'task'),
      );
      expect(task.blockedReason, contains('Tenggat'));
      await expectLater(
        repo.submitAnswer(session, task, text: 'answer'),
        throwsA(isA<StudentFailure>()),
      );
      payload['allowLateSubmission'] = true;
      task = await repo.fetchAssignment(
        session,
        const AssignmentRef('class', 'task'),
      );
      expect(task.blockedReason, isNull);
      payload['status'] = 'CLOSED';
      task = await repo.fetchAssignment(
        session,
        const AssignmentRef('class', 'task'),
      );
      expect(task.blockedReason, contains('ditutup'));
      payload['status'] = 'PUBLISHED';
      payload['class']['enrollments'][0]['role'] = 'ASSISTANT';
      task = await repo.fetchAssignment(
        session,
        const AssignmentRef('class', 'task'),
      );
      expect(task.canSubmit, false);
      expect(postCount, 0);
    },
  );
  test(
    'only the logged-in student and active released grade are mapped',
    () async {
      payload['submissions'] = [
        {'userId': 'other'},
        {
          'id': 'mine',
          'userId': 'student',
          'activeVersionId': 'v2',
          'releasedGradeId': 'g2',
          'versions': [
            {
              'id': 'v1',
              'versionNumber': 1,
              'type': 'TEXT',
              'content': 'old',
              'submittedAt': '2026-01-01T00:00:00',
            },
            {
              'id': 'v2',
              'versionNumber': 2,
              'type': 'DOCX',
              'fileName': 'answer.docx',
              'content': 'new',
              'submittedAt': '2026-01-02T00:00:00',
            },
          ],
          'grades': [
            {'id': 'g1', 'status': 'RELEASED', 'finalScore': 10},
            {
              'id': 'g2',
              'status': 'RELEASED',
              'finalScore': 90,
              'finalFeedback': 'Baik',
            },
            {'id': 'draft', 'status': 'DRAFT', 'finalScore': 99},
          ],
        },
      ];
      final task = await repo.fetchAssignment(
        session,
        const AssignmentRef('class', 'task'),
      );
      expect(task.submission!.active!.number, 2);
      expect(task.submission!.versions.first.number, 2);
      expect(task.submission!.result!.score, 90);
      expect(task.blockedReason, contains('Nilai sudah dirilis'));
    },
  );
  test(
    'server rejection, timeout-like failure and forged receipt remain failures',
    () async {
      final task = await repo.fetchAssignment(
        session,
        const AssignmentRef('class', 'task'),
      );
      responseCode = 400;
      responseBody = {
        'detail': 'Tenggat waktu pengumpulan tugas ini telah berakhir',
      };
      await expectLater(
        repo.submitAnswer(session, task, text: 'answer'),
        throwsA(
          isA<StudentFailure>().having(
            (e) => e.kind,
            'kind',
            FailureKind.submissionClosed,
          ),
        ),
      );
      responseCode = 500;
      responseBody = {'detail': 'private internal error'};
      await expectLater(
        repo.submitAnswer(session, task, text: 'answer'),
        throwsA(
          isA<StudentFailure>().having(
            (e) => e.kind,
            'kind',
            FailureKind.submissionUncertain,
          ),
        ),
      );
      responseCode = 201;
      responseBody = [];
      await expectLater(
        repo.submitAnswer(session, task, text: 'answer'),
        throwsA(
          isA<StudentFailure>().having(
            (e) => e.kind,
            'kind',
            FailureKind.submissionUncertain,
          ),
        ),
      );
      responseCode = 201;
      responseBody = {
        'success': true,
        'userId': 'other',
        'versionNumber': 1,
        'submissionId': 's',
        'versionId': 'v',
      };
      await expectLater(
        repo.submitAnswer(session, task, text: 'answer'),
        throwsA(
          isA<StudentFailure>().having(
            (e) => e.kind,
            'kind',
            FailureKind.submissionUncertain,
          ),
        ),
      );
    },
  );
}
