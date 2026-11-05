// Opt-in test: creates one real enrollment for the authorized teskelas QA account.
import 'dart:convert';
import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dexa_assessment_mobile/student/student_app.dart';
import 'package:dexa_assessment_mobile/student/fastapi_student_repository.dart';

class NativeHttp extends HttpOverrides {}

void main() {
  const live = bool.fromEnvironment('RUN_LIVE_CLASS_QA');
  const resume = bool.fromEnvironment('RESUME_LIVE_CLASS_QA');
  testWidgets(
    'real backend: login, join class, task capability, duplicate join, logout',
    (tester) async {
      final data = jsonDecode(
        File('.local/teskelas.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      final email = data['DEXA_QA_EMAIL'] as String;
      final password = data['DEXA_QA_PASSWORD'] as String;
      final id = data['DEXA_QA_CLASS_ID'] as String;
      final code = data['DEXA_QA_CLASS_CODE'] as String;
      expect(email, 'teskelas@example.com');
      final oldOverrides = HttpOverrides.current;
      HttpOverrides.global = NativeHttp();
      SharedPreferences.setMockInitialValues({});
      addTearDown(() => HttpOverrides.global = oldOverrides);
      tester.view.physicalSize = const Size(900, 1600);
      tester.view.devicePixelRatio = 2.5;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repo = FastApiStudentRepository(
        baseUri: Uri.parse('http://127.0.0.1:3001'),
        allowInsecureDevelopment: true,
      );
      await tester.pumpWidget(StudentApp(repository: repo));
      Future<void> settle() async {
        for (var i = 0; i < 200; i++) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 100)),
          );
          await tester.pump(const Duration(milliseconds: 100));
          if (!tester.binding.hasScheduledFrame) return;
        }
        fail('UI did not settle after real network processing');
      }

      Future<void> tab(String label) async {
        await tester.tap(find.widgetWithText(NavigationDestination, label));
        await settle();
      }

      await tester.enterText(find.byKey(const Key('student-account')), email);
      await tester.enterText(
        find.byKey(const Key('student-password')),
        password,
      );
      await tester.ensureVisible(find.byKey(const Key('student-sign-in')));
      await tester.tap(find.byKey(const Key('student-sign-in')));
      await settle();
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.text('Selamat datang,'), findsOneWidget);
      expect(find.text('Coba lagi'), findsNothing);
      debugPrint('LIVE CHECKPOINT: authenticated student dashboard');
      await tab('Kelas Saya');
      final course = find.byKey(ValueKey('class-$id'));
      if (!resume) {
        expect(
          course,
          findsNothing,
          reason: 'This test requires teskelas to be initially unenrolled',
        );
        await tester.enterText(
          find.byKey(const Key('student-class-code')),
          code.toLowerCase(),
        );
        await tester.ensureVisible(find.byKey(const Key('student-join-class')));
        await tester.tap(find.byKey(const Key('student-join-class')));
        await settle();
      } else {
        debugPrint(
          "LIVE CHECKPOINT: checking previously saved membership; no new join POST",
        );
      }
      // Scroll to create the lazy course card if it falls below the join form.
      await tester.drag(
        find.byKey(const PageStorageKey('student-classes')),
        const Offset(0, -280),
      );
      await settle();
      expect(course, findsOneWidget);
      expect(find.byKey(const Key('class-join-error')), findsNothing);
      await tester.ensureVisible(course);
      await tester.tap(course);
      await settle();
      expect(find.text('Tugas kelas'), findsOneWidget);
      final task = find.byType(ListTile);
      expect(task, findsWidgets);
      await tester.ensureVisible(task.first);
      await tester.tap(task.first);
      await settle();
      expect(find.text('Detail tugas'), findsOneWidget);
      expect(find.byKey(const Key('reload-assignment')), findsOneWidget);
      debugPrint(
        'LIVE CHECKPOINT: membership saved, actual task opened, mobile assignment detail and reload action confirmed',
      );
      await tester.tap(find.byType(BackButton));
      await settle();
      await tester.tap(find.byType(BackButton));
      await settle();
      await tester.drag(
        find.byKey(const PageStorageKey('student-classes')),
        const Offset(0, 400),
      );
      await settle();
      await tester.ensureVisible(find.byKey(const Key('student-class-code')));
      await tester.enterText(find.byKey(const Key('student-class-code')), code);
      await tester.ensureVisible(find.byKey(const Key('student-join-class')));
      await tester.tap(find.byKey(const Key('student-join-class')));
      await settle();
      expect(find.byKey(const Key('class-join-error')), findsOneWidget);
      debugPrint('LIVE CHECKPOINT: duplicate enrollment rejected');
      await tab('Profil');
      await tester.scrollUntilVisible(
        find.text(email),
        180,
        scrollable: find
            .descendant(
              of: find.byKey(const PageStorageKey('student-profile')),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await settle();
      expect(find.text(email), findsOneWidget);
      await tester.ensureVisible(find.byKey(const Key('student-sign-out')));
      await tester.tap(find.byKey(const Key('student-sign-out')));
      await settle();
      await tester.tap(find.text('Keluar'));
      await settle();
      expect(find.byKey(const Key('student-sign-in')), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
      expect(tester.takeException(), isNull);
      debugPrint('LIVE CHECKPOINT: logout returned to login');
    },
    skip: !live,
  );
}
