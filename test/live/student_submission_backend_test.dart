// Opt-in: real mobile widgets and HTTP; file picker injected, not an Android picker test.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dexa_assessment_mobile/student/student_app.dart';
import 'package:dexa_assessment_mobile/student/student_assignment.dart';
import 'package:dexa_assessment_mobile/student/fastapi_student_repository.dart';

class LiveHttp extends HttpOverrides {}

void main() {
  testWidgets(
    'live login, class, text, DOCX and PDF submission with receipts',
    (tester) async {
      final account = jsonDecode(
        File('.local/teskelas.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      final qa = jsonDecode(
        File('.local/submission-qa.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      final old = HttpOverrides.current;
      HttpOverrides.global = LiveHttp();
      addTearDown(() => HttpOverrides.global = old);
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.5;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var extension = 'docx';
      final repo = FastApiStudentRepository(
        baseUri: Uri.parse('http://127.0.0.1:3001'),
        allowInsecureDevelopment: true,
      );
      await tester.pumpWidget(
        StudentApp(
          repository: repo,
          filePicker: (allowed) async {
            expect(allowed, contains(extension));
            return AnswerFile(
              name: 'teskelas-jawaban.$extension',
              bytes: File('.local/upload-fixtures/teskelas-jawaban.$extension')
                  .readAsBytesSync(),
            );
          },
        ),
      );
      Future<void> settle() async {
        for (var i = 0; i < 600; i++) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 100)),
          );
          await tester.pump(const Duration(milliseconds: 100));
          if (!tester.binding.hasScheduledFrame) return;
        }
        fail('Network UI did not settle');
      }

      Future<void> reveal(Finder f, {double delta = 180}) async {
        await tester.scrollUntilVisible(
          f,
          delta,
          scrollable: find
              .descendant(
                of: find.byKey(
                  const PageStorageKey('student-assignment-detail'),
                ),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        await tester.ensureVisible(f);
        await settle();
      }

      Future<void> send(int version) async {
        final button = find.byKey(const Key('student-send-answer'));
        await reveal(button);
        await tester.tap(button);
        await settle();
        await tester.tap(find.byKey(const Key('confirm-answer-send')));
        await settle();
        final receipt = find.text(
          'Jawaban berhasil dikirim. Versi $version sudah diterima server.',
        );
        await reveal(receipt, delta: -180);
        expect(receipt, findsOneWidget);
        expect(tester.takeException(), isNull);
        debugPrint('LIVE SUBMISSION: server acknowledged version $version');
      }

      await tester.enterText(
        find.byKey(const Key('student-account')),
        account['DEXA_QA_EMAIL'],
      );
      await tester.enterText(
        find.byKey(const Key('student-password')),
        account['DEXA_QA_PASSWORD'],
      );
      await tester.ensureVisible(find.byKey(const Key('student-sign-in')));
      await tester.tap(find.byKey(const Key('student-sign-in')));
      await settle();
      expect(find.byType(NavigationBar), findsOneWidget);
      await tester.tap(
        find.widgetWithText(NavigationDestination, 'Kelas Saya'),
      );
      await settle();
      final course = find.byKey(ValueKey('class-${qa['classId']}'));
      await tester.drag(
        find.byKey(const PageStorageKey('student-classes')),
        const Offset(0, -280),
      );
      await settle();
      await tester.ensureVisible(course);
      await tester.tap(course);
      await settle();
      final task = find.byKey(
        ValueKey('class-task-task:${qa['assignmentId']}'),
      );
      await tester.scrollUntilVisible(
        task,
        180,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(task);
      await settle();
      expect(find.text('Detail tugas'), findsOneWidget);
      final text = find.byKey(const Key('student-answer-text'));
      await reveal(text);
      await tester.enterText(text, qa['text']);
      await send((qa['baseVersion'] as int) + 1);
      final mode = find.byKey(const Key('answer-mode-file'));
      await reveal(mode);
      await tester.tap(mode);
      await settle();
      final pick = find.byKey(const Key('student-pick-answer'));
      await reveal(pick);
      await tester.tap(pick);
      await settle();
      expect(find.text('teskelas-jawaban.docx'), findsOneWidget);
      await send((qa['baseVersion'] as int) + 2);
      extension = 'pdf';
      await reveal(pick);
      await tester.tap(pick);
      await settle();
      expect(find.text('teskelas-jawaban.pdf'), findsOneWidget);
      await send((qa['baseVersion'] as int) + 3);
      await tester.tap(find.byKey(const Key('reload-assignment')));
      await settle();
      final active = find.text('Versi ${(qa['baseVersion'] as int) + 3} · PDF');
      await reveal(active);
      expect(active, findsOneWidget);
      expect(tester.takeException(), isNull);
    },
    skip: !const bool.fromEnvironment('RUN_LIVE_SUBMISSION_QA'),
  );
}
