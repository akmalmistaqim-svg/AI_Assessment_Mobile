# Penyesuaian UI dan login mobile — 29 Oktober 2026

> APK pada lokasi unduhan telah diperbarui lagi dengan fitur kelas. Lihat [laporan kelas mobile](LAPORAN_KELAS_MOBILE_2026-10-29.md) untuk metadata terbaru; hash di laporan ini bersifat historis.

Acuan: palet website yang telah dibagikan pengguna di chat (putih, teks gelap, biru langit, biru tua). Tidak membuka atau mengubah proyek website.

## Perubahan
- Halaman awal langsung menampilkan satu formulir login: identitas Dexa Assessment, judul Masuk ke akun Anda, email, kata sandi, dan tombol Masuk.
- Menghapus judul Ruang mahasiswa dan ikon sekolah besar yang berulang pada login. Tidak ada halaman pengantar atau pemilih peran tambahan.
- Header dan indikator tab memakai biru langit #BAE6FD; latar #F0F9FF, tombol/fokus #0369A1, judul #0F172A, kartu sambutan #0C4A6E.
- Palet berlaku pada seluruh alur mahasiswa; daftar tetap putih agar isi mudah dibaca. Navigasi aktif memakai teks/ikon gelap agar kontras.
- Hak akses tetap mahasiswa; perubahan judul login tidak menambahkan login dosen. Kontrak API, penyimpanan, dan logika autentikasi tidak diubah.

## Berkas
- lib/student/student_app.dart: tema lokal dan presentasi login.
- test/student_flow_test.dart: ekspektasi teks email dan warna ikon disesuaikan; seluruh pengujian alur dipertahankan.

## Verifikasi
- flutter analyze --no-pub: bersih (7,7 detik).
- flutter test --no-pub --concurrency=1 --reporter expanded: 55 lulus, 0 gagal (31 detik). Satu kasus adalah generator screenshot opsional yang tidak melakukan capture pada run default.
- Mencakup validasi login, logout, detail, status baca, tombol kembali, layar kecil, pembesaran teks, serta keyboard landscape.
- Bukti: docs/evidence/student-ui-refresh-analyze.log dan student-ui-refresh-tests.log.
- Build APK debug terbaru: BERHASIL (Gradle 30 detik). Lokasi: `D:\Dexa_Assessment_Mobile\build\app\outputs\flutter-apk\app-debug.apk`. Ukuran 194,709,489 bytes. SHA256 `99247ef9a8cf780ee5f520366437540c241cd6a04ed5a549626e4d1daa830221`. Kernel APK memuat judul login baru dan tidak memuat judul tes integrasi/email fixture. Bukti: student-ui-refresh-build.log dan student-ui-refresh-apk.json.

Screenshot student-android dan pengujian backend/emulator dalam laporan sebelumnya berasal dari revisi sebelum perubahan visual ini. Belum ada screenshot atau pengujian emulator ulang untuk revisi warna/login ini.


Preview visual terbaru tersedia di `docs/evidence/student-design-2026-10-29`. Delapan gambar berasal dari render widget Flutter dengan font asli dan data contoh, bukan screenshot emulator atau bukti koneksi backend. Lihat README di folder tersebut. Tes capture berhasil; APK normal tetap sama.
