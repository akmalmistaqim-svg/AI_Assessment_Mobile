import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dexa_assessment_mobile/models/announcement.dart';
import 'package:dexa_assessment_mobile/student/student_repository.dart';
import 'package:dexa_assessment_mobile/student/student_controller.dart';
import 'package:dexa_assessment_mobile/student/student_app.dart';

import 'student_flow_test.dart' show TestRepository, login, tab, viewport;

const course = StudentClass(
  id: 'rpl-a',
  name: 'Rekayasa Perangkat Lunak A',
  subject: 'RPL-2026',
  lecturer: 'Dosen A',
);

class ClassRepository extends TestRepository {
  bool enrolled = false;
  bool failReload = false;
  int joinCalls = 0;
  String? receivedCode;
  StudentFailure? joinFailure, taskFailure;
  Completer<JoinedClass>? joinWait;
  @override
  Future<List<StudentClass>> fetchClasses(StudentSession session) async {
    if (failReload) throw const StudentFailure(FailureKind.network);
    return enrolled ? [course] : [];
  }

  @override
  Future<List<Announcement>> fetchAnnouncements(StudentSession session) async =>
      enrolled ? super.fetchAnnouncements(session) : [];
  @override
  Future<JoinedClass> joinClass(StudentSession session, String code) async {
    joinCalls++;
    receivedCode = code;
    if (joinFailure != null) throw joinFailure!;
    if (joinWait != null) return joinWait!.future;
    enrolled = true;
    return const JoinedClass(id: 'rpl-a', name: 'Rekayasa Perangkat Lunak A');
  }

  @override
  Future<List<Announcement>> fetchClassAssignments(
    StudentSession session,
    StudentClass course,
  ) async {
    if (taskFailure != null) throw taskFailure!;
    return super.fetchAnnouncements(session);
  }
}

void main() {
  WidgetController.hitTestWarningShouldBeFatal = true;
  test('join reloads membership and feed; failed refresh preserves success without duplicate POST', () async {
    final repo = ClassRepository();
    final state = StudentController(repo);
    addTearDown(state.dispose);
    await state.signIn('student@example.invalid', 'test-only');
    expect(state.classes, isEmpty);
    await state.joinClass(' rpl123 ');
    expect(repo.receivedCode, 'RPL123');
    expect(state.classes.single.id, course.id);
    expect(state.announcements, isNotEmpty);
    repo.failReload = true;
    expect(await state.joinClass('OTHER'), isNotNull);
    expect(state.dataError, isNotNull);
    expect(state.joinError, isNull);
    expect(repo.joinCalls, 2);
  });
  test(
    'double tap and late join cannot replace a signed-out account',
    () async {
      final repo = ClassRepository()..joinWait = Completer<JoinedClass>();
      final state = StudentController(repo);
      addTearDown(state.dispose);
      await state.signIn('a', 'test-only');
      final pending = state.joinClass('CODE');
      expect(await state.joinClass('CODE'), isNull);
      expect(repo.joinCalls, 1);
      state.signOut();
      repo.joinWait!.complete(const JoinedClass(id: 'rpl-a', name: 'RPL'));
      expect(await pending, isNull);
      expect(state.classes, isEmpty);
      expect(state.signedIn, false);
      expect(state.joining, false);
    },
  );
  test('expired join logs out and clears class state', () async {
    final repo = ClassRepository()..enrolled = true;
    final state = StudentController(repo);
    addTearDown(state.dispose);
    await state.signIn('a', 'test-only');
    repo.joinFailure = const StudentFailure(FailureKind.expired);
    await state.joinClass('CODE');
    expect(state.signedIn, false);
    expect(state.classes, isEmpty);
  });
  testWidgets(
    'join from empty account, open class and task, return, then logout',
    (tester) async {
      viewport(tester, const Size(390, 844));
      final repo = ClassRepository();
      await tester.pumpWidget(StudentApp(repository: repo));
      await login(tester);
      await tab(tester, 'Kelas Saya');
      expect(find.textContaining('Belum mengikuti kelas.'), findsOneWidget);
      await tester.tap(find.byKey(const Key('student-join-class')));
      await tester.pumpAndSettle();
      expect(repo.joinCalls, 0);
      expect(find.text('Masukkan kode kelas.'), findsOneWidget);
      repo.joinFailure = const StudentFailure(FailureKind.invalidClassCode);
      await tester.enterText(
        find.byKey(const Key('student-class-code')),
        'wrong',
      );
      await tester.tap(find.byKey(const Key('student-join-class')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Kode kelas tidak ditemukan'), findsOneWidget);
      expect(find.byKey(const ValueKey('class-rpl-a')), findsNothing);
      repo.joinFailure = null;
      await tester.enterText(
        find.byKey(const Key('student-class-code')),
        'rpl123',
      );
      await tester.tap(find.byKey(const Key('student-join-class')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Berhasil bergabung ke'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('class-rpl-a')),
        180,
        scrollable: find.descendant(
          of: find.byKey(const PageStorageKey('student-classes')),
          matching: find.byWidgetPredicate(
            (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('class-rpl-a')));
      await tester.pumpAndSettle();
      expect(find.text('Detail kelas'), findsOneWidget);
      expect(find.text('Dosen: Dosen A'), findsOneWidget);
      await tester.tap(find.text('Jadwal evaluasi semester'));
      await tester.pumpAndSettle();
      expect(
        find.text('Isi informasi dari repository pengujian.'),
        findsOneWidget,
      );
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Detail kelas'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('student-class-code')), findsOneWidget);
      await tab(tester, 'Informasi');
      expect(find.text('Jadwal evaluasi semester'), findsOneWidget);
      await tab(tester, 'Profil');
      await tester.ensureVisible(find.byKey(const Key('student-sign-out')));
      await tester.tap(find.byKey(const Key('student-sign-out')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Keluar'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('student-sign-in')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'class screen fits small enlarged text and detail errors can retry',
    (tester) async {
      viewport(tester, const Size(320, 640), scale: 1.5);
      final repo = ClassRepository()..enrolled = true;
      await tester.pumpWidget(StudentApp(repository: repo));
      await login(tester);
      await tab(tester, 'Kelas Saya');
      await tester.ensureVisible(find.byKey(const Key('student-class-code')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('student-class-code')));
      tester.view.viewInsets = const FakeViewPadding(bottom: 220);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      tester.view.resetViewInsets();
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      repo.taskFailure = const StudentFailure(FailureKind.accessDenied);
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('class-rpl-a')),
        180,
        scrollable: find.descendant(
          of: find.byKey(const PageStorageKey('student-classes')),
          matching: find.byWidgetPredicate(
            (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('class-rpl-a')));
      await tester.pumpAndSettle();
      expect(find.textContaining('tidak memiliki akses'), findsOneWidget);
      repo.taskFailure = null;
      await tester.ensureVisible(find.text('Coba lagi'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Coba lagi'));
      await tester.pumpAndSettle();
      expect(find.text('Jadwal evaluasi semester'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
