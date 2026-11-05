import 'package:flutter/material.dart';

import '../models/announcement.dart';
import '../theme/app_theme.dart';
import '../widgets/demo_badge.dart';

/// Halaman detail pengumuman akademik dengan tombol kembali ke daftar.
class AnnouncementDetailPage extends StatelessWidget {
  final Announcement announcement;

  const AnnouncementDetailPage({super.key, required this.announcement});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Informasi')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Baris Kategori & Tanggal
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.skyBlueLight,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: AppTheme.skyBlueBorder,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      announcement.category,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.skyBlue,
                      ),
                    ),
                  ),
                  const DemoBadge(label: 'Data demo'),
                ],
              ),
              const SizedBox(height: 12),
              // Tanggal
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today_outlined,
                    size: 14,
                    color: AppTheme.textMuted,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      announcement.date,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Judul Pengumuman
              Text(
                announcement.title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              // Ringkasan Pengantar
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.chipBackground,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.borderLight),
                ),
                child: Text(
                  announcement.summary,
                  style: const TextStyle(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Isi Lengkap
              Text(
                announcement.content,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 32),
              // Tombol Kembali
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Kembali ke Daftar Informasi'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.navyPrimary,
                    side: const BorderSide(color: AppTheme.navyPrimary),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
