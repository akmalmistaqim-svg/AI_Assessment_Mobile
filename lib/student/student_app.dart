import 'dart:async';

import 'package:flutter/material.dart';

import '../models/announcement.dart';
import '../models/notification_item.dart';
import '../theme/app_theme.dart';
import 'student_controller.dart';
import 'student_class_pages.dart';
import 'student_repository.dart';
import 'student_assignment.dart';
import 'student_assignment_page.dart';
import 'answer_file_picker.dart';
import 'student_registration.dart';
import 'student_registration_page.dart';
import 'student_auth_header.dart';

const _ink = Color(0xFF0F172A);
const _blue = Color(0xFF0369A1);
const _pale = Color(0xFFBAE6FD);
const _canvas = Color(0xFFF0F9FF);
const _navy = Color(0xFF0C4A6E);

class StudentApp extends StatefulWidget {
  const StudentApp({
    super.key,
    required this.repository,
    this.filePicker = pickAnswerFile,
  });
  final StudentRepository repository;
  final AnswerFilePicker filePicker;
  @override
  State<StudentApp> createState() => _StudentAppState();
}

class _StudentAppState extends State<StudentApp> {
  late final StudentController state;
  late final ThemeData studentTheme = _createStudentTheme();
  final navigatorKey = GlobalKey<NavigatorState>();
  Announcement? announcement;
  StudentClass? selectedClass;
  String? notificationId;
  @override
  void initState() {
    super.initState();
    state = StudentController(widget.repository)..addListener(_changed);
  }

  void _changed() {
    if (!state.signedIn) {
      announcement = null;
      notificationId = null;
      selectedClass = null;
    }
    setState(() {});
  }

  @override
  void dispose() {
    state.removeListener(_changed);
    state.dispose();
    super.dispose();
  }

  void _openAnnouncement(Announcement item) {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      announcement = item;
      notificationId = null;
    });
  }

  void _openNotification(NotificationItem item) {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      notificationId = item.id;
      announcement = null;
    });
    state.markRead(item.id);
  }

  ThemeData _createStudentTheme() {
    return AppTheme.lightTheme.copyWith(
      scaffoldBackgroundColor: _canvas,
      colorScheme: AppTheme.lightTheme.colorScheme.copyWith(
        primary: _blue,
        onPrimary: Colors.white,
        primaryContainer: _pale,
        onPrimaryContainer: _navy,
        secondary: _blue,
        surfaceTint: Colors.transparent,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: _pale,
        foregroundColor: _ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 17,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _blue, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: _blue,
          foregroundColor: Colors.white,
          minimumSize: const Size(48, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _ink,
          minimumSize: const Size(48, 52),
          side: const BorderSide(color: Color(0xFFCBD5E1)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? _ink
                : const Color(0xFF526577),
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
            color: states.contains(WidgetState.selected)
                ? _ink
                : const Color(0xFF526577),
          ),
        ),
        backgroundColor: Colors.white,
        indicatorColor: _pale,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    NotificationItem? notification;
    for (final item in state.notifications) {
      if (item.id == notificationId) notification = item;
    }
    return MaterialApp(
      title: 'Dexa Assessment',
      debugShowCheckedModeBanner: false,
      theme: studentTheme,
      home: NavigatorPopHandler<Object?>(
        onPopWithResult: (_) => navigatorKey.currentState?.maybePop(),
        child: Navigator(
          key: navigatorKey,
          pages: [
            if (!state.signedIn)
              MaterialPage(
                key: const ValueKey('login'),
                child: _Login(state: state),
              )
            else ...[
              MaterialPage(
                key: const ValueKey('workspace'),
                child: _Workspace(
                  state: state,
                  onAnnouncement: _openAnnouncement,
                  onNotification: _openNotification,
                  onClass: (course) => setState(() {
                    selectedClass = course;
                    announcement = null;
                    notificationId = null;
                  }),
                ),
              ),
              if (selectedClass case final course?)
                MaterialPage(
                  key: ValueKey('class-${course.id}'),
                  child: StudentClassDetailPage(
                    course: course,
                    state: state,
                    onTask: _openAnnouncement,
                  ),
                ),
              if (announcement case final item?)
                MaterialPage(
                  key: ValueKey('information-${item.id}'),
                  child: item.classId != null && item.assignmentId != null
                      ? StudentAssignmentPage(
                          state: state,
                          ref: AssignmentRef(item.classId!, item.assignmentId!),
                          filePicker: widget.filePicker,
                        )
                      : _Detail(
                          title: item.title,
                          category: item.category,
                          date: item.date,
                          content: item.content,
                          appBarTitle: 'Informasi',
                        ),
                ),
              if (notification case final item?)
                MaterialPage(
                  key: ValueKey('notification-${item.id}'),
                  child: _Detail(
                    title: item.title,
                    category: item.category,
                    date: item.date,
                    content: item.content,
                    appBarTitle: 'Pemberitahuan',
                    status: state.isMarkingRead(item.id)
                        ? 'Menyimpan status baca…'
                        : item.isRead
                        ? 'Sudah dibaca'
                        : 'Belum dibaca',
                    error: state.readError,
                    onRetry: () => state.markRead(item.id),
                  ),
                ),
            ],
          ],
          onDidRemovePage: (page) {
            // Ignore automatic removal on logout or removal of an older route.
            if (!mounted) return;
            if (selectedClass != null &&
                page.key == ValueKey('class-${selectedClass!.id}')) {
              setState(() => selectedClass = null);
            }
            if (page.key == ValueKey('information-${announcement?.id}') ||
                page.key == ValueKey('notification-$notificationId')) {
              setState(() {
                announcement = null;
                notificationId = null;
              });
            }
          },
        ),
      ),
    );
  }
}

class _Login extends StatefulWidget {
  const _Login({required this.state});
  final StudentController state;
  @override
  State<_Login> createState() => _LoginState();
}

class _LoginState extends State<_Login> {
  final form = GlobalKey<FormState>();
  final identifier = TextEditingController();
  final password = TextEditingController();
  bool hidden = true;
  String? registrationMessage;
  Timer? _slowTimer;
  bool _showSlowNotice = false;

  Future<void> openRegistration() async {
    final repo = widget.state.repository;
    if (widget.state.signingIn ||
        !repo.isConfigured ||
        repo is! StudentRegistrationRepository) {
      return;
    }
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => StudentRegistrationPage(
          repository: repo as StudentRegistrationRepository,
        ),
      ),
    );
    if (!mounted || result == null) return;
    setState(() {
      identifier.text = result;
      password.clear();
      widget.state.loginError = null;
      registrationMessage = "Akun berhasil dibuat. Silakan masuk.";
    });
  }

  @override
  void dispose() {
    _slowTimer?.cancel();
    identifier.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (widget.state.signingIn ||
        !widget.state.repository.isConfigured ||
        !form.currentState!.validate()) {
      return;
    }
    FocusScope.of(context).unfocus();
    _slowTimer?.cancel();
    setState(() {
      registrationMessage = null;
      _showSlowNotice = false;
    });
    _slowTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && widget.state.signingIn) {
        setState(() => _showSlowNotice = true);
      }
    });
    final secret = password.text;
    try {
      await widget.state.signIn(identifier.text, secret);
    } finally {
      _slowTimer?.cancel();
      if (mounted && _showSlowNotice) {
        setState(() => _showSlowNotice = false);
      }
    }
    if (!mounted) return;
    if (widget.state.loginError ==
        const StudentFailure(FailureKind.credentials).message) {
      password.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
              child: Form(
                key: form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StudentAuthHeader(
                      registering: false,
                      onSwitch:
                          state.signingIn ||
                              !state.repository.isConfigured ||
                              state.repository is! StudentRegistrationRepository
                          ? null
                          : openRegistration,
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      'Masuk ke akun Anda',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.8,
                        color: _ink,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const SizedBox(height: 12),
                    if (!state.repository.isConfigured) ...[
                      const _Notice(
                        message: 'Layanan masuk belum tersedia. Akun belum dapat dihubungkan.',
                      ),
                      const SizedBox(height: 20),
                    ],
                    if (registrationMessage != null) ...[
                      Semantics(
                        liveRegion: true,
                        child: Text(
                          registrationMessage!,
                          key: const Key('registration-login-message'),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                    if (state.loginError case final message?) ...[
                      _Notice(message: message),
                      const SizedBox(height: 20),
                    ],
                    TextFormField(
                      controller: identifier,
                      key: const Key('student-account'),
                      enabled: !state.signingIn,
                      autocorrect: false,
                      textInputAction: TextInputAction.next,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.username],
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.alternate_email),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Masukkan email.';
                        }
                        if (v.trim().length > 255 ||
                            !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                                .hasMatch(v.trim())) {
                          return 'Masukkan alamat email yang valid.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: password,
                      key: const Key('student-password'),
                      enabled: !state.signingIn,
                      obscureText: hidden,
                      autocorrect: false,
                      enableSuggestions: false,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.password],
                      onFieldSubmitted: (_) => _submit(),
                      decoration: InputDecoration(
                        labelText: 'Kata sandi',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          tooltip: hidden
                              ? 'Tampilkan kata sandi'
                              : 'Sembunyikan kata sandi',
                          onPressed: () => setState(() => hidden = !hidden),
                          icon: Icon(
                            hidden
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                      validator: (v) => v == null || v.isEmpty
                          ? 'Masukkan kata sandi.'
                          : v.length < 6
                          ? 'Kata sandi minimal 6 karakter.'
                          : null,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        key: const Key('student-sign-in'),
                        onPressed:
                            state.signingIn || !state.repository.isConfigured
                            ? null
                            : _submit,
                        child: state.signingIn
                            ? const Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  Text('Memproses…'),
                                ],
                              )
                            : const Text('Masuk'),
                      ),
                    ),
                    if (_showSlowNotice && state.signingIn) ...[
                      const SizedBox(height: 12),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 16,
                            color: Color(0xFF526577),
                          ),
                          SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'Server sedang disiapkan, mohon tunggu sebentar…',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF526577),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),
                    const Text(
                      'Kesulitan masuk? Hubungi pengelola akun kampus Anda.',
                      style: TextStyle(color: Color(0xFF526577), height: 1.5),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Workspace extends StatefulWidget {
  const _Workspace({
    required this.state,
    required this.onAnnouncement,
    required this.onNotification,
    required this.onClass,
  });
  final StudentController state;
  final ValueChanged<Announcement> onAnnouncement;
  final ValueChanged<NotificationItem> onNotification;
  final ValueChanged<StudentClass> onClass;
  @override
  State<_Workspace> createState() => _WorkspaceState();
}

class _WorkspaceState extends State<_Workspace> {
  final visitedTabs = <int>{0};
  StudentController get state => widget.state;

  Widget page(int index) => switch (index) {
    0 => _Home(state: state, onAnnouncement: widget.onAnnouncement),
    1 => StudentClassesPage(state: state, onOpen: widget.onClass),
    2 => _Information(state: state, onOpen: widget.onAnnouncement),
    3 => _Notifications(state: state, onOpen: widget.onNotification),
    _ => _Profile(state: state),
  };

  @override
  Widget build(BuildContext context) {
    visitedTabs.add(state.tab);
    return PopScope(
      canPop: state.tab == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) state.selectTab(0);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const DexaBrand(),
          toolbarHeight: 76,
          actions: [
            if (state.profile == null)
              IconButton(
                tooltip: 'Kembali ke halaman masuk',
                onPressed: state.signOut,
                icon: const Icon(Icons.logout),
              ),
            IconButton(
              tooltip: 'Muat ulang data',
              onPressed: state.loading || state.joining ? null : state.refresh,
              icon: const Icon(Icons.refresh),
            ),
            const SizedBox(width: 4),
          ],
        ),
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              if (state.loading) const LinearProgressIndicator(minHeight: 2),
              Expanded(
                child: state.profile == null
                    ? ListView(
                        padding: const EdgeInsets.all(24),
                        children: [
                          _DataWarning(state: state),
                          Text(
                            state.loading
                                ? 'Memuat akun Anda…'
                                : 'Data mahasiswa belum tersedia.',
                            textAlign: TextAlign.center,
                          ),
                        ],
                      )
                    : IndexedStack(
                        index: state.tab,
                        children: List.generate(
                          5,
                          (index) => visitedTabs.contains(index)
                              ? RepaintBoundary(child: page(index))
                              : const SizedBox.shrink(),
                        ),
                      ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: state.tab,
          onDestinationSelected: (index) {
            FocusManager.instance.primaryFocus?.unfocus();
            state.selectTab(index);
          },
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Beranda',
            ),
            const NavigationDestination(
              icon: Icon(Icons.school_outlined),
              selectedIcon: Icon(Icons.school),
              label: 'Kelas Saya',
            ),
            const NavigationDestination(
              icon: Icon(Icons.article_outlined),
              selectedIcon: Icon(Icons.article_rounded),
              label: 'Informasi',
            ),
            NavigationDestination(
              icon: Badge(
                isLabelVisible: state.unreadCount > 0,
                label: Text(
                  state.unreadCount > 99 ? '99+' : '${state.unreadCount}',
                ),
                child: const Icon(Icons.notifications_outlined),
              ),
              label: 'Notifikasi',
            ),
            const NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}

class _Home extends StatelessWidget {
  const _Home({required this.state, required this.onAnnouncement});
  final StudentController state;
  final ValueChanged<Announcement> onAnnouncement;
  @override
  Widget build(BuildContext context) => RefreshIndicator(
    onRefresh: state.refresh,
    child: ListView(
      key: const PageStorageKey('student-home'),
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      children: [
        _DataWarning(state: state),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _navy,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'RINGKASAN AKADEMIK',
                style: TextStyle(
                  color: Color(0xFF7DD3FC),
                  fontSize: 11,
                  letterSpacing: 1.8,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Selamat datang,',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 4),
              Text(
                state.profile?.name ?? '',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  height: 1.25,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Ikuti kabar akademik dan jangan lewatkan pemberitahuanmu.',
                style: TextStyle(color: Color(0xFFCBDCE9), height: 1.5),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _CountTile(
          label: 'Kelas Saya',
          count: state.classes.where((c) => !c.archived).length,
          icon: Icons.school_outlined,
          onTap: () => state.selectTab(1),
        ),
        const SizedBox(height: 10),
        _CountTile(
          label: 'Informasi tersedia',
          count: state.announcements.length,
          icon: Icons.article_outlined,
          onTap: () => state.selectTab(2),
        ),
        const SizedBox(height: 10),
        _CountTile(
          label: 'Pemberitahuan belum dibaca',
          count: state.unreadCount,
          icon: Icons.notifications_none,
          onTap: () => state.selectTab(3),
        ),
        const SizedBox(height: 28),
        const _Heading(
          title: 'Informasi untukmu',
          subtitle: 'Kabar akademik yang tersedia untuk akunmu.',
        ),
        const SizedBox(height: 12),
        if (state.announcements.isEmpty)
          const _Empty(
            title: 'Belum ada informasi',
            text: 'Informasi akademik akan muncul di sini.',
          )
        else
          ...state.announcements
              .take(3)
              .map(
                (item) => _FeedTile(
                  title: item.title,
                  subtitle: item.summary,
                  meta: '${item.category} · ${item.date}',
                  onTap: () => onAnnouncement(item),
                ),
              ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => state.selectTab(2),
            label: const Text('Lihat semua informasi'),
            icon: const Icon(Icons.arrow_forward, size: 18),
            iconAlignment: IconAlignment.end,
          ),
        ),
      ],
    ),
  );
}

class _CountTile extends StatelessWidget {
  const _CountTile({
    required this.label,
    required this.count,
    required this.icon,
    required this.onTap,
  });
  final String label;
  final int count;
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: _pale,
    borderRadius: BorderRadius.circular(14),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: _blue),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: _ink,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$count',
              style: const TextStyle(
                color: _ink,
                fontWeight: FontWeight.w700,
                fontSize: 22,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _Information extends StatefulWidget {
  const _Information({required this.state, required this.onOpen});
  final StudentController state;
  final ValueChanged<Announcement> onOpen;
  @override
  State<_Information> createState() => _InformationState();
}

class _InformationState extends State<_Information> {
  late final TextEditingController search = TextEditingController(
    text: widget.state.query,
  );
  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final items = state.filteredAnnouncements;
    return RefreshIndicator(
      onRefresh: state.refresh,
      child: ListView(
        key: const PageStorageKey('student-information'),
        physics: const AlwaysScrollableScrollPhysics(),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.all(20),
        children: [
          _DataWarning(state: state),
          const _Heading(
            title: 'Informasi',
            subtitle: 'Tugas dan instruksi dari kelas yang kamu ikuti.',
          ),
          const SizedBox(height: 20),
          TextField(
            controller: search,
            onChanged: state.search,
            decoration: InputDecoration(
              labelText: 'Cari informasi',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: state.query.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Hapus pencarian',
                      onPressed: () {
                        search.clear();
                        state.search('');
                      },
                      icon: const Icon(Icons.close),
                    ),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              ChoiceChip(
                label: const Text('Semua'),
                selected: state.category == null,
                onSelected: (_) => state.filter(null),
              ),
              ...state.categories.map(
                (c) => ChoiceChip(
                  label: Text(c),
                  selected: state.category == c,
                  onSelected: (_) => state.filter(c),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '${items.length} informasi',
            style: const TextStyle(color: Color(0xFF526577)),
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            _Empty(
              title: 'Tidak ada informasi',
              text: state.query.isNotEmpty || state.category != null
                  ? 'Coba kata kunci atau kategori lain.'
                  : 'Pengumuman baru akan tampil di sini.',
              action: state.query.isEmpty && state.category == null
                  ? null
                  : TextButton(
                      onPressed: () {
                        search.clear();
                        state.search('');
                        state.filter(null);
                      },
                      child: const Text('Reset pencarian'),
                    ),
            )
          else
            ...items.map(
              (item) => _FeedTile(
                title: item.title,
                subtitle: item.summary,
                meta: '${item.category} · ${item.date}',
                onTap: () => widget.onOpen(item),
              ),
            ),
        ],
      ),
    );
  }
}

class _Notifications extends StatelessWidget {
  const _Notifications({required this.state, required this.onOpen});
  final StudentController state;
  final ValueChanged<NotificationItem> onOpen;
  @override
  Widget build(BuildContext context) => RefreshIndicator(
    onRefresh: state.refresh,
    child: ListView(
      key: const PageStorageKey('student-notifications'),
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      children: [
        _DataWarning(state: state),
        _Heading(
          title: 'Pemberitahuan',
          subtitle: state.unreadCount == 0
              ? (state.notifications.isEmpty
                    ? 'Nilai yang dirilis dosen akan muncul di sini.'
                    : 'Semua pemberitahuan sudah dibaca.')
              : '${state.unreadCount} pemberitahuan belum dibaca.',
        ),
        const SizedBox(height: 20),
        const Padding(
          padding: EdgeInsets.only(bottom: 16),
          child: Text(
            'Pemberitahuan nilai diperbarui saat data dimuat. Status baca disimpan di perangkat ini.',
            style: TextStyle(color: Color(0xFF526577), height: 1.5),
          ),
        ),
        if (state.notifications.isEmpty)
          const _Empty(
            title: 'Belum ada pemberitahuan',
            text: 'Pemberitahuan untuk akunmu akan muncul di sini.',
          )
        else
          ...state.notifications.map(
            (item) => _FeedTile(
              title: item.title,
              subtitle: item.summary,
              meta:
                  '${item.isRead ? 'Dibaca' : 'Belum dibaca'} · ${item.date}',
              unread: !item.isRead,
              onTap: () => onOpen(item),
            ),
          ),
      ],
    ),
  );
}

class _Profile extends StatelessWidget {
  const _Profile({required this.state});
  final StudentController state;
  String value(String? v) =>
      v == null || v.trim().isEmpty ? 'Belum tersedia' : v;
  @override
  Widget build(BuildContext context) {
    final profile = state.profile;
    // The outgoing route may rebuild while the logout transition is finishing.
    if (profile == null) return const SizedBox.shrink();
    return ListView(
      key: const PageStorageKey('student-profile'),
      padding: const EdgeInsets.all(20),
      children: [
        _DataWarning(state: state),
        const _Heading(
          title: 'Profil saya',
          subtitle: 'Identitas akademik yang terhubung dengan akunmu.',
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _pale,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CircleAvatar(
                backgroundColor: Colors.white,
                foregroundColor: _blue,
                radius: 28,
                child: Icon(Icons.person_outline, size: 30),
              ),
              const SizedBox(height: 16),
              Text(
                profile.name,
                style: const TextStyle(
                  fontSize: 24,
                  color: _ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              const Text('Mahasiswa', style: TextStyle(color: _blue)),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _ProfileField(
          label: 'Nomor induk mahasiswa',
          value: value(profile.studentNumber),
        ),
        _ProfileField(label: 'Program studi', value: value(profile.program)),
        _ProfileField(label: 'Email', value: value(profile.email)),
        const SizedBox(height: 28),
        OutlinedButton.icon(
          key: const Key('student-sign-out'),
          onPressed: () async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (dialogContext) => AlertDialog(
                title: const Text('Keluar dari akun?'),
                content: const Text(
                  'Kamu perlu masuk kembali untuk melihat informasi akunmu.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext, false),
                    child: const Text('Batal'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(dialogContext, true),
                    child: const Text('Keluar'),
                  ),
                ],
              ),
            );
            if (confirmed == true) state.signOut();
          },
          icon: const Icon(Icons.logout),
          label: const Text('Keluar akun'),
        ),
      ],
    );
  }
}

class _ProfileField extends StatelessWidget {
  const _ProfileField({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF526577))),
        const SizedBox(height: 6),
        SelectableText(
          value,
          style: const TextStyle(
            fontSize: 16,
            color: _ink,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 14),
        const Divider(),
      ],
    ),
  );
}

class _Detail extends StatelessWidget {
  const _Detail({
    required this.title,
    required this.category,
    required this.date,
    required this.content,
    required this.appBarTitle,
    this.status,
    this.error,
    this.onRetry,
  });
  final String title, category, date, content, appBarTitle;
  final String? status, error;
  final VoidCallback? onRetry;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(appBarTitle)),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(
                label: Text(category),
                backgroundColor: _pale,
                side: BorderSide.none,
              ),
              if (status case final label?)
                Chip(label: Text(label), side: BorderSide.none),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            '$date (waktu perangkat)',
            style: const TextStyle(color: Color(0xFF526577)),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(
              fontSize: 26,
              height: 1.25,
              color: _ink,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 24),
          if (error case final message?) ...[
            _Notice(message: message, onRetry: onRetry),
            const SizedBox(height: 20),
          ],
          SelectableText(
            content,
            style: const TextStyle(fontSize: 16, height: 1.7, color: _ink),
          ),
          const SizedBox(height: 28),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back, size: 18),
              label: const Text('Kembali'),
            ),
          ),
        ],
      ),
    ),
  );
}

class _FeedTile extends StatelessWidget {
  const _FeedTile({
    required this.title,
    required this.subtitle,
    required this.meta,
    required this.onTap,
    this.unread = false,
  });
  final String title, subtitle, meta;
  final VoidCallback onTap;
  final bool unread;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Material(
      color: unread ? const Color(0xFFF0F9FF) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: unread ? const Color(0xFF7DD3FC) : const Color(0xFFE2E8F0),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                meta,
                style: const TextStyle(
                  color: _blue,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(height: 1.5),
              ),
              const SizedBox(height: 12),
              const Align(
                alignment: Alignment.centerRight,
                child: Icon(Icons.arrow_forward, color: _blue, size: 20),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _Heading extends StatelessWidget {
  const _Heading({required this.title, required this.subtitle});
  final String title, subtitle;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(
          color: _ink,
          fontSize: 25,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
      ),
      const SizedBox(height: 8),
      Text(subtitle, style: const TextStyle(height: 1.5)),
    ],
  );
}

class _Empty extends StatelessWidget {
  const _Empty({required this.title, required this.text, this.action});
  final String title, text;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 8),
    child: Column(
      children: [
        const Icon(Icons.inbox_outlined, size: 40, color: _blue),
        const SizedBox(height: 16),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(text, textAlign: TextAlign.center),
        ?action,
      ],
    ),
  );
}

class _Notice extends StatelessWidget {
  const _Notice({required this.message, this.onRetry});
  final String message;
  final VoidCallback? onRetry;
  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFED7AA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: const TextStyle(color: Color(0xFF7C2D12), height: 1.45),
          ),
          if (onRetry != null)
            TextButton(onPressed: onRetry, child: const Text('Coba lagi')),
        ],
      ),
    ),
  );
}

class _DataWarning extends StatelessWidget {
  const _DataWarning({required this.state});
  final StudentController state;
  @override
  Widget build(BuildContext context) {
    final message = state.dataError;
    if (message == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: _Notice(
        message: message,
        onRetry: state.loading ? null : state.refresh,
      ),
    );
  }
}
