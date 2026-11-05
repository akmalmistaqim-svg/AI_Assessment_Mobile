import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dexa_assessment_mobile/student/student_app.dart';
import 'package:dexa_assessment_mobile/student/fastapi_student_repository.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const email = String.fromEnvironment('DEXA_QA_EMAIL');
  const password = String.fromEnvironment('DEXA_QA_PASSWORD');
  const api = String.fromEnvironment(
    'DEXA_API_BASE_URL',
    defaultValue: 'http://10.0.2.2:3001',
  );
  testWidgets(
    'student uses real FastAPI on Android: login, information, profile and logout',
    (tester) async {
      expect(
        email,
        isNotEmpty,
        reason:
            'Supply a dedicated test account, never production credentials.',
      );
      expect(password, isNotEmpty);
      final repository = FastApiStudentRepository(
        baseUri: Uri.parse(api),
        allowInsecureDevelopment: true,
      );
      await tester.pumpWidget(StudentApp(repository: repository));
      await tester.pumpAndSettle();
      Future<void> capture(String name) async {
        await tester.pump(const Duration(milliseconds: 700));
        await binding.takeScreenshot(name);
      }

      await binding.convertFlutterSurfaceToImage();
      await tester.pumpAndSettle();
      await capture('student-login-android');
      await tester.enterText(find.byKey(const Key('student-account')), email);
      await tester.enterText(
        find.byKey(const Key('student-password')),
        password,
      );
      await tester.ensureVisible(find.byKey(const Key('student-sign-in')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('student-sign-in')));
      await tester.pumpAndSettle(
        const Duration(milliseconds: 200),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 60),
      );
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.text('Selamat datang,'), findsOneWidget);
      expect(find.text('Coba lagi'), findsNothing);
      await capture('student-home-android');
      Future<void> tab(String text) async {
        await tester.tap(find.widgetWithText(NavigationDestination, text));
        await tester.pumpAndSettle();
      }

      await tab('Informasi');
      expect(find.widgetWithText(TextField, 'Cari informasi'), findsOneWidget);
      await capture('student-information-android');
      // Read the first actual task if this test account has published assignments.
      final cards = find.descendant(
        of: find.byKey(const PageStorageKey('student-information')),
        matching: find.byIcon(Icons.arrow_forward),
      );
      if (cards.evaluate().isNotEmpty) {
        await tester.ensureVisible(cards.first);
        await tester.pumpAndSettle();
        await tester.tap(cards.first);
        await tester.pumpAndSettle();
        expect(find.byType(BackButton), findsOneWidget);
        expect(find.text('Detail tugas'), findsOneWidget);
        await capture('student-information-detail-android');
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();
      }
      await tab('Notifikasi');
      await capture('student-notifications-android');
      await tab('Profil');
      expect(find.text(email.toLowerCase()), findsOneWidget);
      expect(find.text('Mahasiswa'), findsOneWidget);
      await capture('student-profile-android');
      await tester.ensureVisible(find.byKey(const Key('student-sign-out')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('student-sign-out')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Keluar'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('student-sign-in')), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
