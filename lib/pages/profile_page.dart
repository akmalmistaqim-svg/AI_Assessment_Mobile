import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/demo_badge.dart';

/// Halaman Profil contoh untuk menampilkan identitas akun demo dan informasi sistem.
/// Tidak memiliki tombol dummy / non-fungsional sesuai ketentuan batas pekerjaan.
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Pengguna'),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: Center(
              child: DemoBadge(label: 'Akun demo'),
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
              // Kartu Identitas Akun Contoh
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      // Avatar Lingkaran Praktis
                      Container(
                        width: 56,
                        height: 56,
                        decoration: const BoxDecoration(
                          color: AppTheme.skyBlueLight,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.person,
                          size: 32,
                          color: AppTheme.navyPrimary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Info Pengguna
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pengguna Uji Coba Dexa',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textDark,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'ID Contoh: DEXA-2026-DEMO',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textMuted,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Program: Sistem Informasi & Penilaian',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.navyPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Bagian Informasi Akun Contoh
              Text(
                'Data Akademik Contoh',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Column(
                    children: [
                      _ProfileRow(
                        label: 'Status Akun',
                        value: 'Simulasi Evaluasi',
                        isHighlight: true,
                      ),
                      const Divider(),
                      _ProfileRow(
                        label: 'Peran Pengguna',
                        value: 'Pengguna Umum (Belum Ditentukan)',
                      ),
                      const Divider(),
                      _ProfileRow(
                        label: 'Semester Aktif',
                        value: 'Ganjil 2026/2027 (Demo)',
                      ),
                      const Divider(),
                      _ProfileRow(
                        label: 'Institusi',
                        value: 'Dexa Assessment Academy',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Bagian Informasi Aplikasi
              Text(
                'Informasi Aplikasi',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Column(
                    children: [
                      _ProfileRow(
                        label: 'Aplikasi',
                        value: 'Dexa Assessment Mobile',
                      ),
                      const Divider(),
                      _ProfileRow(
                        label: 'Tahap Pengembangan',
                        value: 'Tahap 2 (Kerangka UI & Navigasi)',
                      ),
                      const Divider(),
                      _ProfileRow(
                        label: 'Versi',
                        value: '1.0.0+1 (Debug Build)',
                      ),
                      const Divider(),
                      _ProfileRow(
                        label: 'Lingkungan',
                        value: 'Offline / Simulasi Lokal',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Keterangan Mode Demo dan Batasan Tahap 2
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.chipBackground,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.borderLight),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: AppTheme.textMuted,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Catatan Batas Tahap 2',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Fitur autentikasi/login, pergantian profil, dan pengaturan akun riil belum diaktifkan pada tahap ini sesuai batas pekerjaan kerangka tampilan.',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                        height: 1.4,
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

class _ProfileRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isHighlight;

  const _ProfileRow({
    required this.label,
    required this.value,
    this.isHighlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textMuted,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isHighlight ? FontWeight.w600 : FontWeight.w500,
                color: isHighlight ? AppTheme.skyBlue : AppTheme.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
