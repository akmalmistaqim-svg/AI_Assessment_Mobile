import 'student_repository.dart';

class StudentRegistration {
  const StudentRegistration({
    required this.name,
    required this.email,
    required this.password,
  });
  final String name, email, password;
  String get normalizedEmail => email.trim().toLowerCase();
  static String? nameError(String? value) =>
      value == null || value.trim().length < 2 || value.trim().length > 100
      ? 'Nama lengkap harus 2–100 karakter.'
      : null;
  static String? emailError(String? value) =>
      value == null ||
          value.trim().length > 255 ||
          !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value.trim())
      ? 'Masukkan alamat email yang valid.'
      : null;
  static String? passwordError(String? value) =>
      value == null || value.length < 6
      ? 'Kata sandi minimal 6 karakter.'
      : null;
  void validate() {
    if (nameError(name) != null ||
        emailError(email) != null ||
        passwordError(password) != null) {
      throw const StudentFailure(FailureKind.registrationInvalid);
    }
  }
}

abstract interface class StudentRegistrationRepository {
  Future<String> registerStudent(StudentRegistration data);
}
