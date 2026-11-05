import 'package:flutter/material.dart';

import '../models/notification_item.dart';
import '../theme/app_theme.dart';
import '../widgets/demo_badge.dart';

/// Halaman detail notifikasi yang menampilkan pesan lengkap dan status baca.
class NotificationDetailPage extends StatelessWidget {
  final NotificationItem notification;

  const NotificationDetailPage({super.key, required this.notification});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Notifikasi')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Banner simulasi lokal
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.chipBackground,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppTheme.borderLight),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.sync_alt_outlined,
                      size: 16,
                      color: AppTheme.textMuted,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Pesan ini merupakan simulasi lokal. Status notifikasi telah ditandai sebagai sudah dibaca.',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Label berpindah baris ketika lebar layar tidak mencukupi.
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.skyBlueLight,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppTheme.skyBlueBorder),
                    ),
                    child: Text(
                      notification.category,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.skyBlue,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.chipBackground,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.done_all,
                          size: 12,
                          color: AppTheme.textMuted,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Sudah Dibaca',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.textMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const DemoBadge(label: 'Simulasi'),
                ],
              ),
              const SizedBox(height: 12),
              // Tanggal
              Row(
                children: [
                  const Icon(
                    Icons.access_time,
                    size: 13,
                    color: AppTheme.textMuted,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      notification.date,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Judul Notifikasi
              Text(
                notification.title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              // Isi Lengkap
              Text(
                notification.content,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 32),
              // Tombol Kembali
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Kembali ke Daftar Notifikasi'),
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
