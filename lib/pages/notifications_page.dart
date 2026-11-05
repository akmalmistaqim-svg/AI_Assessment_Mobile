import 'package:flutter/material.dart';
import '../models/notification_item.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/demo_badge.dart';
import 'notification_detail_page.dart';

/// Halaman Notifikasi dengan penanda status dibaca/belum dibaca, persistensi lokal, dan simulasi data.
class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final notifications = appState.notifications;
    final unreadCount = appState.unreadNotificationCount;
    final storageError = appState.storageErrorMessage;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifikasi'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: DemoBadge(
                label: unreadCount > 0 ? '$unreadCount belum dibaca' : 'Semua dibaca',
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.all(16.0),
          itemCount: notifications.length + (storageError != null ? 2 : 1),
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            // Banner peringatan kegagalan penyimpanan lokal jika ada
            if (storageError != null && index == 0) {
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade300),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.amber.shade800,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        storageError,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.amber.shade900,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 16),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => appState.clearStorageErrorMessage(),
                    ),
                  ],
                ),
              );
            }

            final headerIndex = storageError != null ? 1 : 0;
            // Header pemberitahuan simulasi di bagian atas daftar
            if (index == headerIndex) {
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.skyBlueLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.skyBlueBorder),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppTheme.skyBlue,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Pemberitahuan simulasi lokal. Status baca disimpan di perangkat dan tetap bertahan setelah aplikasi ditutup.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            final itemIndex = index - (storageError != null ? 2 : 1);
            final item = notifications[itemIndex];
            return _NotificationCard(
              notification: item,
              onTap: () {
                // Tandai sebagai dibaca secara idempoten dan persisten sebelum membuka detail
                appState.markNotificationAsRead(item.id);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => NotificationDetailPage(notification: item),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final NotificationItem notification;
  final VoidCallback onTap;

  const _NotificationCard({
    required this.notification,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isUnread = !notification.isRead;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isUnread ? AppTheme.skyBlue : AppTheme.borderLight,
          width: isUnread ? 1.5 : 1.0,
        ),
      ),
      color: isUnread ? AppTheme.skyBlueLight.withValues(alpha: 0.35) : AppTheme.surfaceWhite,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Baris Status, Kategori & Waktu
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 4,
                children: [
                  if (isUnread) ...[
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppTheme.skyBlue,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'Belum Dibaca',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.skyBlue,
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    const Text(
                      'Sudah Dibaca',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                  Text(
                    '•  ${notification.category}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textMuted,
                    ),
                  ),
                  Text(
                    notification.date,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Judul Notifikasi
              Text(
                notification.title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isUnread ? FontWeight.w700 : FontWeight.w600,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 6),
              // Ringkasan Notifikasi
              Text(
                notification.summary,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
