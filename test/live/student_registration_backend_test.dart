// Opt-in widget UI test with the real FastAPI service. Not a native Android test.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dexa_assessment_mobile/student/student_app.dart';
import 'package:dexa_assessment_mobile/student/fastapi_student_repository.dart';

class RegistrationHttp extends HttpOverrides {}

void main() {
  testWidgets(
    'real registration then manual login uses the same backend account',
    (t) async {
      final data = jsonDecode(
        File('.local/register-qa.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      final old = HttpOverrides.current;
      HttpOverrides.global = RegistrationHttp();
      addTearDown(() => HttpOverrides.global = old);
      SharedPreferences.setMockInitialValues({});
      t.view.physicalSize = const Size(432, 960);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      Future<void> settle() async {
        for (var i = 0; i < 300; i++) {
          await t.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 100)),
          );
          await t.pump(const Duration(milliseconds: 100));
          if (!t.binding.hasScheduledFrame) return;
        }
        fail('Network UI did not settle');
      }

      Future<void> tapKey(String key) async {
        final f = find.byKey(Key(key));
        await t.ensureVisible(f);
        await settle();
        await t.tap(f);
        await settle();
      }

      final repo = FastApiStudentRepository(
        baseUri: Uri.parse('http://192.168.1.66:3001'),
        allowInsecureDevelopment: true,
      );
      await t.pumpWidget(StudentApp(repository: repo));
      await settle();
      await tapKey('student-open-register');
      for (final entry in {
        'registration-name': data['name'],
        'registration-email': data['email'],
        'registration-password': data['password'],
        'registration-confirm': data['password'],
      }.entries) {
        final f = find.byKey(Key(entry.key));
        await t.ensureVisible(f);
        await settle();
        await t.enterText(f, entry.value);
        await settle();
      }
      await tapKey('student-register-submit');
      expect(find.text('Akun berhasil dibuat'), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
      debugPrint('LIVE REGISTER: account created; no automatic login');
      await tapKey('registration-back-login');
      expect(
        t
            .widget<TextFormField>(find.byKey(const Key('student-account')))
            .controller!
            .text,
        data['email'],
      );
      await t.enterText(
        find.byKey(const Key('student-password')),
        data['password'],
      );
      await tapKey('student-sign-in');
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.text('Selamat datang,'), findsOneWidget);
      expect(t.takeException(), isNull);
      debugPrint('LIVE REGISTER: manual login reached student dashboard');
    },
    skip: !const bool.fromEnvironment('RUN_REGISTER_LIVE_QA'),
  );
}
