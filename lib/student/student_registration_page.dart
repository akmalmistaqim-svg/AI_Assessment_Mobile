import 'package:flutter/material.dart';

import 'student_auth_header.dart';
import 'student_registration.dart';
import 'student_repository.dart';

class StudentRegistrationPage extends StatefulWidget {
  const StudentRegistrationPage({super.key, required this.repository});
  final StudentRegistrationRepository repository;
  @override
  State<StudentRegistrationPage> createState() =>
      _StudentRegistrationPageState();
}

class _StudentRegistrationPageState extends State<StudentRegistrationPage> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController(),
      email = TextEditingController(),
      password = TextEditingController(),
      confirmation = TextEditingController();
  bool busy = false, hidden = true, confirmHidden = true;
  String? error, createdEmail;
  @override
  void dispose() {
    name.dispose();
    email.dispose();
    password.dispose();
    confirmation.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (busy || createdEmail != null || !form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final result = await widget.repository.registerStudent(
        StudentRegistration(
          name: name.text,
          email: email.text,
          password: password.text,
        ),
      );
      if (!mounted) return;
      password.clear();
      confirmation.clear();
      setState(() => createdEmail = result);
    } catch (e) {
      if (mounted) {
        setState(
          () => error = e is StudentFailure
              ? e.message
              : const StudentFailure(FailureKind.registrationUncertain).message,
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Widget gap() => const SizedBox(height: 16);
  @override
  Widget build(BuildContext context) => PopScope<Object?>(
    canPop: !busy,
    child: Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              key: const Key('registration-scroll'),
              padding: const EdgeInsets.all(24),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: createdEmail != null
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const DexaBrand(),
                        const SizedBox(height: 32),
                        Icon(
                          Icons.check_circle_outline,
                          size: 48,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        gap(),
                        Text(
                          'Akun berhasil dibuat',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        gap(),
                        Text(
                          'Anda bisa masuk di aplikasi atau web Dexa dengan $createdEmail.',
                        ),
                        gap(),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            key: const Key('registration-back-login'),
                            onPressed: () =>
                                Navigator.pop(context, createdEmail),
                            child: const Text('Lanjut ke halaman masuk'),
                          ),
                        ),
                      ],
                    )
                  : Form(
                      key: form,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          StudentAuthHeader(
                            registering: true,
                            onSwitch: busy
                                ? null
                                : () => Navigator.pop(context),
                          ),
                          const SizedBox(height: 32),
                          Text(
                            'Buat akun mahasiswa',
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.8,
                                ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Sudah mendaftar di web Dexa? Gunakan email yang sama di menu Masuk.',
                          ),
                          const SizedBox(height: 24),
                          if (error != null) ...[
                            Semantics(
                              liveRegion: true,
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .errorContainer,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  error!,
                                  key: const Key('registration-error'),
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onErrorContainer,
                                  ),
                                ),
                              ),
                            ),
                            gap(),
                          ],
                          TextFormField(
                            key: const Key('registration-name'),
                            controller: name,
                            enabled: !busy,
                            autofillHints: const [AutofillHints.name],
                            textCapitalization: TextCapitalization.words,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Nama lengkap',
                              hintText: 'Nama sesuai daftar kelas',
                            ),
                            validator: StudentRegistration.nameError,
                          ),
                          gap(),
                          TextFormField(
                            key: const Key('registration-email'),
                            controller: email,
                            enabled: !busy,
                            autocorrect: false,
                            keyboardType: TextInputType.emailAddress,
                            autofillHints: const [AutofillHints.email],
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              hintText: 'nama@kampus.ac.id',
                            ),
                            validator: StudentRegistration.emailError,
                          ),
                          gap(),
                          TextFormField(
                            key: const Key('registration-password'),
                            controller: password,
                            enabled: !busy,
                            obscureText: hidden,
                            autocorrect: false,
                            enableSuggestions: false,
                            autofillHints: const [AutofillHints.newPassword],
                            textInputAction: TextInputAction.next,
                            decoration: InputDecoration(
                              labelText: 'Kata sandi',
                              helperText: 'Minimal 6 karakter',
                              suffixIcon: IconButton(
                                tooltip: hidden
                                    ? 'Tampilkan kata sandi'
                                    : 'Sembunyikan kata sandi',
                                onPressed: busy
                                    ? null
                                    : () => setState(() => hidden = !hidden),
                                icon: Icon(
                                  hidden
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                              ),
                            ),
                            validator: StudentRegistration.passwordError,
                          ),
                          gap(),
                          TextFormField(
                            key: const Key('registration-confirm'),
                            controller: confirmation,
                            enabled: !busy,
                            obscureText: confirmHidden,
                            autocorrect: false,
                            enableSuggestions: false,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => submit(),
                            decoration: InputDecoration(
                              labelText: 'Konfirmasi kata sandi',
                              suffixIcon: IconButton(
                                tooltip: confirmHidden
                                    ? 'Tampilkan konfirmasi kata sandi'
                                    : 'Sembunyikan konfirmasi kata sandi',
                                onPressed: busy
                                    ? null
                                    : () => setState(
                                        () => confirmHidden = !confirmHidden,
                                      ),
                                icon: Icon(
                                  confirmHidden
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                              ),
                            ),
                            validator: (v) => v == null || v.isEmpty
                                ? 'Ulangi kata sandi.'
                                : v != password.text
                                ? 'Konfirmasi kata sandi tidak cocok.'
                                : null,
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              key: const Key('student-register-submit'),
                              onPressed: busy ? null : submit,
                              child: busy
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text('Buat akun'),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ),
      ),
    ),
  );
}
