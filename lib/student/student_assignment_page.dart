import 'package:flutter/material.dart';

import 'answer_file_picker.dart';
import 'student_assignment.dart';
import 'student_controller.dart';
import 'student_repository.dart';

class StudentAssignmentPage extends StatefulWidget {
  const StudentAssignmentPage({
    super.key,
    required this.state,
    required this.ref,
    this.filePicker = pickAnswerFile,
  });
  final StudentController state;
  final AssignmentRef ref;
  final AnswerFilePicker filePicker;
  @override
  State<StudentAssignmentPage> createState() => _StudentAssignmentPageState();
}

class _StudentAssignmentPageState extends State<StudentAssignmentPage> {
  final answer = TextEditingController();
  StudentAssignment? task;
  AnswerFile? file;
  SubmissionReceipt? receipt;
  String? error, loadError;
  String initialText = '';
  bool loading = true,
      sending = false,
      choosing = false,
      confirming = false,
      uncertain = false,
      textMode = true,
      allowLeave = false;
  bool get busy => sending || choosing || confirming;
  bool get dirty => file != null || answer.text != initialText;
  @override
  void initState() {
    super.initState();
    load(resetDraft: true);
  }

  @override
  void dispose() {
    answer.dispose();
    super.dispose();
  }

  String message(Object e) => e is StudentFailure
      ? e.message
      : 'Belum dapat memuat data. Periksa koneksi dan coba lagi.';
  Future<void> load({bool resetDraft = false}) async {
    if (!mounted) return;
    setState(() {
      loading = true;
      loadError = null;
    });
    try {
      final result = await widget.state.assignment(widget.ref);
      if (!mounted) return;
      setState(() {
        task = result;
        if (resetDraft) {
          final active = result.submission?.active;
          initialText = active?.type == 'TEXT' ? active!.content : '';
          answer.text = initialText;
          textMode =
              result.acceptsText && (active == null || active.type == 'TEXT');
          if (result.fileExtensions.isEmpty) textMode = true;
          file = null;
        }
        uncertain =
            receipt != null &&
            result.submission?.activeVersionId != receipt!.versionId;
        if (uncertain) loadError = 'Jawaban sudah diterima, tetapi rincian terbaru belum tersedia. Muat ulang status.';
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          loadError = message(e);
          if (receipt != null) uncertain = true;
        });
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> choose() async {
    if (busy || loading) return;
    setState(() {
      choosing = true;
      error = null;
    });
    try {
      final selected = await widget.filePicker(task!.fileExtensions);
      if (!mounted || selected == null) return;
      selected.validate(task!.fileExtensions);
      setState(() => file = selected);
    } catch (e) {
      if (mounted) {
        setState(
          () => error = e is StudentFailure ? e.message : 'Berkas tidak dapat dibuka. Pilih kembali dokumen dari penyimpanan perangkat.',
        );
      }
    } finally {
      if (mounted) setState(() => choosing = false);
    }
  }

  Future<void> send() async {
    if (busy || loading || uncertain || task == null) return;
    final current = task!;
    try {
      current.validateAnswer(
        textMode ? answer.text : null,
        textMode ? null : file,
      );
    } catch (e) {
      setState(() => error = message(e));
      return;
    }
    setState(() => confirming = true);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          current.submission == null ? 'Kirim jawaban?' : 'Kirim versi baru?',
        ),
        content: Text(
          current.submission == null
              ? 'Jawaban akan tersimpan dan dapat diperiksa dosen. Pastikan isi jawaban sudah benar.'
              : 'Versi baru akan menjadi jawaban aktif. Riwayat versi sebelumnya tetap tersimpan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Periksa lagi'),
          ),
          FilledButton(
            key: const Key('confirm-answer-send'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Kirim sekarang'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    setState(() => confirming = false);
    if (confirmed != true) return;
    setState(() {
      sending = true;
      error = null;
      receipt = null;
    });
    try {
      final result = await widget.state.submitAnswer(
        current,
        text: textMode ? answer.text : null,
        file: textMode ? null : file,
      );
      if (!mounted) return;
      setState(() {
        receipt = result;
        file = null;
        initialText = '';
        answer.clear();
        sending = false;
      });
      await load(resetDraft: true);
    } catch (e) {
      if (mounted) {
        setState(() {
          error = message(e);
          uncertain =
              e is! StudentFailure || e.kind == FailureKind.submissionUncertain;
        });
      }
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  Future<void> leave(bool didPop, Object? result) async {
    if (didPop || allowLeave) return;
    if (busy) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tunggu proses selesai sebelum meninggalkan halaman.'),
        ),
      );
      return;
    }
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tinggalkan jawaban?'),
        content: const Text('Perubahan yang belum dikirim akan hilang.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Lanjut menulis'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Tinggalkan'),
          ),
        ],
      ),
    );
    if (!mounted || discard != true) return;
    setState(() => allowLeave = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop();
    });
  }

  Widget panel(List<Widget> children) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    ),
  );
  Widget notice(String text, {bool success = false}) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: success
          ? const Color(0xFFE0F2FE)
          : Theme.of(context).colorScheme.errorContainer,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      text,
      style: TextStyle(
        color: success
            ? const Color(0xFF075985)
            : Theme.of(context).colorScheme.onErrorContainer,
      ),
    ),
  );
  @override
  Widget build(BuildContext context) {
    final current = task;
    final active = current?.submission?.active;
    final result = current?.submission?.result;
    final blocked = current?.blockedReason;
    return PopScope<Object?>(
      canPop: allowLeave || (!busy && !dirty),
      onPopInvokedWithResult: leave,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Detail tugas'),
          actions: [
            IconButton(
              key: const Key('reload-assignment'),
              tooltip: 'Muat ulang status',
              onPressed: busy || loading ? null : () => load(),
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: SafeArea(
          child: loading && current == null
              ? const Center(child: CircularProgressIndicator())
              : current == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(loadError ?? 'Tugas belum tersedia.'),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: () => load(resetDraft: true),
                          child: const Text('Coba lagi'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => busy ? Future<void>.value() : load(),
                  child: ListView(
                    key: const PageStorageKey('student-assignment-detail'),
                    padding: const EdgeInsets.all(16),
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      if (loading) const LinearProgressIndicator(),
                      if (receipt != null)
                        notice(
                          'Jawaban berhasil dikirim. Versi ${receipt!.number} sudah diterima server.',
                          success: true,
                        ),
                      if (loadError != null) notice(loadError!),
                      Text(
                        current.className,
                        style: Theme.of(context).textTheme.labelLarge
                            ?.copyWith(color: const Color(0xFF0369A1)),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        current.title,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 16),
                      panel([
                        Text(
                          'Ketentuan tugas',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        Text('Batas pengumpulan: ${current.dueLabel}'),
                        const SizedBox(height: 8),
                        Text(
                          'Format: ${current.type == "ANY" ? "Teks, PDF, atau DOCX" : current.type} · Maksimum ${current.maxScore} poin',
                        ),
                        const SizedBox(height: 8),
                        Text(
                          current.allowLate
                              ? 'Pengumpulan terlambat diizinkan oleh dosen.'
                              : 'Pengumpulan ditutup setelah tenggat.',
                        ),
                        const Divider(height: 28),
                        Text(
                          'Instruksi',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        SelectableText(
                          current.instructions.isEmpty
                              ? 'Belum ada instruksi tambahan.'
                              : current.instructions,
                        ),
                      ]),
                      const SizedBox(height: 12),
                      if (result != null) ...[
                        panel([
                          Text(
                            'Nilai sudah dirilis',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '${result.score} / ${current.maxScore}',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            result.feedback.isEmpty
                                ? 'Belum ada catatan tambahan dari dosen.'
                                : result.feedback,
                          ),
                        ]),
                        const SizedBox(height: 12),
                      ],
                      panel([
                        Row(
                          children: [
                            Icon(
                              active == null
                                  ? Icons.edit_note
                                  : Icons.check_circle_outline,
                              color: const Color(0xFF0369A1),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                active == null
                                    ? 'Belum dikumpulkan'
                                    : 'Jawaban sudah dikumpulkan',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                          ],
                        ),
                        if (active != null) ...[
                          const SizedBox(height: 12),
                          Text('Versi ${active.number} · ${active.type}'),
                          Text('Dikirim ${active.submittedAt}'),
                          if (active.fileName != null) Text(active.fileName!),
                          const SizedBox(height: 12),
                          Text(
                            result == null
                                ? 'Menunggu pemeriksaan dosen.'
                                : 'Nilai dan umpan balik tersedia di atas.',
                          ),
                          if (active.content.isNotEmpty)
                            ExpansionTile(
                              key: PageStorageKey(
                                'answer-content-${widget.ref.key}-${active.id}',
                              ),
                              tilePadding: EdgeInsets.zero,
                              title: const Text('Lihat jawaban tersimpan'),
                              children: [
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: SelectableText(active.content),
                                ),
                              ],
                            ),
                        ],
                        if (blocked != null) ...[
                          const SizedBox(height: 16),
                          notice(blocked),
                        ] else ...[
                          const Divider(height: 28),
                          Text(
                            active == null
                                ? 'Kumpulkan jawaban'
                                : 'Perbarui jawaban',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 12),
                          if (current.acceptsText &&
                              current.fileExtensions.isNotEmpty)
                            Wrap(
                              spacing: 10,
                              children: [
                                ChoiceChip(
                                  key: const Key('answer-mode-text'),
                                  label: const Text('Tulis jawaban'),
                                  selected: textMode,
                                  onSelected: busy || loading
                                      ? null
                                      : (_) => setState(() {
                                          textMode = true;
                                          error = null;
                                        }),
                                ),
                                ChoiceChip(
                                  key: const Key('answer-mode-file'),
                                  label: const Text('Unggah dokumen'),
                                  selected: !textMode,
                                  onSelected: busy || loading
                                      ? null
                                      : (_) => setState(() {
                                          textMode = false;
                                          error = null;
                                        }),
                                ),
                              ],
                            ),
                          const SizedBox(height: 12),
                          if (textMode)
                            TextField(
                              key: const Key('student-answer-text'),
                              controller: answer,
                              enabled: !busy && !loading,
                              minLines: 5,
                              maxLines: 12,
                              keyboardType: TextInputType.multiline,
                              decoration: const InputDecoration(
                                labelText: 'Jawaban',
                                alignLabelWithHint: true,
                                hintText:
                                    'Tulis jawaban sesuai instruksi tugas.',
                              ),
                              onChanged: (_) => setState(() => error = null),
                            )
                          else ...[
                            Text(
                              'Pilih ${current.fileExtensions.map((x) => x.toUpperCase()).join(" atau ")} · maksimal 10 MB',
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              key: const Key('student-pick-answer'),
                              onPressed: busy || loading ? null : choose,
                              icon: const Icon(Icons.attach_file),
                              label: Text(
                                choosing
                                    ? 'Membuka berkas…'
                                    : file == null
                                    ? 'Pilih dokumen'
                                    : 'Ganti dokumen',
                              ),
                            ),
                            if (file != null)
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(file!.name),
                                subtitle: Text(
                                  '${(file!.bytes.length / 1024).toStringAsFixed(1)} KB',
                                ),
                                trailing: IconButton(
                                  tooltip: 'Hapus pilihan',
                                  onPressed: busy
                                      ? null
                                      : () => setState(() => file = null),
                                  icon: const Icon(Icons.close),
                                ),
                              ),
                          ],
                          const SizedBox(height: 16),
                          if (error != null) notice(error!),
                          if (uncertain)
                            OutlinedButton.icon(
                              key: const Key('check-submission-status'),
                              onPressed: busy || loading ? null : () => load(),
                              icon: const Icon(Icons.refresh),
                              label: const Text('Periksa status pengumpulan'),
                            ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              key: const Key('student-send-answer'),
                              onPressed:
                                  busy ||
                                      loading ||
                                      uncertain ||
                                      loadError != null
                                  ? null
                                  : send,
                              icon: sending
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.send_outlined),
                              label: Text(
                                sending
                                    ? 'Mengirim jawaban…'
                                    : active == null
                                    ? 'Kirim jawaban'
                                    : 'Kirim versi baru',
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Status berhasil muncul setelah server menerima jawaban.',
                          ),
                        ],
                      ]),
                      if (current.submission != null) ...[
                        const SizedBox(height: 12),
                        panel([
                          Text(
                            'Riwayat pengumpulan',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          ...current.submission!.versions.map(
                            (v) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                'Versi ${v.number}${v.id == current.submission!.activeVersionId ? " · Aktif" : ""}',
                              ),
                              subtitle: Text(
                                '${v.fileName ?? v.type}\n${v.submittedAt}',
                              ),
                            ),
                          ),
                        ]),
                      ],
                      if (current.rubric.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        panel([
                          Text(
                            'Pedoman penilaian',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          ...current.rubric.map(
                            (r) => Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Text(r),
                            ),
                          ),
                        ]),
                      ],
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
