import 'dart:convert';
import 'dart:io';

import 'package:dexa_assessment_mobile/student/fastapi_student_repository.dart';
import 'package:dexa_assessment_mobile/student/student_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LiveHttp extends HttpOverrides {}

void main() {
  testWidgets('live login, tabs, refresh and logout', (t) async {
    final previous = HttpOverrides.current;
    HttpOverrides.global = LiveHttp();
    addTearDown(() => HttpOverrides.global = previous);
    SharedPreferences.setMockInitialValues({});
    final account = jsonDecode(
      File('.local/register-qa.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final repo = FastApiStudentRepository(
      baseUri: Uri.parse('http://127.0.0.1:3001'),
      allowInsecureDevelopment: true,
    );
    t.view.physicalSize = const Size(390, 844);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);

    Future<void> waitFor(bool Function() ready) async {
      final until = DateTime.now().add(const Duration(seconds: 45));
      while (!ready() && DateTime.now().isBefore(until)) {
        await t.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)),
        );
        await t.pump(const Duration(milliseconds: 50));
      }
      expect(ready(), isTrue, reason: 'Live UI did not reach expected state');
      await t.pump(const Duration(milliseconds: 400));
    }

    await t.pumpWidget(StudentApp(repository: repo));
    await t.pumpAndSettle();
    await t.enterText(
      find.byKey(const Key('student-account')),
      account['email'],
    );
    await t.enterText(
      find.byKey(const Key('student-password')),
      account['password'],
    );
    final button = find.byKey(const Key('student-sign-in'));
    await t.ensureVisible(button);
    final timer = Stopwatch()..start();
    await t.tap(button);
    await waitFor(() => find.text('Selamat datang,').evaluate().isNotEmpty);
    final profileMs = timer.elapsedMilliseconds;
    await waitFor(
      () => find.byType(LinearProgressIndicator).evaluate().isEmpty,
    );
    final dataMs = timer.elapsedMilliseconds;

    for (final label in [
      'Kelas Saya',
      'Informasi',
      'Notifikasi',
      'Profil',
      'Beranda',
      'Profil',
    ]) {
      await t.tap(find.widgetWithText(NavigationDestination, label));
      await t.pump(const Duration(milliseconds: 400));
    }
    expect(find.text(account['email']), findsOneWidget);
    expect(find.text('Mahasiswa'), findsOneWidget);
    expect(
      find.textContaining('tidak dapat', findRichText: true),
      findsNothing,
    );
    await t.tap(find.byTooltip('Muat ulang data'));
    await t.pump();
    await waitFor(
      () => find.byType(LinearProgressIndicator).evaluate().isEmpty,
    );
    expect(find.text(account['email']), findsOneWidget);
    expect(find.text('Coba lagi'), findsNothing);
    await t.scrollUntilVisible(
      find.byKey(const Key('student-sign-out')),
      180,
      scrollable: find
          .descendant(
            of: find.byKey(const PageStorageKey('student-profile')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await t.tap(find.byKey(const Key('student-sign-out')));
    await t.pumpAndSettle();
    await t.tap(find.text('Keluar'));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('student-sign-in')), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    expect(t.takeException(), isNull);
    await t.runAsync(
      () => File('docs/evidence/auth-live-performance.json').writeAsString(
        const JsonEncoder.withIndent('  ').convert({
          'environment':
              'Flutter widget UI with real localhost FastAPI and PostgreSQL',
          'dashboardProfileMs': profileMs,
          'initialDataMs': dataMs,
          'tabSwitches': 6,
          'login': true,
          'profile': true,
          'refresh': true,
          'logout': true,
          'physicalPhoneTested': false,
          'note': 'Timings are host test measurements, not phone benchmarks.',
        }),
      ),
    );
    debugPrint(
      'LIVE PASS: profile ${profileMs}ms; initial data ${dataMs}ms; tabs, refresh and logout verified',
    );
  }, skip: !const bool.fromEnvironment('RUN_AUTH_PERFORMANCE_QA'));
}
