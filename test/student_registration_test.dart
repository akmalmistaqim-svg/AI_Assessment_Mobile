import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dexa_assessment_mobile/student/student_app.dart';
import 'package:dexa_assessment_mobile/student/student_registration.dart';
import 'package:dexa_assessment_mobile/student/student_registration_page.dart';
import 'package:dexa_assessment_mobile/student/student_repository.dart';
import 'package:dexa_assessment_mobile/student/fastapi_student_repository.dart';

import 'student_flow_test.dart' show TestRepository, viewport;

class RegisterRepo extends TestRepository
    implements StudentRegistrationRepository {
  int registrations = 0;
  StudentRegistration? received;
  StudentFailure? failure;
  Completer<String>? wait;
  @override
  Future<String> registerStudent(StudentRegistration data) async {
    registrations++;
    received = data;
    if (failure != null) throw failure!;
    return wait?.future ?? data.normalizedEmail;
  }
}

class RealHttp extends HttpOverrides {}

Future<void> open(WidgetTester t, RegisterRepo repo) async {
  await t.pumpWidget(StudentApp(repository: repo));
  await t.pumpAndSettle();
  final f = find.byKey(const Key('student-open-register'));
  await t.ensureVisible(f);
  await t.pumpAndSettle();
  await t.tap(f);
  await t.pumpAndSettle();
}

Future<void> field(WidgetTester t, String key, String value) async {
  final f = find.byKey(Key(key));
  await t.ensureVisible(f);
  await t.enterText(f, value);
  await t.pumpAndSettle();
}

Future<void> fill(WidgetTester t) async {
  await field(t, 'registration-name', ' Nama Mahasiswa ');
  await field(t, 'registration-email', ' Student@Example.com ');
  await field(t, 'registration-password', 'Secret123!');
  await field(t, 'registration-confirm', 'Secret123!');
}

Future<void> submit(WidgetTester t) async {
  final f = find.byKey(const Key('student-register-submit'));
  await t.ensureVisible(f);
  await t.pumpAndSettle();
  await t.tap(f);
  await t.pump();
}

void main() {
  WidgetController.hitTestWarningShouldBeFatal = true;
  testWidgets(
    'registration success returns to login with email but never signs in automatically',
    (t) async {
      final repo = RegisterRepo();
      await open(t, repo);
      await fill(t);
      await submit(t);
      await t.pumpAndSettle();
      expect(find.text('Akun berhasil dibuat'), findsOneWidget);
      expect(repo.registrations, 1);
      expect(repo.loginCalls, 0);
      await t.tap(find.byKey(const Key('registration-back-login')));
      await t.pumpAndSettle();
      expect(find.byType(StudentRegistrationPage), findsNothing);
      expect(
        t
            .widget<TextFormField>(find.byKey(const Key('student-account')))
            .controller!
            .text,
        'student@example.com',
      );
      expect(
        t
            .widget<TextFormField>(find.byKey(const Key('student-password')))
            .controller!
            .text,
        isEmpty,
      );
    },
  );
  testWidgets(
    'required fields and confirmation mismatch prevent registration',
    (t) async {
      final repo = RegisterRepo();
      await open(t, repo);
      await submit(t);
      await t.pumpAndSettle();
      expect(repo.registrations, 0);
      await fill(t);
      await field(t, 'registration-confirm', 'Different');
      await submit(t);
      await t.pumpAndSettle();
      expect(find.text('Konfirmasi kata sandi tidak cocok.'), findsOneWidget);
      expect(repo.registrations, 0);
    },
  );
  testWidgets(
    'duplicate error retains form and pending registration blocks repeated tap and back',
    (t) async {
      final repo = RegisterRepo()
        ..failure = const StudentFailure(FailureKind.registrationDuplicate);
      await open(t, repo);
      await fill(t);
      await submit(t);
      await t.pumpAndSettle();
      expect(find.textContaining('Email sudah terdaftar'), findsOneWidget);
      expect(find.byType(StudentRegistrationPage), findsOneWidget);
      repo.failure = null;
      repo.wait = Completer<String>();
      await submit(t);
      await t.pump();
      expect(repo.registrations, 2);
      expect(
        t
            .widget<FilledButton>(
              find.byKey(const Key('student-register-submit')),
            )
            .onPressed,
        isNull,
      );
      await t.binding.handlePopRoute();
      await t.pump();
      expect(find.byType(StudentRegistrationPage), findsOneWidget);
      repo.wait!.complete('student@example.com');
      await t.pumpAndSettle();
      expect(find.text('Akun berhasil dibuat'), findsOneWidget);
    },
  );
  testWidgets('registration fits small screen, large text and keyboard', (
    t,
  ) async {
    viewport(t, const Size(320, 640), scale: 1.5);
    await open(t, RegisterRepo());
    t.view.viewInsets = const FakeViewPadding(bottom: 250);
    await t.pumpAndSettle();
    await fill(t);
    await submit(t);
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
    expect(find.text('Akun berhasil dibuat'), findsOneWidget);
  });
  group('registration HTTP contract', () {
    late HttpServer server;
    late FastApiStudentRepository repo;
    late HttpOverrides? old;
    int status = 201;
    String detail = '';
    bool malformed = false;
    final bodies = <Map<String, dynamic>>[];
    final auth = <String?>[];
    setUp(() async {
      old = HttpOverrides.current;
      HttpOverrides.global = RealHttp();
      status = 201;
      detail = '';
      malformed = false;
      bodies.clear();
      auth.clear();
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((r) async {
        expect(r.method, 'POST');
        expect(r.uri.path, '/auth/register');
        auth.add(r.headers.value(HttpHeaders.authorizationHeader));
        final body = jsonDecode(
          await utf8.decoder.bind(r).join(),
        ) as Map<String, dynamic>;
        bodies.add(body);
        r.response.statusCode = status;
        r.response.write(
          jsonEncode(
            status == 201
                ? (malformed
                      ? []
                      : {
                          'access_token': 'registration-token-not-to-use',
                          'user': {
                            'id': 'new',
                            'email': body['email'],
                            'role': 'MAHASISWA',
                          },
                        })
                : {'detail': detail},
          ),
        );
        await r.response.close();
      });
      repo = FastApiStudentRepository(
        baseUri: Uri.parse('http://127.0.0.1:${server.port}'),
        allowInsecureDevelopment: true,
      );
    });
    tearDown(() async {
      await server.close(force: true);
      HttpOverrides.global = old;
    });
    const data = StudentRegistration(
      name: ' Student ',
      email: ' Student@Example.com ',
      password: ' secret ',
    );
    test('normalizes name/email, preserves password, pins student role and sends no bearer', () async {
      expect(await repo.registerStudent(data), 'student@example.com');
      expect(bodies.single, {
        'name': 'Student',
        'email': 'student@example.com',
        'password': ' secret ',
        'role': 'MAHASISWA',
      });
      expect(auth.single, isNull);
    });
    test('invalid data is rejected before HTTP', () async {
      await expectLater(
        repo.registerStudent(
          const StudentRegistration(name: ' ', email: 'bad', password: 'x'),
        ),
        throwsA(
          isA<StudentFailure>().having(
            (e) => e.kind,
            'kind',
            FailureKind.registrationInvalid,
          ),
        ),
      );
      expect(bodies, isEmpty);
    });
    test('duplicate and invalid data become safe failures', () async {
      status = 400;
      detail = 'Email sudah terdaftar. Silakan gunakan email lain atau login.';
      await expectLater(
        repo.registerStudent(data),
        throwsA(
          isA<StudentFailure>().having(
            (e) => e.kind,
            'kind',
            FailureKind.registrationDuplicate,
          ),
        ),
      );
      status = 422;
      detail = 'sensitive internals';
      await expectLater(
        repo.registerStudent(data),
        throwsA(
          isA<StudentFailure>().having(
            (e) => e.kind,
            'kind',
            FailureKind.registrationInvalid,
          ),
        ),
      );
    });
    test('malformed acknowledgment and server failure cannot imply account creation', () async {
      malformed = true;
      await expectLater(
        repo.registerStudent(data),
        throwsA(
          isA<StudentFailure>().having(
            (e) => e.kind,
            'kind',
            FailureKind.registrationUncertain,
          ),
        ),
      );
      status = 500;
      await expectLater(
        repo.registerStudent(data),
        throwsA(
          isA<StudentFailure>().having(
            (e) => e.kind,
            'kind',
            FailureKind.registrationUncertain,
          ),
        ),
      );
    });
  });
}
