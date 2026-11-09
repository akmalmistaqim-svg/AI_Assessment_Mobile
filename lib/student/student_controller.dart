import 'student_assignment.dart';

import 'package:flutter/foundation.dart';

import '../models/announcement.dart';
import '../models/notification_item.dart';
import 'student_repository.dart';

class StudentController extends ChangeNotifier {
  StudentController(this.repository);
  final StudentRepository repository;
  StudentSession? _session;
  StudentProfile? profile;
  List<Announcement> _announcements = [];
  List<StudentClass> _classes = [];
  List<StudentClass> get classes => List.unmodifiable(_classes);
  bool joining = false;
  String? joinError;
  List<NotificationItem> _notifications = [];
  List<Announcement> get announcements => List.unmodifiable(_announcements);
  List<NotificationItem> get notifications => List.unmodifiable(_notifications);
  final Set<String> _pendingRead = {};
  int _generation = 0;
  bool _disposed = false;
  bool signingIn = false;
  bool loading = false;
  String? loginError;
  String? dataError;
  String? readError;
  int tab = 0;
  String query = '';
  String? category;
  bool get signedIn => _session != null;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;
  bool isMarkingRead(String id) => _pendingRead.contains(id);
  List<String> get categories =>
      _announcements.map((a) => a.category).toSet().toList();
  List<Announcement> get filteredAnnouncements {
    final q = query.trim().toLowerCase();
    return _announcements
        .where(
          (a) =>
              (category == null || category == a.category) &&
              '${a.title} ${a.summary} ${a.content}'.toLowerCase().contains(q),
        )
        .toList();
  }

  void _emit() {
    if (!_disposed) notifyListeners();
  }

  bool _current(int generation) => !_disposed && generation == _generation;
  String _message(Object error) => error is StudentFailure
      ? error.message
      : const StudentFailure(FailureKind.network).message;

  Future<void> signIn(String identifier, String password) async {
    if (signingIn || signedIn || _disposed) return;
    final generation = ++_generation;
    signingIn = true;
    loginError = null;
    _emit();
    try {
      final session = await repository.signIn(identifier.trim(), password);
      if (!_current(generation)) {
        await _discard(session);
        return;
      }
      if (!session.isStudent) {
        await _discard(session);
        throw const StudentFailure(FailureKind.forbidden);
      }
      _session = session;
      if (session.initialProfile != null) {
        profile = session.initialProfile;
      }
      signingIn = false;
      _emit();
      await refresh();
    } catch (error) {
      if (_current(generation)) {
        signingIn = false;
        loginError = _message(error);
        _emit();
      }
    }
  }

  Future<void> _discard(StudentSession session) async {
    try {
      await repository.signOut(session);
    } catch (_) {
      // Local credentials are dropped even when remote revocation is unavailable.
    }
  }

  Future<void> refresh() => _refresh();

  Future<void> _refresh({bool afterJoin = false}) async {
    final session = _session;
    if (session == null || loading || (joining && !afterJoin) || _disposed) {
      return;
    }
    final generation = _generation;
    loading = true;
    dataError = null;
    _emit();
    void handleError(Object error) {
      if (!_current(generation)) return;
      if (error is StudentFailure &&
          (error.kind == FailureKind.expired ||
              error.kind == FailureKind.forbidden)) {
        signOut(message: error.message);
      } else {
        dataError = _message(error);
        _emit();
      }
    }

    Future<bool> loadProfile() async {
      try {
        final fetchedProfile = await repository.fetchProfile(session);
        if (!_current(generation)) return false;
        if (fetchedProfile.id != session.accountId) {
          throw const StudentFailure(FailureKind.expired);
        }
        profile = fetchedProfile;
        _emit();
        return true;
      } catch (error) {
        handleError(error);
        return false;
      }
    }

    final profileReady = loadProfile();
    Future<void> loadPart<T>(
      Future<T> Function() fetch,
      void Function(T) apply,
    ) async {
      try {
        final result = await fetch();
        // Show account data only after validating the current profile.
        if (!await profileReady || !_current(generation)) return;
        apply(result);
        _emit();
      } catch (error) {
        handleError(error);
      }
    }

    try {
      await Future.wait<void>([
        profileReady.then<void>((_) {}),
        loadPart(() => repository.fetchAnnouncements(session), (items) {
          _announcements = List.of(items);
          if (!categories.contains(category)) category = null;
        }),
        loadPart(() => repository.fetchNotifications(session), (items) {
          final readIds = _notifications
              .where((n) => n.isRead)
              .map((n) => n.id)
              .toSet();
          _notifications = items
              .map(
                (n) => n.copyWith(isRead: n.isRead || readIds.contains(n.id)),
              )
              .toList();
        }),
        loadPart(() => repository.fetchClasses(session), (items) {
          _classes = List.of(items);
        }),
      ]);
    } finally {
      if (_current(generation)) {
        loading = false;
        _emit();
      }
    }
  }

  Future<JoinedClass?> joinClass(String code) async {
    final session = _session;
    if (session == null || joining || loading || _disposed) return null;
    final generation = _generation;
    joining = true;
    joinError = null;
    _emit();
    try {
      final result = await repository.joinClass(
        session,
        code.trim().toUpperCase(),
      );
      if (!_current(generation)) return null;
      await _refresh(afterJoin: true);
      return _current(generation) ? result : null;
    } catch (error) {
      if (!_current(generation)) return null;
      if (error is StudentFailure && error.kind == FailureKind.expired) {
        signOut(message: error.message);
      } else {
        joinError = _message(error);
      }
      return null;
    } finally {
      if (_current(generation)) {
        joining = false;
        _emit();
      }
    }
  }

  Future<List<Announcement>> classAssignments(StudentClass course) async {
    final session = _session;
    final generation = _generation;
    if (session == null) throw const StudentFailure(FailureKind.expired);
    try {
      final result = await repository.fetchClassAssignments(session, course);
      if (!_current(generation)) {
        throw const StudentFailure(FailureKind.expired);
      }
      return result;
    } on StudentFailure catch (error) {
      if (_current(generation) && error.kind == FailureKind.expired) {
        signOut(message: error.message);
      }
      rethrow;
    }
  }

  final Set<String> _sendingAnswers = {};
  Future<T> _assignmentCall<T>(
    Future<T> Function(StudentSubmissionRepository, StudentSession) action,
  ) async {
    final session = _session;
    final generation = _generation;
    final adapter = repository;
    if (session == null) throw const StudentFailure(FailureKind.expired);
    if (adapter is! StudentSubmissionRepository) {
      throw const StudentFailure(FailureKind.unavailable);
    }
    try {
      final result = await action(
        adapter as StudentSubmissionRepository,
        session,
      );
      if (!_current(generation)) {
        throw const StudentFailure(FailureKind.expired);
      }
      return result;
    } on StudentFailure catch (error) {
      if (_current(generation) && error.kind == FailureKind.expired) {
        signOut(message: error.message);
      }
      rethrow;
    }
  }

  Future<StudentAssignment> assignment(AssignmentRef ref) =>
      _assignmentCall((repo, session) => repo.fetchAssignment(session, ref));

  Future<SubmissionReceipt> submitAnswer(
    StudentAssignment assignment, {
    String? text,
    AnswerFile? file,
  }) async {
    final key = '$_generation/${assignment.ref.key}';
    if (!_sendingAnswers.add(key)) {
      throw const StudentFailure(FailureKind.submissionBusy);
    }
    try {
      return await _assignmentCall(
        (repo, session) =>
            repo.submitAnswer(session, assignment, text: text, file: file),
      );
    } finally {
      _sendingAnswers.remove(key);
    }
  }

  Future<void> markRead(String id) async {
    final session = _session;
    final matches = _notifications.where((n) => n.id == id);
    if (session == null ||
        matches.isEmpty ||
        matches.first.isRead ||
        _pendingRead.contains(id) ||
        _disposed) {
      return;
    }
    final generation = _generation;
    _pendingRead.add(id);
    readError = null;
    _emit();
    try {
      await repository.markRead(session, id);
      if (!_current(generation)) return;
      _notifications = _notifications
          .map((n) => n.id == id ? n.copyWith(isRead: true) : n)
          .toList();
    } catch (error) {
      if (!_current(generation)) return;
      if (error is StudentFailure &&
          (error.kind == FailureKind.expired ||
              error.kind == FailureKind.forbidden)) {
        signOut(message: error.message);
        return;
      }
      readError = 'Status baca belum tersimpan. Silakan coba lagi.';
    } finally {
      if (_current(generation)) {
        _pendingRead.remove(id);
        _emit();
      }
    }
  }

  void selectTab(int index) {
    if (index < 0 || index > 4 || tab == index) return;
    tab = index;
    _emit();
  }

  void search(String value) {
    query = value;
    _emit();
  }

  void filter(String? value) {
    category = value;
    _emit();
  }

  void signOut({String? message}) {
    final oldSession = _session;
    ++_generation;
    _session = null;
    profile = null;
    _announcements = [];
    _classes = [];
    joining = false;
    joinError = null;
    _notifications = [];
    _pendingRead.clear();
    loading = false;
    signingIn = false;
    dataError = null;
    readError = null;
    loginError = message;
    query = '';
    category = null;
    tab = 0;
    _emit();
    if (oldSession != null) {
      _discard(oldSession);
    }
  }

  @override
  void dispose() {
    final session = _session;
    _session = null;
    _disposed = true;
    ++_generation;
    if (session != null) {
      _discard(session);
    }
    super.dispose();
  }
}
