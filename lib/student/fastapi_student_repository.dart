import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/announcement.dart';
import '../models/notification_item.dart';
import 'student_repository.dart';
import 'student_assignment.dart';
import 'student_registration.dart';

/// Uses the existing FastAPI contract; never calls fabricated feed endpoints.
/// Notifications represent RELEASED grades. Read receipts are device-local.
class FastApiStudentRepository
    implements
        StudentRepository,
        StudentSubmissionRepository,
        StudentRegistrationRepository {
  FastApiStudentRepository({
    required this.baseUri,
    this.timeout = const Duration(seconds: 15),
    this.connectionTimeout = const Duration(seconds: 5),
    this.allowInsecureDevelopment = false,
  });
  final Uri baseUri;
  final Duration timeout;
  final Duration connectionTimeout;
  final bool allowInsecureDevelopment;
  Future<void> _writeQueue = Future<void>.value();
  @override
  bool get isConfigured =>
      baseUri.hasAuthority &&
      baseUri.host.isNotEmpty &&
      baseUri.userInfo.isEmpty &&
      !baseUri.hasQuery &&
      !baseUri.hasFragment &&
      (baseUri.scheme == 'https' ||
          (allowInsecureDevelopment && baseUri.scheme == 'http'));

  Uri _url(String path) => baseUri.replace(
    path: '${baseUri.path.replaceFirst(RegExp(r'/+$'), '')}$path',
  );

  Future<Object?> _request(
    String method,
    String path, {
    StudentSession? session,
    Map<String, Object?>? body,
    bool login = false,
    bool joining = false,
    bool submitting = false,
    bool registering = false,
    AnswerFile? file,
  }) async {
    if (!isConfigured) throw const StudentFailure(FailureKind.unavailable);
    final client = HttpClient()..connectionTimeout = connectionTimeout;
    bool mayHaveSent = false;
    try {
      return await (() async {
        final request = await client.openUrl(method, _url(path));
        // Never forward Authorization or login credentials to redirected hosts.
        request.followRedirects = false;
        request.headers.set(HttpHeaders.acceptHeader, 'application/json');
        if (session != null) {
          request.headers.set(
            HttpHeaders.authorizationHeader,
            'Bearer ${_credentials(session).token}',
          );
        }
        // Once a request may be sent, a lost response cannot prove failure.
        mayHaveSent = true;
        if (file != null) {
          final boundary =
              'dexa${DateTime.now().microsecondsSinceEpoch}${Random.secure().nextInt(1 << 30)}';
          final name = file.name
              .split(RegExp(r'[/\\]'))
              .last
              .replaceAll(RegExp(r'[\r\n"\\]'), '_');
          request.headers.contentType = ContentType(
            'multipart',
            'form-data',
            parameters: {'boundary': boundary},
          );
          final mime = file.extension == 'pdf'
              ? 'application/pdf'
              : 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
          request.add(
            utf8.encode(
              '--$boundary\r\nContent-Disposition: form-data; name="file"; filename="$name"\r\nContent-Type: $mime\r\n\r\n',
            ),
          );
          request.add(file.bytes);
          request.add(utf8.encode('\r\n--$boundary--\r\n'));
        } else if (body != null) {
          request.headers.contentType = ContentType.json;
          request.write(jsonEncode(body));
        }
        final response = await request.close();
        final code = response.statusCode;
        if (registering && (code == 400 || code == 409 || code == 422)) {
          final chunks = <int>[];
          await for (final chunk in response) {
            chunks.addAll(chunk);
            if (chunks.length > 16384) break;
          }
          String detail = '';
          try {
            final decoded = jsonDecode(utf8.decode(chunks));
            if (decoded is Map && decoded['detail'] is String) {
              detail = decoded['detail'];
            }
          } catch (_) {
            /* Do not expose server internals. */
          }
          if (detail.toLowerCase().contains('email sudah terdaftar')) {
            throw const StudentFailure(FailureKind.registrationDuplicate);
          }
          throw const StudentFailure(FailureKind.registrationInvalid);
        }
        if (code == 401) {
          throw StudentFailure(
            login ? FailureKind.credentials : FailureKind.expired,
          );
        }
        if (submitting &&
            (code == 400 ||
                code == 403 ||
                code == 404 ||
                code == 413 ||
                code == 422)) {
          final chunks = <int>[];
          await for (final chunk in response) {
            chunks.addAll(chunk);
            if (chunks.length > 16384) break;
          }
          String detail = '';
          try {
            final parsed = jsonDecode(utf8.decode(chunks));
            if (parsed is Map && parsed['detail'] is String) {
              detail = parsed['detail'];
            }
          } catch (_) {
            /* Never expose arbitrary server errors. */
          }
          if (code == 413 ||
              detail.contains('10MB') ||
              detail.contains('maksimum 10')) {
            throw const StudentFailure(FailureKind.answerTooLarge);
          }
          if (detail.contains('Tenggat') || detail.contains('tidak menerima')) {
            throw const StudentFailure(FailureKind.submissionClosed);
          }
          if (code == 403 || code == 404) {
            throw const StudentFailure(FailureKind.accessDenied);
          }
          if (detail.contains('format') ||
              detail.contains('memerlukan pengumpulan')) {
            throw const StudentFailure(FailureKind.answerFormat);
          }
          throw const StudentFailure(FailureKind.submissionRejected);
        }
        if (code == 403) throw const StudentFailure(FailureKind.accessDenied);
        if (code == 429) throw const StudentFailure(FailureKind.rateLimited);
        if (joining && (code == 400 || code == 404 || code == 422)) {
          if (code == 404 || code == 422) {
            throw const StudentFailure(FailureKind.invalidClassCode);
          }
          final errorBytes = <int>[];
          await for (final chunk in response) {
            errorBytes.addAll(chunk);
            if (errorBytes.length > 16384) {
              throw const StudentFailure(FailureKind.joinRejected);
            }
          }
          final errorBody = jsonDecode(utf8.decode(errorBytes));
          final detail = errorBody is Map ? errorBody['detail'] : null;
          if (detail is String && detail.contains('sudah terdaftar')) {
            throw const StudentFailure(FailureKind.alreadyEnrolled);
          }
          if (detail is String && detail.contains('diarsipkan')) {
            throw const StudentFailure(FailureKind.archivedClass);
          }
          throw const StudentFailure(FailureKind.joinRejected);
        }
        if (code == 400 || code == 422) {
          throw StudentFailure(
            login ? FailureKind.credentials : FailureKind.invalidResponse,
          );
        }
        if (code < 200 || code >= 300) {
          throw StudentFailure(
            submitting
                ? FailureKind.submissionUncertain
                : FailureKind.unavailable,
          );
        }
        final bytes = <int>[];
        await for (final chunk in response) {
          bytes.addAll(chunk);
          if (bytes.length > 8 * 1024 * 1024) {
            throw const StudentFailure(FailureKind.invalidResponse);
          }
        }
        return jsonDecode(utf8.decode(bytes));
      })().timeout(submitting ? const Duration(seconds: 120) : timeout);
    } on StudentFailure catch (error) {
      if (registering &&
          (error.kind == FailureKind.invalidResponse ||
              error.kind == FailureKind.unavailable)) {
        throw const StudentFailure(FailureKind.registrationUncertain);
      }

      if (submitting && error.kind == FailureKind.invalidResponse) {
        throw const StudentFailure(FailureKind.submissionUncertain);
      }
      rethrow;
    } on FormatException {
      if (registering) {
        throw const StudentFailure(FailureKind.registrationUncertain);
      }
      throw StudentFailure(
        submitting
            ? FailureKind.submissionUncertain
            : FailureKind.invalidResponse,
      );
    } catch (_) {
      if (registering) {
        throw StudentFailure(
          mayHaveSent ? FailureKind.registrationUncertain : FailureKind.network,
        );
      }
      throw StudentFailure(
        submitting ? FailureKind.submissionUncertain : FailureKind.network,
      );
    } finally {
      client.close(force: true);
    }
  }

  _Credentials _credentials(StudentSession session) {
    final credentials = session.handle;
    if (credentials is! _Credentials ||
        credentials.token == null ||
        !identical(credentials.owner, this)) {
      throw const StudentFailure(FailureKind.expired);
    }
    return credentials;
  }

  @override
  Future<StudentSession> signIn(String identifier, String password) async {
    final data = _object(
      await _request(
        'POST',
        '/auth/login',
        login: true,
        body: {'email': identifier.trim().toLowerCase(), 'password': password},
      ),
    );
    final user = _object(data['user']);
    final token = _string(data, 'access_token');
    if (_string(data, 'token_type').toLowerCase() != 'bearer') {
      throw const StudentFailure(FailureKind.invalidResponse);
    }
    final id = _string(user, 'id');
    final name = user['name'] is String ? (user['name'] as String).trim() : '';
    final email = user['email'] is String ? (user['email'] as String).trim() : '';
    final isStudent = _string(user, 'role') == 'MAHASISWA';
    return StudentSession(
      accountId: id,
      isStudent: isStudent,
      handle: _Credentials(this, token),
      initialProfile: (name.isNotEmpty || email.isNotEmpty)
          ? StudentProfile(
              id: id,
              name: name.isEmpty ? 'Mahasiswa' : name,
              email: email.isEmpty ? identifier.trim() : email,
            )
          : null,
    );
  }

  @override
  Future<String> registerStudent(StudentRegistration data) async {
    data.validate();
    final raw = await _request(
      'POST',
      '/auth/register',
      registering: true,
      body: {
        'name': data.name.trim(),
        'email': data.normalizedEmail,
        'password': data.password,
        'role': 'MAHASISWA',
      },
    );
    if (raw is! Map<String, dynamic> || raw['user'] is! Map<String, dynamic>) {
      throw const StudentFailure(FailureKind.registrationUncertain);
    }
    final user = raw['user'] as Map<String, dynamic>;
    if (user['id'] is! String ||
        (user['id'] as String).isEmpty ||
        user['role'] != 'MAHASISWA' ||
        user['email'] != data.normalizedEmail) {
      throw const StudentFailure(FailureKind.registrationUncertain);
    }
    // Registration intentionally returns to login, like the website. Ignore token/cookie.
    return data.normalizedEmail;
  }

  @override
  Future<StudentProfile> fetchProfile(StudentSession session) async {
    final user = _object(await _request('GET', '/auth/me', session: session));
    if (_string(user, 'id') != session.accountId) {
      throw const StudentFailure(FailureKind.expired);
    }
    if (_string(user, 'role') != 'MAHASISWA') {
      throw const StudentFailure(FailureKind.forbidden);
    }
    // NIM and program are not fields of the current UserResponse contract.
    return StudentProfile(
      id: _string(user, 'id'),
      name: _string(user, 'name'),
      email: _string(user, 'email'),
    );
  }

  @override
  Future<List<StudentClass>> fetchClasses(StudentSession session) async {
    final credentials = _credentials(session);
    final pending = credentials.classesRequest ??= _fetchClasses(session);
    try {
      return await pending;
    } finally {
      if (identical(credentials.classesRequest, pending)) {
        credentials.classesRequest = null;
      }
    }
  }

  Future<List<StudentClass>> _fetchClasses(StudentSession session) async {
    final raw = _list(await _request('GET', '/classes', session: session));
    return raw.map((value) {
      final c = _object(value);
      final lecturer = c['dosen'];
      return StudentClass(
        id: _string(c, 'id'),
        name: _string(c, 'name'),
        subject: c['subject'] is String ? c['subject'] as String : '',
        description: c['description'] is String
            ? c['description'] as String
            : '',
        lecturer: lecturer is Map && lecturer['name'] is String
            ? lecturer['name'] as String
            : '',
        archived: c['isArchived'] == true,
      );
    }).toList();
  }

  @override
  Future<JoinedClass> joinClass(StudentSession session, String code) async {
    final clean = code.trim().toUpperCase();
    if (clean.isEmpty || clean.length > 20) {
      throw const StudentFailure(FailureKind.invalidClassCode);
    }
    final result = _object(
      await _request(
        'POST',
        '/classes/join',
        session: session,
        joining: true,
        body: {'enrollmentKey': clean},
      ),
    );
    if (result['success'] != true) {
      throw const StudentFailure(FailureKind.invalidResponse);
    }
    return JoinedClass(
      id: _string(result, 'classId'),
      name: _string(result, 'className'),
    );
  }

  @override
  Future<List<Announcement>> fetchClassAssignments(
    StudentSession session,
    StudentClass course,
  ) async {
    final assignments = _list(
      await _request(
        'GET',
        '/classes/${Uri.encodeComponent(course.id)}/assignments',
        session: session,
      ),
    );
    final items = <Announcement>[];
    final seen = <String>{};
    for (final raw in assignments) {
      final task = _object(raw);
      final status = _string(task, 'status');
      if (status != 'PUBLISHED' && status != 'CLOSED') continue;
      final id = _string(task, 'id');
      if (!seen.add(id)) continue;
      final due = _date(task['dueDate']);
      final instructions = task['instructions'] is String
          ? task['instructions'] as String
          : '';
      final closed = status == 'CLOSED';
      items.add(
        Announcement(
          id: 'task:$id',
          classId: course.id,
          assignmentId: id,
          title: _string(task, 'title'),
          date: due,
          category: closed ? 'Tugas ditutup' : 'Tugas',
          summary:
              '${course.name}\n${closed ? 'Pengumpulan ditutup' : 'Batas pengumpulan: $due'}',
          content:
              'Kelas: ${course.name}\nBatas pengumpulan: $due\n'
              'Status: ${closed ? 'Ditutup' : 'Dipublikasikan'}\n\n'
              '${instructions.trim().isEmpty ? 'Belum ada instruksi tambahan.' : instructions}\n\n'
              'Buka detail tugas untuk melihat ketentuan dan mengumpulkan jawaban.',
        ),
      );
    }
    return items;
  }

  @override
  Future<List<Announcement>> fetchAnnouncements(StudentSession session) async {
    final courses = await fetchClasses(session);
    final items = <Announcement>[];
    final activeCourses = courses.where((c) => !c.archived).toList();
    // Bound concurrent requests so a large enrollment does not flood the API.
    for (var start = 0; start < activeCourses.length; start += 3) {
      _credentials(session);
      final batch = await Future.wait(
        activeCourses
            .skip(start)
            .take(3)
            .map((course) => fetchClassAssignments(session, course)),
        eagerError: true,
      );
      items.addAll(batch.expand((tasks) => tasks));
    }
    return items;
  }

  String _assignmentPath(AssignmentRef ref) =>
      '/classes/${Uri.encodeComponent(ref.classId)}/assignments/${Uri.encodeComponent(ref.assignmentId)}';

  @override
  Future<StudentAssignment> fetchAssignment(
    StudentSession session,
    AssignmentRef ref,
  ) async {
    final raw = _object(
      await _request('GET', _assignmentPath(ref), session: session),
    );
    if (_string(raw, 'id') != ref.assignmentId ||
        _string(raw, 'classId') != ref.classId) {
      throw const StudentFailure(FailureKind.invalidResponse);
    }
    final status = _string(raw, 'status');
    if (status != 'PUBLISHED' && status != 'CLOSED') {
      throw const StudentFailure(FailureKind.accessDenied);
    }
    final course = _object(raw['class']);
    final allowed = _list(course['enrollments']).any(
      (e) =>
          e is Map &&
          e['userId'] == session.accountId &&
          e['role'] == 'STUDENT',
    );
    SubmittedAnswer? submission;
    for (final value in _list(raw['submissions'])) {
      final sub = _object(value);
      if (sub['userId'] != session.accountId) continue;
      final versions = _list(sub['versions']).map((v) {
        final version = _object(v);
        final number = version['versionNumber'];
        if (number is! int) {
          throw const StudentFailure(FailureKind.invalidResponse);
        }
        return AnswerVersion(
          id: _string(version, 'id'),
          number: number,
          type: _string(version, 'type'),
          submittedAt: _date(version['submittedAt']),
          fileName: version['fileName'] is String ? version['fileName'] : null,
          content: version['content'] is String ? version['content'] : '',
        );
      }).toList()..sort((a, b) => b.number.compareTo(a.number));
      ReleasedResult? result;
      for (final value in _list(sub['grades'])) {
        final grade = _object(value);
        if (grade['id'] == sub['releasedGradeId'] &&
            grade['status'] == 'RELEASED' &&
            grade['finalScore'] is num) {
          result = ReleasedResult(
            score: grade['finalScore'],
            feedback: grade['finalFeedback'] is String
                ? grade['finalFeedback']
                : '',
          );
        }
      }
      submission = SubmittedAnswer(
        id: _string(sub, 'id'),
        activeVersionId: sub['activeVersionId'] is String
            ? sub['activeVersionId']
            : '',
        versions: versions,
        result: result,
      );
      break;
    }
    final rubric = <String>[];
    if (raw['rubric'] is Map && raw['rubric']['criteria'] is List) {
      for (final item in raw['rubric']['criteria']) {
        if (item is Map && item['label'] is String) {
          rubric.add(
            '${item['label']} — ${item['maxScore']} poin\n${item['description'] is String ? item['description'] : ''}',
          );
        }
      }
    }
    final due = DateTime.tryParse(_string(raw, 'dueDate'));
    if (due == null || raw['maxScore'] is! num) {
      throw const StudentFailure(FailureKind.invalidResponse);
    }
    return StudentAssignment(
      ref: ref,
      title: _string(raw, 'title'),
      className: _string(course, 'name'),
      instructions: raw['instructions'] is String ? raw['instructions'] : '',
      type: _string(raw, 'submissionType'),
      status: status,
      dueAt: due,
      dueLabel: _date(raw['dueDate']),
      maxScore: raw['maxScore'],
      allowLate: raw['allowLateSubmission'] == true,
      canSubmit: allowed,
      submission: submission,
      rubric: rubric,
    );
  }

  @override
  Future<SubmissionReceipt> submitAnswer(
    StudentSession session,
    StudentAssignment assignment, {
    String? text,
    AnswerFile? file,
  }) async {
    assignment.validateAnswer(text, file);
    final raw = await _request(
      'POST',
      '${_assignmentPath(assignment.ref)}/submissions',
      session: session,
      submitting: true,
      file: file,
      body: file == null ? {'content': text!.trim()} : null,
    );
    if (raw is! Map<String, dynamic>) {
      throw const StudentFailure(FailureKind.submissionUncertain);
    }
    if (raw['success'] != true ||
        raw['userId'] != session.accountId ||
        raw['versionNumber'] is! int ||
        raw['submissionId'] is! String ||
        raw['versionId'] is! String) {
      throw const StudentFailure(FailureKind.submissionUncertain);
    }
    return SubmissionReceipt(
      submissionId: raw['submissionId'],
      versionId: raw['versionId'],
      number: raw['versionNumber'],
    );
  }

  String _storageKey(StudentSession session) =>
      'dexa_student_reads_v1_${base64Url.encode(utf8.encode('${baseUri.toString()}|${session.accountId}'))}';

  Set<String> _readIds(SharedPreferences preferences, String key) {
    // A malformed legacy value must not crash the whole feed.
    final raw = preferences.get(key);
    return raw is List<String> ? raw.toSet() : <String>{};
  }

  @override
  Future<List<NotificationItem>> fetchNotifications(
    StudentSession session,
  ) async {
    final grades = _list(await _request('GET', '/grades', session: session));
    final preferences = await SharedPreferences.getInstance();
    final readIds = _readIds(preferences, _storageKey(session));
    final result = <NotificationItem>[];
    final seen = <String>{};
    for (final rawGrade in grades) {
      final grade = _object(rawGrade);
      if (grade['status'] != 'RELEASED') continue;
      final id = _string(grade, 'id');
      final submission = _object(grade['submission']);
      if (submission['releasedGradeId'] != id || !seen.add(id)) continue;
      final assignment = _object(submission['assignment']);
      final course = _object(assignment['class']);
      final title = _string(assignment, 'title');
      final score = grade['finalScore'];
      final maxScore = assignment['maxScore'];
      if (score is! num || maxScore is! num) {
        throw const StudentFailure(FailureKind.invalidResponse);
      }
      final feedback = grade['finalFeedback'] is String
          ? grade['finalFeedback'] as String
          : '';
      final notificationId = 'grade:$id';
      result.add(
        NotificationItem(
          id: notificationId,
          title: 'Nilai dirilis: $title',
          date: _date(grade['createdAt']),
          category: 'Nilai dirilis',
          summary:
              '${_string(course, 'name')} · Nilai ${_number(score)}/${_number(maxScore)}',
          content:
              'Tugas: $title\nKelas: ${_string(course, 'name')}\n'
              'Nilai: ${_number(score)}/${_number(maxScore)}\n\n'
              '${feedback.trim().isEmpty ? 'Belum ada catatan tambahan dari dosen.' : feedback}',
          isRead: readIds.contains(notificationId),
        ),
      );
    }
    return result;
  }

  @override
  Future<void> markRead(StudentSession session, String notificationId) {
    _credentials(session);
    final key = _storageKey(session);
    final operation = _writeQueue.catchError((Object _) {}).then((_) async {
      _credentials(session);
      final preferences = await SharedPreferences.getInstance();
      final ids = _readIds(preferences, key)..add(notificationId);
      if (!await preferences.setStringList(key, ids.toList())) {
        throw StateError('Read receipt could not be persisted');
      }
    });
    // Consume failures on the queue as well as returning them to the caller.
    _writeQueue = operation.catchError((Object _) {});
    return operation;
  }

  @override
  Future<void> signOut(StudentSession session) async {
    final credentials = session.handle;
    if (credentials is! _Credentials || !identical(credentials.owner, this)) {
      return;
    }
    // FastAPI /auth/logout only clears a browser cookie; no bearer revocation API.
    // Drop our in-memory token immediately; no credentials persist across restarts.
    credentials.token = null;
    credentials.classesRequest = null;
  }
}

class _Credentials {
  _Credentials(this.owner, this.token);
  final FastApiStudentRepository owner;
  String? token;
  Future<List<StudentClass>>? classesRequest;
  @override
  String toString() => 'Session credentials (redacted)';
}

Map<String, dynamic> _object(Object? value) {
  if (value is! Map<String, dynamic>) {
    throw const StudentFailure(FailureKind.invalidResponse);
  }
  return value;
}

List<dynamic> _list(Object? value) {
  if (value is! List) throw const StudentFailure(FailureKind.invalidResponse);
  return value;
}

String _string(Map<String, dynamic> object, String key) {
  final value = object[key];
  if (value is! String || value.trim().isEmpty) {
    throw const StudentFailure(FailureKind.invalidResponse);
  }
  return value;
}

String _number(num value) => value == value.truncateToDouble()
    ? value.toInt().toString()
    : value.toString();
String _date(Object? value) {
  if (value == null) return 'Belum ditentukan';
  if (value is! String) throw const StudentFailure(FailureKind.invalidResponse);
  final parsed = DateTime.tryParse(value)?.toLocal();
  if (parsed == null) throw const StudentFailure(FailureKind.invalidResponse);
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];
  return '${parsed.day} ${months[parsed.month - 1]} ${parsed.year} · '
      '${parsed.hour.toString().padLeft(2, '0')}.${parsed.minute.toString().padLeft(2, '0')}';
}
