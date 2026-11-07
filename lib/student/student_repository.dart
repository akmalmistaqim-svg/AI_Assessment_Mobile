import '../models/announcement.dart';
import '../models/notification_item.dart';

/// Transport-independent models. Mapping backend fields belongs in an adapter.
class StudentProfile {
  const StudentProfile({
    required this.id,
    required this.name,
    this.email,
    this.studentNumber,
    this.program,
  });
  final String id;
  final String name;
  final String? email;
  final String? studentNumber;
  final String? program;
}

class StudentClass {
  const StudentClass({
    required this.id,
    required this.name,
    this.subject = '',
    this.description = '',
    this.lecturer = '',
    this.archived = false,
  });
  final String id, name, subject, description, lecturer;
  final bool archived;
}

class JoinedClass {
  const JoinedClass({required this.id, required this.name});
  final String id, name;
}

class StudentSession {
  const StudentSession({
    required this.accountId,
    required this.isStudent,
    required this.handle,
  });
  final String accountId;
  final bool isStudent;
  // Adapter-owned credentials. Never persist with SharedPreferences or log them.
  final Object handle;
}

enum FailureKind {
  credentials,
  expired,
  forbidden,
  unavailable,
  network,
  rateLimited,
  invalidResponse,
  accessDenied,
  invalidClassCode,
  alreadyEnrolled,
  archivedClass,
  joinRejected,
  emptyAnswer,
  answerTooLarge,
  answerFormat,
  submissionClosed,
  submissionRejected,
  submissionUncertain,
  submissionBusy,
  registrationDuplicate,
  registrationInvalid,
  registrationUncertain,
}

class StudentFailure implements Exception {
  const StudentFailure(this.kind);
  final FailureKind kind;
  String get message => switch (kind) {
    FailureKind.registrationDuplicate =>
      'Email sudah terdaftar. Silakan masuk dengan akun tersebut.',
    FailureKind.registrationInvalid =>
      'Data pendaftaran belum sesuai. Periksa nama, email, dan kata sandi.',
    FailureKind.registrationUncertain => 'Status pendaftaran belum dapat dipastikan. Coba masuk dengan email ini sebelum mendaftar ulang.',
    FailureKind.credentials => 'Akun atau kata sandi tidak sesuai. Coba lagi.',
    FailureKind.expired => 'Sesi berakhir. Silakan masuk kembali.',
    FailureKind.forbidden => 'Aplikasi ini khusus akun mahasiswa.',
    FailureKind.unavailable =>
      'Layanan masuk belum tersedia. Silakan coba kembali nanti.',
    FailureKind.rateLimited =>
      'Terlalu banyak percobaan. Tunggu satu menit lalu coba lagi.',
    FailureKind.invalidResponse =>
      'Data layanan belum dapat dibaca. Silakan coba lagi nanti.',
    FailureKind.accessDenied => 'Akunmu tidak memiliki akses ke data ini.',
    FailureKind.invalidClassCode =>
      'Kode kelas tidak ditemukan. Periksa kode dari dosen.',
    FailureKind.alreadyEnrolled =>
      'Kamu sudah bergabung ke kelas ini. Muat ulang daftar kelas.',
    FailureKind.archivedClass =>
      'Kelas sudah diarsipkan dan tidak menerima anggota baru.',
    FailureKind.joinRejected =>
      'Belum dapat bergabung. Periksa kode kelas dan coba lagi.',
    FailureKind.emptyAnswer => 'Pilih berkas atau isi jawaban terlebih dahulu.',
    FailureKind.answerTooLarge => 'Ukuran jawaban maksimal 10 MB.',
    FailureKind.answerFormat =>
      'Format jawaban tidak sesuai. Gunakan jenis berkas yang diminta dosen.',
    FailureKind.submissionClosed =>
      'Tugas tidak menerima jawaban. Periksa tenggat atau status tugas.',
    FailureKind.submissionRejected =>
      'Jawaban ditolak. Periksa format, isi dokumen, dan ketentuan tugas.',
    FailureKind.submissionUncertain => 'Status pengiriman belum dapat dipastikan. Periksa status pengumpulan sebelum mengirim ulang.',
    FailureKind.submissionBusy =>
      'Jawaban masih dikirim. Tunggu hingga proses selesai.',
    FailureKind.network =>
      'Tidak dapat terhubung ke layanan. Periksa koneksi internet atau sambungan USB, lalu coba lagi.',
  };
}

abstract class StudentRepository {
  bool get isConfigured;
  Future<StudentSession> signIn(String identifier, String password);
  Future<StudentProfile> fetchProfile(StudentSession session);
  Future<List<StudentClass>> fetchClasses(StudentSession session);
  Future<JoinedClass> joinClass(StudentSession session, String code);
  Future<List<Announcement>> fetchClassAssignments(
    StudentSession session,
    StudentClass course,
  );
  Future<List<Announcement>> fetchAnnouncements(StudentSession session);
  Future<List<NotificationItem>> fetchNotifications(StudentSession session);
  Future<void> markRead(StudentSession session, String notificationId);
  Future<void> signOut(StudentSession session);
}

/// Deliberately fails closed until the real API contract is supplied.
/// No guessed endpoints, test accounts, or successful fake login in production.
class UnconfiguredStudentRepository implements StudentRepository {
  const UnconfiguredStudentRepository();
  @override
  bool get isConfigured => false;
  Never _unavailable() => throw const StudentFailure(FailureKind.unavailable);
  @override
  Future<StudentSession> signIn(String identifier, String password) async =>
      _unavailable();
  @override
  Future<StudentProfile> fetchProfile(StudentSession session) async =>
      _unavailable();
  @override
  Future<List<StudentClass>> fetchClasses(StudentSession session) async =>
      _unavailable();
  @override
  Future<JoinedClass> joinClass(StudentSession session, String code) async =>
      _unavailable();
  @override
  Future<List<Announcement>> fetchClassAssignments(
    StudentSession session,
    StudentClass course,
  ) async => _unavailable();
  @override
  Future<List<Announcement>> fetchAnnouncements(StudentSession session) async =>
      _unavailable();
  @override
  Future<List<NotificationItem>> fetchNotifications(
    StudentSession session,
  ) async => _unavailable();
  @override
  Future<void> markRead(StudentSession session, String notificationId) async =>
      _unavailable();
  @override
  Future<void> signOut(StudentSession session) async {}
}
