import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';

import 'student_assignment.dart';
import 'student_repository.dart';

typedef AnswerFilePicker = Future<AnswerFile?> Function(
  List<String> extensions,
);

Future<AnswerFile?> pickAnswerFile(List<String> extensions) async {
  final file = await openFile(
    acceptedTypeGroups: [
      XTypeGroup(
        label: 'Dokumen jawaban',
        extensions: extensions,
        mimeTypes: [
          if (extensions.contains('pdf')) 'application/pdf',
          if (extensions.contains('docx')) 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
        ],
      ),
    ],
  );
  if (file == null) return null;
  if (await file.length() > maxAnswerBytes) {
    throw const StudentFailure(FailureKind.answerTooLarge);
  }
  final builder = BytesBuilder(copy: false);
  await for (final chunk in file.openRead()) {
    if (builder.length + chunk.length > maxAnswerBytes) {
      throw const StudentFailure(FailureKind.answerTooLarge);
    }
    builder.add(chunk);
  }
  final answer = AnswerFile(name: file.name, bytes: builder.takeBytes());
  answer.validate(extensions);
  return answer;
}
