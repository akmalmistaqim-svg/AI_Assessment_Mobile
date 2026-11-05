import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dexa_assessment_mobile/models/announcement.dart';
import 'package:dexa_assessment_mobile/models/notification_item.dart';
import 'package:dexa_assessment_mobile/student/student_app.dart';
import 'package:dexa_assessment_mobile/student/student_controller.dart';
import 'package:dexa_assessment_mobile/student/student_repository.dart';

// Test data never enters the production app or authenticates a real account.
class TestRepository implements StudentRepository {
  @override
  bool get isConfigured => true;
  int loginCalls = 0, readCalls = 0, logoutCalls = 0;
  String accountId = 'student-a';
  String? capturedIdentifier, capturedPassword;
  bool student = true;
  StudentFailure? loginFailure, fetchFailure, readFailure;
  Completer<StudentSession>? loginWait;
  Completer<StudentProfile>? profileWait;
  Completer<void>? readWait;
  bool empty = false;
  bool longText = false;
  @override
  Future<StudentSession> signIn(String identifier, String password) async {
    loginCalls++;
    capturedIdentifier = identifier;
    capturedPassword = password;
    if (loginFailure case final error?) throw error;
    return loginWait?.future ??
        StudentSession(
          accountId: accountId,
          isStudent: student,
          handle: Object(),
        );
  }

  @override
  Future<StudentProfile> fetchProfile(StudentSession session) async {
    if (fetchFailure case final error?) throw error;
    return profileWait?.future ??
        StudentProfile(
          id: session.accountId,
          name: longText
              ? 'Mahasiswa Pengujian Dengan Nama Sangat Panjang Untuk Memeriksa Tata Letak'
              : 'Mahasiswa Pengujian',
          email: 'student@example.invalid',
          studentNumber: 'TEST-001',
          program: 'Sistem Informasi',
        );
  }

  @override
  Future<List<StudentClass>> fetchClasses(StudentSession session) async => [];
  @override
  Future<JoinedClass> joinClass(StudentSession session, String code) async =>
      throw const StudentFailure(FailureKind.unavailable);
  @override
  Future<List<Announcement>> fetchClassAssignments(
    StudentSession session,
    StudentClass course,
  ) => fetchAnnouncements(session);
  @override
  Future<List<Announcement>> fetchAnnouncements(StudentSession session) async =>
      empty
      ? []
      : [
          Announcement(
            id: 'announcement-1',
            title: 'Jadwal evaluasi semester',
            date: '28 Oktober 2026',
            category: longText
                ? 'Informasi Akademik dan Kemahasiswaan'
                : 'Akademik',
            summary: 'Periksa jadwal evaluasi dan persiapan perkuliahan.',
            content: 'Isi informasi dari repository pengujian.',
          ),
          const Announcement(
            id: 'announcement-2',
            title: 'Pendaftaran magang',
            date: '27 Oktober 2026',
            category: 'Karier',
            summary: 'Periode magang mahasiswa.',
            content: 'Detail magang pengujian.',
          ),
        ];
  @override
  Future<List<NotificationItem>> fetchNotifications(
    StudentSession session,
  ) async => empty
      ? []
      : [
          NotificationItem(
            id: 'notification-1',
            title: 'Informasi baru untukmu',
            date: '28 Oktober 2026',
            category: longText
                ? 'Pemberitahuan Akademik Mahasiswa'
                : 'Informasi',
            summary: 'Buka untuk membaca informasi selengkapnya.',
            content: 'Isi pemberitahuan pengujian.',
          ),
        ];
  @override
  Future<void> markRead(StudentSession session, String notificationId) async {
    readCalls++;
    if (readFailure case final error?) throw error;
    if (readWait != null) await readWait!.future;
  }

  @override
  Future<void> signOut(StudentSession session) async {
    logoutCalls++;
  }
}

Future<void> login(WidgetTester tester) async {
  await tester.enterText(
    find.byKey(const Key('student-account')),
    ' student@example.invalid ',
  );
  await tester.enterText(
    find.byKey(const Key('student-password')),
    'test-only',
  );
  await tester.ensureVisible(find.byKey(const Key('student-sign-in')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('student-sign-in')));
  await tester.pumpAndSettle();
}

Future<void> tab(WidgetTester tester, String label) async {
  await tester.tap(find.widgetWithText(NavigationDestination, label));
  await tester.pumpAndSettle();
}

void viewport(WidgetTester tester, Size size, {double scale = 1}) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetViewInsets);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
}

void main() {
  WidgetController.hitTestWarningShouldBeFatal = true;
  test(
    'unconfigured production repository never accepts credentials',
    () async {
      final state = StudentController(const UnconfiguredStudentRepository());
      addTearDown(state.dispose);
      await state.signIn('account', 'password');
      expect(state.signedIn, false);
      expect(state.loginError, contains('belum tersedia'));
      expect(state.announcements, isEmpty);
    },
  );
  test(
    'login trims identifier but preserves password and rejects other roles',
    () async {
      final repo = TestRepository()..student = false;
      final state = StudentController(repo);
      addTearDown(state.dispose);
      await state.signIn(' user ', ' password ');
      expect(repo.capturedIdentifier, 'user');
      expect(repo.capturedPassword, ' password ');
      expect(state.signedIn, false);
      expect(repo.logoutCalls, 1);
      expect(state.loginError, contains('khusus akun mahasiswa'));
    },
  );
  test(
    'duplicate login is prevented and delayed login cannot undo logout',
    () async {
      final wait = Completer<StudentSession>();
      final repo = TestRepository()..loginWait = wait;
      final state = StudentController(repo);
      addTearDown(state.dispose);
      final pending = state.signIn('a', 'password');
      await state.signIn('a', 'password');
      expect(repo.loginCalls, 1);
      state.signOut();
      wait.complete(
        StudentSession(accountId: 'a', isStudent: true, handle: Object()),
      );
      await pending;
      expect(state.signedIn, false);
      expect(state.profile, null);
      expect(repo.logoutCalls, 1);
    },
  );
  test('logout clears private data, filters and notification count', () async {
    final repo = TestRepository();
    final state = StudentController(repo);
    addTearDown(state.dispose);
    await state.signIn('a', 'password');
    state.search('secret');
    state.filter('Akademik');
    state.selectTab(3);
    state.signOut();
    expect(state.signedIn, false);
    expect(state.profile, null);
    expect(state.announcements, isEmpty);
    expect(state.notifications, isEmpty);
    expect(state.unreadCount, 0);
    expect(state.query, '');
    expect(state.category, null);
    expect(state.tab, 0);
  });
  test('old account refresh cannot overwrite the next account', () async {
    final repo = TestRepository();
    final state = StudentController(repo);
    addTearDown(state.dispose);
    await state.signIn('a', 'password');
    final old = Completer<StudentProfile>();
    repo.profileWait = old;
    final pending = state.refresh();
    state.signOut();
    repo.profileWait = null;
    repo.accountId = 'student-b';
    await state.signIn('b', 'password');
    old.complete(const StudentProfile(id: 'student-a', name: 'Old account'));
    await pending;
    expect(state.profile!.id, 'student-b');
    expect(state.loading, false);
  });
  test(
    'expired or mismatched profile ends session without leaking data',
    () async {
      final repo = TestRepository();
      final state = StudentController(repo);
      addTearDown(state.dispose);
      await state.signIn('a', 'password');
      repo.profileWait = Completer<StudentProfile>()
        ..complete(const StudentProfile(id: 'other', name: 'Other'));
      await state.refresh();
      expect(state.signedIn, false);
      expect(state.loginError, contains('Sesi berakhir'));
      expect(state.profile, null);
    },
  );
  test(
    'read count changes only on confirmation, failure allows retry',
    () async {
      final repo = TestRepository();
      final state = StudentController(repo);
      addTearDown(state.dispose);
      await state.signIn('a', 'password');
      repo.readFailure = const StudentFailure(FailureKind.network);
      await state.markRead('notification-1');
      expect(state.unreadCount, 1);
      expect(state.readError, isNotNull);
      repo.readFailure = null;
      repo.readWait = Completer<void>();
      final pending = state.markRead('notification-1');
      await state.markRead('notification-1');
      expect(repo.readCalls, 2);
      expect(state.unreadCount, 1);
      repo.readWait!.complete();
      await pending;
      expect(state.unreadCount, 0);
      expect(state.readError, null);
      await state.markRead('notification-1');
      await state.markRead('unknown');
      expect(repo.readCalls, 2);
      await state.refresh();
      expect(state.unreadCount, 0);
    },
  );
  test('session expiry during mark-read clears session', () async {
    final repo = TestRepository();
    final state = StudentController(repo);
    addTearDown(state.dispose);
    await state.signIn('a', 'password');
    repo.readFailure = const StudentFailure(FailureKind.expired);
    await state.markRead('notification-1');
    expect(state.signedIn, false);
    expect(state.notifications, isEmpty);
  });
  test(
    'fetch failure is retryable and does not insert demo information',
    () async {
      final repo = TestRepository()
        ..fetchFailure = const StudentFailure(FailureKind.network);
      final state = StudentController(repo);
      addTearDown(state.dispose);
      await state.signIn('a', 'password');
      expect(state.signedIn, true);
      expect(state.profile, null);
      expect(state.announcements, isEmpty);
      expect(state.dataError, isNotNull);
      repo.fetchFailure = null;
      await state.refresh();
      expect(state.profile, isNotNull);
      expect(state.dataError, null);
      state.search(' MAGANG ');
      state.filter('Karier');
      expect(state.filteredAnnouncements.single.id, 'announcement-2');
    },
  );
  testWidgets('login validates input; credential failure stays at login', (
    tester,
  ) async {
    final repo = TestRepository()
      ..loginFailure = const StudentFailure(FailureKind.credentials);
    await tester.pumpWidget(StudentApp(repository: repo));
    await tester.tap(find.byKey(const Key('student-sign-in')));
    await tester.pumpAndSettle();
    expect(repo.loginCalls, 0);
    expect(find.text('Masukkan email.'), findsOneWidget);
    await login(tester);
    expect(find.textContaining('tidak sesuai'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    final field = tester.widget<TextFormField>(
      find.byKey(const Key('student-password')),
    );
    expect(field.controller!.text, isEmpty);
  });
  testWidgets(
    'student journey: login, filter, details, read status, profile, logout',
    (tester) async {
      viewport(tester, const Size(390, 844));
      final repo = TestRepository();
      await tester.pumpWidget(StudentApp(repository: repo));
      await login(tester);
      expect(find.text('Mahasiswa Pengujian'), findsOneWidget);
      expect(
        IconTheme.of(tester.element(find.byIcon(Icons.home_rounded))).color,
        const Color(0xFF0F172A),
      );
      await tab(tester, 'Informasi');
      await tester.enterText(
        find.widgetWithText(TextField, 'Cari informasi'),
        'magang',
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Pendaftaran magang'));
      await tester.tap(find.text('Pendaftaran magang'));
      await tester.pumpAndSettle();
      expect(find.text('Detail magang pengujian.'), findsOneWidget);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text('1 informasi'), findsOneWidget);
      await tab(tester, 'Notifikasi');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Informasi baru untukmu'));
      await tester.pumpAndSettle();
      expect(find.text('Sudah dibaca'), findsOneWidget);
      expect(repo.readCalls, 1);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text('Semua pemberitahuan sudah dibaca.'), findsOneWidget);
      await tab(tester, 'Profil');
      expect(find.text('TEST-001'), findsOneWidget);
      await tester.ensureVisible(find.byKey(const Key('student-sign-out')));
      await tester.tap(find.byKey(const Key('student-sign-out')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();
      expect(find.text('TEST-001'), findsOneWidget);
      await tester.tap(find.byKey(const Key('student-sign-out')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Keluar'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('student-sign-in')), findsOneWidget);
      expect(find.text('TEST-001'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'notification error offers retry and expired detail returns to login',
    (tester) async {
      final repo = TestRepository()
        ..readFailure = const StudentFailure(FailureKind.network);
      await tester.pumpWidget(StudentApp(repository: repo));
      await login(tester);
      await tab(tester, 'Notifikasi');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Informasi baru untukmu'));
      await tester.pumpAndSettle();
      expect(find.text('Belum dibaca'), findsOneWidget);
      expect(
        find.textContaining('Status baca belum tersimpan'),
        findsOneWidget,
      );
      repo.readFailure = const StudentFailure(FailureKind.expired);
      await tester.tap(find.text('Coba lagi'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Sesi berakhir'), findsOneWidget);
      expect(find.text('Isi pemberitahuan pengujian.'), findsNothing);
    },
  );
  testWidgets('Android back returns detail to list and tab to home', (
    tester,
  ) async {
    await tester.pumpWidget(StudentApp(repository: TestRepository()));
    await login(tester);
    await tab(tester, 'Notifikasi');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Informasi baru untukmu'));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Isi pemberitahuan pengujian.'), findsNothing);
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      3,
    );
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      0,
    );
  });
  testWidgets('small screen and enlarged text fit login, all tabs and detail', (
    tester,
  ) async {
    viewport(tester, const Size(320, 640), scale: 1.5);
    await tester.pumpWidget(
      StudentApp(repository: TestRepository()..longText = true),
    );
    expect(tester.takeException(), isNull);
    await login(tester);
    for (final label in ['Beranda', 'Informasi', 'Notifikasi', 'Profil']) {
      await tab(tester, label);
      expect(tester.takeException(), isNull, reason: label);
    }
    await tab(tester, 'Notifikasi');
    await tester.scrollUntilVisible(
      find.text('Informasi baru untukmu'),
      120,
      scrollable: find
          .descendant(
            of: find.byKey(const PageStorageKey('student-notifications')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Informasi baru untukmu'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
  testWidgets('landscape keyboard does not overflow login or search', (
    tester,
  ) async {
    viewport(tester, const Size(640, 360));
    tester.view.viewInsets = const FakeViewPadding(bottom: 160);
    await tester.pumpWidget(StudentApp(repository: TestRepository()));
    await login(tester);
    expect(tester.takeException(), isNull);
    await tab(tester, 'Informasi');
    await tester.ensureVisible(
      find.widgetWithText(TextField, 'Cari informasi'),
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Cari informasi'),
      'no match',
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(
      find.text('Reset pencarian'),
      100,
      scrollable: find
          .descendant(
            of: find.byKey(const PageStorageKey('student-information')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reset pencarian'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('2 informasi'),
      -100,
      scrollable: find
          .descendant(
            of: find.byKey(const PageStorageKey('student-information')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(find.text('2 informasi'), findsOneWidget);
  });
  testWidgets('empty and failed data states remain recoverable', (
    tester,
  ) async {
    final repo = TestRepository()
      ..fetchFailure = const StudentFailure(FailureKind.network);
    await tester.pumpWidget(StudentApp(repository: repo));
    await login(tester);
    expect(find.text('Coba lagi'), findsOneWidget);
    repo.fetchFailure = null;
    repo.empty = true;
    await tester.tap(find.text('Coba lagi'));
    await tester.pumpAndSettle();
    await tab(tester, 'Notifikasi');
    expect(find.text('Belum ada pemberitahuan'), findsOneWidget);
    await tab(tester, 'Informasi');
    expect(find.text('Tidak ada informasi'), findsOneWidget);
  });
  testWidgets(
    'unconfigured entry disables login and renders honest service state',
    (tester) async {
      await tester.pumpWidget(
        const StudentApp(repository: UnconfiguredStudentRepository()),
      );
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('student-sign-in')))
            .onPressed,
        null,
      );
      expect(find.textContaining('belum tersedia'), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
    },
  );
  testWidgets('load failure remains scrollable with keyboard in landscape', (
    tester,
  ) async {
    viewport(tester, const Size(640, 360), scale: 1.5);
    tester.view.viewInsets = const FakeViewPadding(bottom: 160);
    final repo = TestRepository()
      ..fetchFailure = const StudentFailure(FailureKind.network);
    await tester.pumpWidget(StudentApp(repository: repo));
    await login(tester);
    expect(tester.takeException(), isNull);
    await tester.tap(find.byTooltip('Kembali ke halaman masuk'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('student-sign-in')), findsOneWidget);
  });
  testWidgets('capture deterministic UI previews with test data only', (
    tester,
  ) async {
    if (!const bool.fromEnvironment('CAPTURE_STUDENT_PREVIEW')) return;
    viewport(tester, const Size(390, 844));
    final key = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: StudentApp(repository: TestRepository()),
      ),
    );
    await tester.pumpAndSettle();
    Future<void> capture(String name) async {
      await tester.runAsync(() async {
        final boundary =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 2);
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        final directory = Directory('docs/evidence/student-preview');
        await directory.create(recursive: true);
        await File('${directory.path}/$name.png')
            .writeAsBytes(data!.buffer.asUint8List());
        image.dispose();
      });
    }

    await capture('login-test-render');
    await login(tester);
    await capture('home-test-render');
    await tab(tester, 'Informasi');
    await capture('information-test-render');
    await tab(tester, 'Profil');
    await capture('profile-test-render');
  });
}
