import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dexa_assessment_mobile/student/student_assignment.dart';
import 'package:dexa_assessment_mobile/student/student_assignment_page.dart';
import 'package:dexa_assessment_mobile/student/student_controller.dart';
import 'package:dexa_assessment_mobile/student/student_repository.dart';
import 'package:dexa_assessment_mobile/student/answer_file_picker.dart';

import 'student_flow_test.dart' show TestRepository;

class UploadRepo extends TestRepository implements StudentSubmissionRepository {
  int sends = 0;
  bool failRefresh = false;
  String? sentText;
  AnswerFile? sentFile;
  Completer<SubmissionReceipt>? delayed;
  StudentFailure? submitFailure;
  SubmittedAnswer? stored;
  @override
  Future<StudentAssignment> fetchAssignment(
    StudentSession session,
    AssignmentRef ref,
  ) async {
    if (failRefresh && sends > 0) {
      throw const StudentFailure(FailureKind.network);
    }
    return StudentAssignment(
      ref: ref,
      title: 'Tugas mobile',
      className: 'Kelas pengujian',
      instructions: 'Jelaskan jawaban dengan lengkap.',
      type: 'ANY',
      status: 'PUBLISHED',
      dueAt: DateTime(2099),
      dueLabel: '1 Jan 2099',
      maxScore: 100,
      allowLate: false,
      canSubmit: true,
      submission: stored,
    );
  }

  @override
  Future<SubmissionReceipt> submitAnswer(
    StudentSession session,
    StudentAssignment assignment, {
    String? text,
    AnswerFile? file,
  }) async {
    sends++;
    sentText = text;
    sentFile = file;
    if (submitFailure != null) throw submitFailure!;
    final receipt = delayed == null
        ? SubmissionReceipt(
            submissionId: 's',
            versionId: 'v$sends',
            number: sends,
          )
        : await delayed!.future;
    stored = SubmittedAnswer(
      id: 's',
      activeVersionId: receipt.versionId,
      versions: [
        AnswerVersion(
          id: receipt.versionId,
          number: receipt.number,
          type: file == null ? 'TEXT' : 'PDF',
          fileName: file?.name,
          submittedAt: 'Hari ini',
          content: text ?? 'Isi dokumen',
        ),
      ],
    );
    return receipt;
  }
}

Future<StudentController> showUpload(
  WidgetTester tester,
  UploadRepo repo, {
  AnswerFilePicker? picker,
  double width = 390,
  double scale = 1,
}) async {
  final state = StudentController(repo);
  await state.signIn('test', 'test-only');
  tester.view.physicalSize = Size(width * 2, 1600);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(state.dispose);
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: StudentAssignmentPage(
        state: state,
        ref: const AssignmentRef('class', 'task'),
        filePicker: picker ?? ((_) async => null),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return state;
}

Future<void> reveal(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    180,
    scrollable: find
        .descendant(
          of: find.byKey(const PageStorageKey('student-assignment-detail')),
          matching: find.byType(Scrollable),
        )
        .first,
  );
  await tester.pumpAndSettle();
  await tester.ensureVisible(finder);
}

Future<void> submit(WidgetTester tester) async {
  await reveal(tester, find.byKey(const Key('student-send-answer')));
  await tester.tap(find.byKey(const Key('student-send-answer')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('confirm-answer-send')));
  await tester.pump();
}

void main() {
  testWidgets(
    'text submission requires confirmation, blocks duplicate taps, then shows server receipt',
    (tester) async {
      final repo = UploadRepo()..delayed = Completer<SubmissionReceipt>();
      await showUpload(tester, repo);
      await reveal(tester, find.byKey(const Key('student-answer-text')));
      await tester.enterText(
        find.byKey(const Key('student-answer-text')),
        'Jawaban saya',
      );
      await submit(tester);
      expect(repo.sends, 1);
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('student-send-answer')))
            .onPressed,
        isNull,
      );
      repo.delayed!.complete(
        const SubmissionReceipt(submissionId: 's', versionId: 'v1', number: 1),
      );
      await tester.pumpAndSettle();
      await tester.drag(
        find.byKey(const PageStorageKey('student-assignment-detail')),
        const Offset(0, 1500),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Jawaban berhasil dikirim'), findsOneWidget);
      expect(repo.sentText, 'Jawaban saya');
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'file cancel is harmless; selected PDF is sent and appears in history',
    (tester) async {
      final repo = UploadRepo();
      var picks = 0;
      await showUpload(
        tester,
        repo,
        picker: (_) async => ++picks == 1
            ? null
            : AnswerFile(
                name: 'jawaban.pdf',
                bytes: Uint8List.fromList([37, 80, 68, 70]),
              ),
      );
      await reveal(tester, find.byKey(const Key('answer-mode-file')));
      await tester.tap(find.byKey(const Key('answer-mode-file')));
      await tester.pumpAndSettle();
      await reveal(tester, find.byKey(const Key('student-pick-answer')));
      await tester.tap(find.byKey(const Key('student-pick-answer')));
      await tester.pumpAndSettle();
      expect(repo.sends, 0);
      await tester.tap(find.byKey(const Key('student-pick-answer')));
      await tester.pumpAndSettle();
      expect(find.text('jawaban.pdf'), findsOneWidget);
      await submit(tester);
      await tester.pumpAndSettle();
      expect(repo.sentFile!.name, 'jawaban.pdf');
      expect(repo.sentText, isNull);
    },
  );
  testWidgets(
    'uncertain request retains draft and requires status check before another send',
    (tester) async {
      final repo = UploadRepo()
        ..submitFailure = const StudentFailure(FailureKind.submissionUncertain);
      await showUpload(tester, repo);
      await reveal(tester, find.byKey(const Key('student-answer-text')));
      await tester.enterText(
        find.byKey(const Key('student-answer-text')),
        'Jangan hilangkan jawaban',
      );
      await submit(tester);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('student-send-answer')))
            .onPressed,
        isNull,
      );
      await reveal(tester, find.byKey(const Key('check-submission-status')));
      expect(repo.sends, 1);
      await tester.tap(find.byKey(const Key('check-submission-status')));
      await tester.pumpAndSettle();
      await reveal(tester, find.byKey(const Key('student-answer-text')));
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('student-answer-text')))
            .controller!
            .text,
        'Jangan hilangkan jawaban',
      );
    },
  );
  testWidgets('accepted upload remains success when status refresh fails', (
    tester,
  ) async {
    final repo = UploadRepo()..failRefresh = true;
    await showUpload(tester, repo);
    await reveal(tester, find.byKey(const Key('student-answer-text')));
    await tester.enterText(
      find.byKey(const Key('student-answer-text')),
      'Jawaban',
    );
    await submit(tester);
    await tester.pumpAndSettle();
    await tester.drag(
      find.byKey(const PageStorageKey('student-assignment-detail')),
      const Offset(0, 1500),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Jawaban berhasil dikirim'), findsOneWidget);
    expect(repo.sends, 1);
  });
  testWidgets('small screen and large text with keyboard do not overflow', (
    tester,
  ) async {
    await showUpload(tester, UploadRepo(), width: 320, scale: 1.5);
    await reveal(tester, find.byKey(const Key('student-answer-text')));
    await tester.showKeyboard(find.byKey(const Key('student-answer-text')));
    await tester.enterText(
      find.byKey(const Key('student-answer-text')),
      'Jawaban panjang untuk layar kecil',
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
  test(
    'late submit response cannot attach to a new or logged-out session',
    () async {
      final repo = UploadRepo()..delayed = Completer<SubmissionReceipt>();
      final state = StudentController(repo);
      addTearDown(state.dispose);
      await state.signIn('test', 'test-only');
      final task = await state.assignment(const AssignmentRef('class', 'task'));
      final pending = state.submitAnswer(task, text: 'jawaban');
      final check = expectLater(
        pending,
        throwsA(
          isA<StudentFailure>().having(
            (e) => e.kind,
            'kind',
            FailureKind.expired,
          ),
        ),
      );
      await expectLater(
        state.submitAnswer(task, text: 'again'),
        throwsA(
          isA<StudentFailure>().having(
            (e) => e.kind,
            'kind',
            FailureKind.submissionBusy,
          ),
        ),
      );
      state.signOut();
      repo.delayed!.complete(
        const SubmissionReceipt(submissionId: 's', versionId: 'v', number: 1),
      );
      await check;
      expect(state.signedIn, false);
      expect(repo.sends, 1);
    },
  );
}
