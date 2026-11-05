import 'package:flutter/material.dart';

import '../models/announcement.dart';
import 'student_controller.dart';
import 'student_repository.dart';

class StudentClassesPage extends StatefulWidget {
  const StudentClassesPage({
    super.key,
    required this.state,
    required this.onOpen,
  });
  final StudentController state;
  final ValueChanged<StudentClass> onOpen;
  @override
  State<StudentClassesPage> createState() => _StudentClassesPageState();
}

class _StudentClassesPageState extends State<StudentClassesPage> {
  final code = TextEditingController();
  final form = GlobalKey<FormState>();
  @override
  void dispose() {
    code.dispose();
    super.dispose();
  }

  Future<void> join() async {
    if (widget.state.joining ||
        widget.state.loading ||
        !form.currentState!.validate()) {
      return;
    }
    FocusScope.of(context).unfocus();
    final result = await widget.state.joinClass(code.text);
    if (!mounted || !widget.state.signedIn || result == null) return;
    code.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Berhasil bergabung ke ${result.name}.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    return RefreshIndicator(
      onRefresh: state.refresh,
      child: ListView(
        key: const PageStorageKey('student-classes'),
        padding: const EdgeInsets.all(20),
        physics: const AlwaysScrollableScrollPhysics(),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        children: [
          Text('Kelas Saya', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          const Text(
            'Kelas dan mata kuliah yang kamu ikuti di Dexa Assessment.',
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Form(
                key: form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gabung kelas',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    const Text('Masukkan kode kelas yang diberikan dosen.'),
                    const SizedBox(height: 16),
                    TextFormField(
                      key: const Key('student-class-code'),
                      controller: code,
                      enabled: !state.joining && !state.loading,
                      textCapitalization: TextCapitalization.characters,
                      autocorrect: false,
                      enableSuggestions: false,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => join(),
                      decoration: const InputDecoration(
                        labelText: 'Kode kelas',
                        prefixIcon: Icon(Icons.key_outlined),
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'Masukkan kode kelas.'
                          : value.trim().length > 20
                          ? 'Kode kelas maksimal 20 karakter.'
                          : null,
                    ),
                    if (state.joinError case final error?) ...[
                      const SizedBox(height: 12),
                      Text(
                        error,
                        key: const Key('class-join-error'),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        key: const Key('student-join-class'),
                        onPressed: state.joining || state.loading ? null : join,
                        icon: state.joining
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.add),
                        label: Text(
                          state.joining ? 'Menghubungkan…' : 'Gabung kelas',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          if (state.dataError case final error?) ...[
            Text(
              error,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: state.loading || state.joining
                    ? null
                    : state.refresh,
                icon: const Icon(Icons.refresh),
                label: const Text('Muat ulang kelas'),
              ),
            ),
          ],
          if (state.classes.isEmpty &&
              !state.loading &&
              state.dataError == null)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text(
                'Belum mengikuti kelas. Gunakan kode dari dosen untuk mulai bergabung.',
              ),
            ),
          ...state.classes.map(
            (course) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Card(
                child: InkWell(
                  key: ValueKey('class-${course.id}'),
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => widget.onOpen(course),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (course.archived)
                          const Chip(label: Text('Diarsipkan')),
                        Text(
                          course.name,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        if (course.subject.isNotEmpty) Text(course.subject),
                        Text(
                          'Dosen: ${course.lecturer.isEmpty ? 'Belum tersedia' : course.lecturer}',
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Lihat kelas',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward,
                              size: 18,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class StudentClassDetailPage extends StatefulWidget {
  const StudentClassDetailPage({
    super.key,
    required this.course,
    required this.state,
    required this.onTask,
  });
  final StudentClass course;
  final StudentController state;
  final ValueChanged<Announcement> onTask;
  @override
  State<StudentClassDetailPage> createState() => _StudentClassDetailPageState();
}

class _StudentClassDetailPageState extends State<StudentClassDetailPage> {
  late Future<List<Announcement>> tasks = widget.state.classAssignments(
    widget.course,
  );
  Future<void> reload() async {
    final next = widget.state.classAssignments(widget.course);
    setState(() {
      tasks = next;
    });
    try {
      await next;
    } catch (_) {
      /* Error is displayed by FutureBuilder. */
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Detail kelas')),
    body: SafeArea(
      child: RefreshIndicator(
        onRefresh: reload,
        child: FutureBuilder<List<Announcement>>(
          future: tasks,
          builder: (context, snapshot) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
            children: [
              if (widget.course.archived)
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Chip(label: Text('Kelas diarsipkan')),
                ),
              Text(
                widget.course.name,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 12),
              if (widget.course.subject.isNotEmpty) Text(widget.course.subject),
              Text(
                'Dosen: ${widget.course.lecturer.isEmpty ? 'Belum tersedia' : widget.course.lecturer}',
              ),
              if (widget.course.description.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(widget.course.description),
              ],
              const SizedBox(height: 24),
              Text(
                'Tugas kelas',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              if (snapshot.connectionState != ConnectionState.done)
                const LinearProgressIndicator()
              else if (snapshot.hasError) ...[
                Text(
                  snapshot.error is StudentFailure
                      ? (snapshot.error! as StudentFailure).message
                      : 'Tugas belum dapat dimuat. Silakan coba lagi.',
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: reload,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Coba lagi'),
                  ),
                ),
              ] else if (snapshot.data!.isEmpty)
                const Text(
                  'Belum ada tugas yang dipublikasikan untuk kelas ini.',
                )
              else
                ...snapshot.data!.map(
                  (task) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Card(
                      child: ListTile(
                        key: ValueKey('class-task-${task.id}'),
                        contentPadding: const EdgeInsets.all(16),
                        title: Text(task.title),
                        subtitle: Text('${task.category} · ${task.date}'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => widget.onTask(task),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}
