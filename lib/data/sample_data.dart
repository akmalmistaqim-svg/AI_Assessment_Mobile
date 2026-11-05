import '../models/announcement.dart';
import '../models/notification_item.dart';

/// Data contoh lokal bertanda mode demo untuk pengujian kerangka UI dan navigasi.
class SampleData {
  SampleData._();

  static List<Announcement> get initialAnnouncements => [
        const Announcement(
          id: 'info-1',
          title: 'Jadwal Ujian Tengah Semester Genap 2026/2027',
          date: '25 Oktober 2026',
          category: 'Akademik',
          summary:
              'Pengumuman jadwal pelaksanaan UTS genap beserta tata tertib ujian daring dan luring.',
          content:
              'Pelaksanaan Ujian Tengah Semester (UTS) Genap Tahun Akademik 2026/2027 akan diselenggarakan mulai tanggal 10 November 2026.\n\n'
              'Mahasiswa diwajibkan memeriksa jadwal ruang dan mata kuliah pada portal akademik serta memastikan tidak ada kendala administrasi sebelum pekan ujian.\n\n'
              'Tata tertib ujian:\n'
              '1. Hadir di ruang ujian 15 menit sebelum waktu mulai.\n'
              '2. Membawa Kartu Tanda Mahasiswa (KTM) atau kartu ujian resmi.\n'
              '3. Berpakaian rapi dan mematuhi aturan integritas akademik.',
        ),
        const Announcement(
          id: 'info-2',
          title: 'Pendaftaran Program Magang & Studi Independen Bersertifikat',
          date: '22 Oktober 2026',
          category: 'Kemahasiswaan',
          summary:
              'Sosialisasi pembukaan pendaftaran program magang industri dan konversi SKS semester depan.',
          content:
              'Pendaftaran program magang bersertifikat periode tahun 2027 telah dibuka secara resmi.\n\n'
              'Mahasiswa aktif semester 5 ke atas dapat berkonsultasi dengan Dosen Pembimbing Akademik (DPA) terkait rencana konversi mata kuliah dan kelayakan beban studi.\n\n'
              'Batas pengumpulan berkas rekomendasi jurusan adalah 15 November 2026 melalui loket administrasi fakultas.',
        ),
        const Announcement(
          id: 'info-3',
          title: 'Pemeliharaan Terjadwal Server Portal Pembelajaran',
          date: '18 Oktober 2026',
          category: 'Layanan TI',
          summary:
              'Pemberitahuan pemeliharaan rutin infrastruktur server portal ujian dan pengumpulan tugas.',
          content:
              'Unit Teknologi Informasi akan melaksanakan pemeliharaan berkala infrastruktur server pada hari Sabtu, 31 Oktober 2026 pukul 22.00 - 04.00 WIB.\n\n'
              'Selama rentang waktu pemeliharaan, portal pembelajaran dan repositori tugas tidak dapat diakses sementara.\n\n'
              'Mohon seluruh mahasiswa dan staf pengajar menyelesaikan unggahan berkas sebelum jadwal pemeliharaan dimulai.',
        ),
        const Announcement(
          id: 'info-4',
          title: 'Panduan Pengajuan Beasiswa Peningkatan Prestasi Akademik',
          date: '15 Oktober 2026',
          category: 'Beasiswa',
          summary:
              'Informasi alur pendaftaran, kriteria penilaian, dan kelengkapan berkas beasiswa prestasi.',
          content:
              'Pendaftaran beasiswa Peningkatan Prestasi Akademik (PPA) periode semester berjalan telah dibuka.\n\n'
              'Persyaratan umum:\n'
              '- Mahasiswa aktif program Sarjana minimal semester 3.\n'
              '- Indeks Prestasi Kumulatif (IPK) minimal 3.25.\n'
              '- Tidak sedang menerima beasiswa dari sumber lain.\n\n'
              'Pengajuan berkas dilayani hingga 5 November 2026 di Biro Administrasi Kemahasiswaan.',
        ),
      ];

  static List<NotificationItem> get initialNotifications => [
        NotificationItem(
          id: 'notif-1',
          title: 'Pengingat Pengisian Kuesioner Evaluasi Dosen',
          date: '27 Oktober 2026, 09:00',
          category: 'Evaluasi',
          summary:
              'Batas pengisian kuesioner evaluasi perkuliahan tengah semester tersisa 3 hari lagi.',
          content:
              'Halo Mahasiswa, mohon luangkan waktu untuk mengisi kuesioner evaluasi proses pembelajaran tengah semester.\n\n'
              'Masukan Anda sangat berharga bagi peningkatan mutu pengajaran fakultas. Pengisian dapat diselesaikan sebelum batas akhir 30 Oktober 2026.',
          isRead: false,
        ),
        NotificationItem(
          id: 'notif-2',
          title: 'Perubahan Ruang Kuliah Analisis & Perancangan Sistem',
          date: '26 Oktober 2026, 14:30',
          category: 'Perkuliahan',
          summary:
              'Perkuliahan sesi Rabu dialihkan dari Ruang 302 ke Gedung Lab Komputer 2.',
          content:
              'Diberitahukan kepada seluruh peserta mata kuliah Analisis & Perancangan Sistem kelas B, bahwa pertemuan tatap muka pada hari Rabu dialihkan ke Gedung Lab Komputer 2 lantai 3 untuk agenda praktikum perangkat lunak.',
          isRead: false,
        ),
        NotificationItem(
          id: 'notif-3',
          title: 'Hasil Verifikasi Berkas Ujian Tengah Semester',
          date: '24 Oktober 2026, 11:15',
          category: 'Administrasi',
          summary:
              'Berkas persyaratan ujian Anda telah diverifikasi oleh bagian akademik.',
          content:
              'Berkas administrasi dan kartu ujian Anda untuk periode UTS telah diverifikasi lengkap dan disetujui.\n\n'
              'Kartu ujian digital dapat disimpan untuk ditunjukkan saat pelaksanaan ujian berlangsung.',
          isRead: true,
        ),
        NotificationItem(
          id: 'notif-4',
          title: 'Batas Akhir Validasi Rencana Studi Mahasiswa',
          date: '20 Oktober 2026, 16:00',
          category: 'Akademik',
          summary:
              'Konfirmasi validasi kartu rencana studi telah ditutup secara otomatis oleh sistem.',
          content:
              'Periode revisi dan validasi Kartu Rencana Studi (KRS) telah resmi ditutup. Seluruh mata kuliah yang tercantum telah terdaftar secara permanen pada pangkalan data akademik.',
          isRead: true,
        ),
      ];
}
