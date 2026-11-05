import 'package:flutter/material.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/demo_badge.dart';
import 'announcement_detail_page.dart';

/// Halaman Beranda Dexa Assessment dengan ringkasan informasi dan notifikasi.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final totalAnnouncements = appState.totalAnnouncementCount;
    final unreadCount = appState.unreadNotificationCount;
    final recentAnnouncements = appState.announcements.take(2).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dexa Assessment'),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: Center(
              child: DemoBadge(label: 'Mode demo'),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Banner Selamat Datang
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.navyPrimary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.school_outlined,
                          color: AppTheme.skyBlueLight,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Portal Akademik',
                          style: TextStyle(
                            color: AppTheme.skyBlueLight,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Selamat Datang di Dexa Assessment',
                      style: TextStyle(
                        color: AppTheme.surfaceWhite,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Kerangka aplikasi informasi dan notifikasi akademik. Seluruh data pada tahap ini adalah data contoh lokal bertanda mode demo.',
                      style: TextStyle(
                        color: AppTheme.surfaceWhite.withValues(alpha: 0.85),
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Bagian Ringkasan
              Text(
                'Ringkasan Aktivitas',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              // Dua Kartu Ringkasan (Dihitung dari data contoh yang sama)
              Row(
                children: [
                  // Kartu Ringkasan Informasi
                  Expanded(
                    child: _SummaryCard(
                      icon: Icons.article_outlined,
                      title: 'Informasi',
                      value: '$totalAnnouncements',
                      label: 'Pengumuman aktif',
                      buttonText: 'Lihat Semua',
                      onPressed: () => appState.setTabIndex(1),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Kartu Ringkasan Notifikasi
                  Expanded(
                    child: _SummaryCard(
                      icon: Icons.notifications_outlined,
                      title: 'Notifikasi',
                      value: '$unreadCount',
                      label: unreadCount > 0 ? 'Belum dibaca' : 'Semua dibaca',
                      buttonText: 'Buka Pesan',
                      highlightValue: unreadCount > 0,
                      onPressed: () => appState.setTabIndex(2),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Header Pengumuman Terbaru
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Pengumuman Terbaru',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => appState.setTabIndex(1),
                    icon: const Icon(Icons.arrow_forward, size: 14),
                    label: const Text('Selengkapnya'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.skyBlue,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Daftar Preview Pengumuman
              ...recentAnnouncements.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Card(
                    child: InkWell(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => AnnouncementDetailPage(
                              announcement: item,
                            ),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Padding(
                        padding: const EdgeInsets.all(14.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.chipBackground,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: AppTheme.borderLight,
                                    ),
                                  ),
                                  child: Text(
                                    item.category,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.navyPrimary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    item.date,
                                    textAlign: TextAlign.end,
                                    style: Theme.of(context).textTheme.bodySmall,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              item.title,
                              style: Theme.of(context).textTheme.titleMedium,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.summary,
                              style: Theme.of(context).textTheme.bodyMedium,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Catatan mode demo di bagian bawah
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.chipBackground,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.borderLight),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: AppTheme.textMuted,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Dexa Assessment Tahap 2: Menampilkan kerangka UI, navigasi empat tab, dan konsistensi data demo lokal.',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String label;
  final String buttonText;
  final VoidCallback onPressed;
  final bool highlightValue;

  const _SummaryCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.label,
    required this.buttonText,
    required this.onPressed,
    this.highlightValue = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: AppTheme.navyPrimary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textDark,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: highlightValue ? AppTheme.skyBlue : AppTheme.navyPrimary,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textMuted,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onPressed,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.navyPrimary,
                  side: const BorderSide(color: AppTheme.borderLight),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  visualDensity: VisualDensity.compact,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: Text(
                  buttonText,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
