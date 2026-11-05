import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dexa_assessment_mobile/student/student_app.dart';
import 'package:dexa_assessment_mobile/student/fastapi_student_repository.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const email = String.fromEnvironment('DEXA_QA_EMAIL');
  const password = String.fromEnvironment('DEXA_QA_PASSWORD');
  const classId = String.fromEnvironment('DEXA_QA_CLASS_ID');
  const classCode = String.fromEnvironment('DEXA_QA_CLASS_CODE');
  const className = String.fromEnvironment('DEXA_QA_CLASS_NAME');
  testWidgets(
    'teskelas joins a real class on Android and checks task capabilities',
    (tester) async {
      expect(email, 'teskelas@example.com');
      expect(password, isNotEmpty);
      expect(classId, isNotEmpty);
      final repository = FastApiStudentRepository(
        baseUri: Uri.parse('http://10.0.2.2:3001'),
        allowInsecureDevelopment: true,
      );
      await tester.pumpWidget(StudentApp(repository: repository));
      await tester.pumpAndSettle();
      Future<void> waitFor(Finder finder) async {
        final until = DateTime.now().add(const Duration(seconds: 90));
        while (finder.evaluate().isEmpty && DateTime.now().isBefore(until)) {
          await tester.pump(const Duration(milliseconds: 500));
        }
        expect(finder, findsWidgets);
        await tester.pumpAndSettle(
          const Duration(milliseconds: 200),
          EnginePhase.sendSemanticsUpdate,
          const Duration(seconds: 90),
        );
      }

      Future<void> capture(String name) async {
        await tester.pump(const Duration(milliseconds: 500));
        await binding.takeScreenshot(name);
      }

      Future<void> tab(String label) async {
        await tester.tap(find.widgetWithText(NavigationDestination, label));
        await tester.pumpAndSettle();
      }

      await binding.convertFlutterSurfaceToImage();
      await tester.pumpAndSettle();
      await capture('student-class-live-login');
      await tester.enterText(find.byKey(const Key('student-account')), email);
      await tester.enterText(
        find.byKey(const Key('student-password')),
        password,
      );
      await tester.ensureVisible(find.byKey(const Key('student-sign-in')));
      await tester.tap(find.byKey(const Key('student-sign-in')));
      await waitFor(find.byType(NavigationBar));
      expect(find.text('Coba lagi'), findsNothing);
      await capture('student-class-live-dashboard');
      await tab('Kelas Saya');
      final course = find.byKey(ValueKey('class-$classId'));
      expect(
        course,
        findsNothing,
        reason:
            'Positive enrollment requires an initially unenrolled test account',
      );
      await capture('student-class-live-before');
      await tester.enterText(
        find.byKey(const Key('student-class-code')),
        classCode.toLowerCase(),
      );
      await tester.ensureVisible(find.byKey(const Key('student-join-class')));
      await tester.tap(find.byKey(const Key('student-join-class')));
      await waitFor(course);
      expect(find.byKey(const Key('class-join-error')), findsNothing);
      await tester.ensureVisible(course);
      await tester.pumpAndSettle();
      await capture('student-class-live-joined');
      await tester.tap(course);
      await waitFor(find.text('Tugas kelas'));
      await tester.pumpAndSettle();
      expect(find.text(className), findsOneWidget);
      await capture('student-class-live-detail');
      // Open an actual published task, never invent a submission through a separate API.
      final task = find.byType(ListTile);
      await waitFor(task);
      await tester.ensureVisible(task.first);
      await tester.tap(task.first);
      await tester.pumpAndSettle();
      await waitFor(find.text('Detail tugas'));
      expect(find.byKey(const Key('reload-assignment')), findsOneWidget);
      await capture('student-class-live-task');
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      // A duplicate enrollment must produce feedback, not another membership.
      await tester.ensureVisible(find.byKey(const Key('student-class-code')));
      await tester.enterText(
        find.byKey(const Key('student-class-code')),
        classCode,
      );
      await tester.ensureVisible(find.byKey(const Key('student-join-class')));
      await tester.tap(find.byKey(const Key('student-join-class')));
      await waitFor(find.byKey(const Key('class-join-error')));
      await capture('student-class-live-duplicate');
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
      await tester.pumpAndSettle();
      expect(find.text(email), findsOneWidget);
      await tester.ensureVisible(find.byKey(const Key('student-sign-out')));
      await tester.tap(find.byKey(const Key('student-sign-out')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Keluar'));
      await waitFor(find.byKey(const Key('student-sign-in')));
      expect(find.byType(NavigationBar), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
