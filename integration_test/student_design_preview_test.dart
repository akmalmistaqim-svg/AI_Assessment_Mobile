import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dexa_assessment_mobile/student/student_app.dart';

import '../test/student_flow_test.dart' show TestRepository, login, tab;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('capture refreshed student design with sample data', (
    tester,
  ) async {
    await tester.pumpWidget(StudentApp(repository: TestRepository()));
    await tester.pumpAndSettle();
    await binding.convertFlutterSurfaceToImage();
    await tester.pumpAndSettle();
    Future<void> capture(String name) async {
      await tester.pump(const Duration(milliseconds: 800));
      expect(tester.takeException(), isNull);
      await binding.takeScreenshot('student-new-$name');
    }

    await capture('login');
    await login(tester);
    await capture('home');
    await tab(tester, 'Informasi');
    await capture('information');
    await tester.ensureVisible(find.text('Jadwal evaluasi semester'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Jadwal evaluasi semester'));
    await tester.pumpAndSettle();
    await capture('information-detail');
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tab(tester, 'Notifikasi');
    await capture('notifications');
    await tester.tap(find.text('Informasi baru untukmu'));
    await tester.pumpAndSettle();
    await capture('notification-detail');
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tab(tester, 'Profil');
    await capture('profile');
    await tester.ensureVisible(find.byKey(const Key('student-sign-out')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('student-sign-out')));
    await tester.pumpAndSettle();
    await capture('logout');
  });
}
