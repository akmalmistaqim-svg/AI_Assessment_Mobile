import 'dart:convert';
import 'dart:math';

import 'package:dexa_assessment_mobile/student/fastapi_student_repository.dart';
import 'package:dexa_assessment_mobile/student/student_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const email = String.fromEnvironment('DEXA_REGISTER_QA_EMAIL');
  const name = String.fromEnvironment('DEXA_REGISTER_QA_NAME');
  testWidgets(
    'student registers, signs in, views own profile and signs out on Android',
    (t) async {
      final random = Random.secure();
      final password = base64UrlEncode(
        List.generate(24, (_) => random.nextInt(256)),
      );
      final repo = FastApiStudentRepository(
        baseUri: Uri.parse('http://10.0.2.2:3001'),
        allowInsecureDevelopment: true,
      );
      await t.pumpWidget(StudentApp(repository: repo));
      await t.pumpAndSettle();
      t.testTextInput.register();
      addTearDown(t.testTextInput.unregister);
      Future<void> waitFor(Finder f) async {
        final until = DateTime.now().add(const Duration(seconds: 45));
        while (f.evaluate().isEmpty && DateTime.now().isBefore(until)) {
          await t.pump(const Duration(milliseconds: 200));
          final error = find.byKey(const Key('registration-error'));
          if (error.evaluate().isNotEmpty) {
            fail(t.widget<Text>(error).data ?? 'Registration error');
          }
        }
        expect(f, findsOneWidget);
      }

      Finder key(String id) => find.byKey(Key(id));
      Future<void> tap(Finder f) async {
        await t.ensureVisible(f);
        await t.pumpAndSettle();
        expect(f.hitTestable(), findsOneWidget);
        await t.tap(f);
        await t.pumpAndSettle();
      }

      Future<void> fill(String id, String value) async {
        final f = key(id);
        await t.ensureVisible(f);
        await t.enterText(f, value);
        await t.pump();
        expect(
          t.widget<TextFormField>(f).controller!.text == value,
          isTrue,
          reason: 'Field input was not delivered: $id',
        );
        FocusManager.instance.primaryFocus?.unfocus();
        await t.pumpAndSettle();
      }

      await tap(key('student-open-register'));
      await fill('registration-name', name);
      await fill('registration-email', email);
      await fill('registration-password', password);
      await fill('registration-confirm', password);
      for (final entry in {
        'registration-name': name,
        'registration-email': email,
        'registration-password': password,
        'registration-confirm': password,
      }.entries) {
        expect(
          t.widget<TextFormField>(key(entry.key)).controller!.text ==
              entry.value,
          isTrue,
          reason: 'Form field changed before submit: ${entry.key}',
        );
      }
      await tap(key('student-register-submit'));
      await waitFor(find.text('Akun berhasil dibuat'));
      debugPrint('QA verified: registered');
      await tap(key('registration-back-login'));
      expect(
        t.widget<TextFormField>(key('student-account')).controller!.text,
        email,
      );
      await fill('student-password', 'intentionally-wrong');
      await tap(key('student-sign-in'));
      await waitFor(find.text('Akun atau kata sandi tidak sesuai. Coba lagi.'));
      expect(find.byType(NavigationBar), findsNothing);
      expect(key('student-sign-in'), findsOneWidget);
      await fill('student-password', password);
      await tap(key('student-sign-in'));
      await waitFor(find.text('Selamat datang,'));
      expect(find.text(name), findsOneWidget);
      debugPrint('QA verified: dashboard');
      await tap(find.widgetWithText(NavigationDestination, 'Profil'));
      expect(find.text(email), findsOneWidget);
      expect(find.text(name), findsOneWidget);
      expect(find.text('Mahasiswa'), findsOneWidget);
      debugPrint('QA verified: own student profile');
      await tap(key('student-sign-out'));
      await tap(find.text('Keluar'));
      expect(key('student-sign-in'), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
      expect(t.takeException(), isNull);
      debugPrint('QA verified: logged out');
    },
    skip: name.isEmpty || !email.endsWith('@example.com'),
  );
}
