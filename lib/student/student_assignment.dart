import 'dart:convert';
import 'dart:typed_data';

import 'student_repository.dart';

const maxAnswerBytes = 10 * 1024 * 1024;

class AssignmentRef {
  const AssignmentRef(this.classId, this.assignmentId);
  final String classId, assignmentId;
  String get key => '$classId/$assignmentId';
}

class AnswerFile {
  const AnswerFile({required this.name, required this.bytes});
  final String name;
  final Uint8List bytes;
  String get extension => name.split('.').last.toLowerCase();
  void validate(List<String> allowed) {
    if (bytes.isEmpty) throw const StudentFailure(FailureKind.emptyAnswer);
    if (bytes.length > maxAnswerBytes) {
      throw const StudentFailure(FailureKind.answerTooLarge);
    }
    if (!allowed.contains(extension)) {
      throw const StudentFailure(FailureKind.answerFormat);
    }
  }
}

class AnswerVersion {
  const AnswerVersion({
    required this.id,
    required this.number,
    required this.type,
    required this.submittedAt,
    this.fileName,
    this.content = '',
  });
  final String id, type, submittedAt, content;
  final String? fileName;
  final int number;
}

class ReleasedResult {
  const ReleasedResult({required this.score, required this.feedback});
  final num score;
  final String feedback;
}

class SubmittedAnswer {
  const SubmittedAnswer({
    required this.id,
    required this.activeVersionId,
    required this.versions,
    this.result,
  });
  final String id, activeVersionId;
  final List<AnswerVersion> versions;
  final ReleasedResult? result;
  AnswerVersion? get active {
    for (final v in versions) {
      if (v.id == activeVersionId) return v;
    }
    return null;
  }
}

class StudentAssignment {
  const StudentAssignment({
    required this.ref,
    required this.title,
    required this.className,
    required this.instructions,
    required this.type,
    required this.status,
    required this.dueAt,
    required this.dueLabel,
    required this.maxScore,
    required this.allowLate,
    required this.canSubmit,
    this.submission,
    this.rubric = const [],
  });
  final AssignmentRef ref;
  final String title, className, instructions, type, status, dueLabel;
  final DateTime dueAt;
  final num maxScore;
  final bool allowLate, canSubmit;
  final SubmittedAnswer? submission;
  final List<String> rubric;
  bool get acceptsText => type == 'ANY' || type == 'TEXT';
  List<String> get fileExtensions => switch (type) {
    'ANY' => const ['pdf', 'docx'],
    'PDF' => const ['pdf'],
    'DOCX' => const ['docx'],
    _ => const [],
  };
  String? get blockedReason {
    if (!canSubmit) {
      return 'Pengumpulan hanya tersedia untuk anggota mahasiswa pada kelas ini.';
    }
    if (status != 'PUBLISHED') {
      return 'Tugas ini sudah ditutup dan tidak menerima pengumpulan.';
    }
    if (submission?.result != null) {
      return 'Nilai sudah dirilis. Hubungi dosen jika jawaban perlu diperbarui.';
    }
    if (!allowLate && DateTime.now().isAfter(dueAt)) {
      return 'Tenggat pengumpulan sudah berakhir.';
    }
    if (type == 'SCAN') {
      return 'Tugas ini meminta scan dengan verifikasi OCR. Fitur scan khusus belum tersedia di mobile.';
    }
    if (!acceptsText && fileExtensions.isEmpty) {
      return 'Format tugas ini belum didukung.';
    }
    return null;
  }

  void validateAnswer(String? text, AnswerFile? file) {
    if (blockedReason != null) {
      throw const StudentFailure(FailureKind.submissionClosed);
    }
    if (file != null) {
      file.validate(fileExtensions);
      return;
    }
    if (!acceptsText) throw const StudentFailure(FailureKind.answerFormat);
    if (text == null || text.trim().isEmpty) {
      throw const StudentFailure(FailureKind.emptyAnswer);
    }
    if (utf8.encode(text.trim()).length > maxAnswerBytes) {
      throw const StudentFailure(FailureKind.answerTooLarge);
    }
  }
}

class SubmissionReceipt {
  const SubmissionReceipt({
    required this.submissionId,
    required this.versionId,
    required this.number,
  });
  final String submissionId, versionId;
  final int number;
}

abstract interface class StudentSubmissionRepository {
  Future<StudentAssignment> fetchAssignment(
    StudentSession session,
    AssignmentRef ref,
  );
  Future<SubmissionReceipt> submitAnswer(
    StudentSession session,
    StudentAssignment assignment, {
    String? text,
    AnswerFile? file,
  });
}
