# Laporan uji kelas mobile dan website dosen — 1 November 2026

## Status
SEBAGIAN: alur widget Flutter dengan FastAPI/PostgreSQL asli dan pemeriksaan website dosen berhasil. Pengujian Android end-to-end belum berhasil karena emulator berulang kali mengalami System UI isn't responding. Hasil widget tidak dianggap sebagai hasil emulator.

## Data uji dan perubahan yang benar-benar terjadi
- Membuat akun mahasiswa teskelas (teskelas@example.com) melalui POST /auth/register sesuai izin pengguna.
- Akun bergabung ke kelas Rekayasa Perangkat Lunak A milik akun fixture dosen_a@test.local melalui tombol Gabung kelas pada widget aplikasi Flutter yang memakai FastApiStudentRepository asli.
- Keanggotaan kelas sebelum tes: 2. Sesudah tes: 3. Keanggotaan teskelas pada kelas tersebut: tepat 1.
- Pengumpulan tugas dari teskelas: 0. Tidak mengirim jawaban melalui API terpisah untuk menyimulasikan fitur mobile yang belum tersedia.
- Tidak mengubah akun Ihsan, membuat kelas baru, mengubah tugas/nilai, menjalankan seed, mengubah skema, atau menghapus database.
- Akun dan keanggotaannya dipertahankan untuk pengujian lanjutan. Kredensial berada di .local/teskelas.json, diabaikan melalui .gitignore; tidak dicantumkan dalam laporan.

## Hasil pemeriksaan
| Pemeriksaan | Hasil dan batas |
|---|---|
| Login mahasiswa menuju dashboard | Lulus pada widget aplikasi dengan HTTP/API asli |
| Gabung kelas baru | Berhasil pada percobaan widget pertama; PostgreSQL mengonfirmasi tambahan 1 keanggotaan |
| Membaca tugas kelas | Berhasil membuka Tugas 1: Spesifikasi Kebutuhan Perangkat Lunak |
| Gabung ulang | Ditolak dengan pesan pada UI; database tetap hanya 1 keanggotaan teskelas |
| Profil dan logout | Lulus pada pengujian lanjutan setelah memperbaiki selector gulir tes |
| Website dosen | Playwright login melalui form, dashboard tampil, tab Mahasiswa kelas menampilkan teskelas; tidak ada pageerror yang tertangkap |
| Unggah jawaban lewat mobile | Belum tersedia; halaman detail menampilkan petunjuk pengumpulan melalui website |
| Pengumpulan teskelas di sisi dosen | Belum ada; database menunjukkan 0 pengumpulan. Angka 1 pengumpulan pada tugas RPL adalah data yang sudah ada, bukan kiriman teskelas |
| flutter analyze --no-pub | No issues found, 7.5 detik |
| APK normal | Dipertahankan, SHA256 sama dengan artefak sebelumnya |

## Rincian tes dan perbaikan alat QA
Percobaan widget pertama berhasil login, melakukan POST gabung kelas melalui callback tombol aplikasi, membaca tugas, dan menolak join ulang. Tes kemudian gagal karena email profil berada di bawah area layar dan belum digulir. Ini kegagalan selector tes, bukan bukti email hilang dari data profil.

Pengujian lanjutan memakai keanggotaan yang sudah tersimpan (RESUME_LIVE_CLASS_QA=true), sehingga tidak mengulang pendaftaran baru. Selector gulir diperbaiki untuk memilih Scrollable utama. Hasil akhir: 1 tes alur lulus, 0 gagal, 15 detik. Local SharedPreferences memakai penyimpanan pengujian; jaringan, autentikasi, kelas, tugas, dan database menggunakan layanan asli.

Tes live bersifat opt-in. Perintah default flutter test tidak membuat keanggotaan. Untuk memeriksa akun yang kini sudah menjadi anggota:

```powershell
flutter test --no-pub test/live/student_class_backend_widget_test.dart --dart-define=RUN_LIVE_CLASS_QA=true --dart-define=RESUME_LIVE_CLASS_QA=true --reporter expanded
```

Jangan menjalankan ulang persiapan fixture untuk menyetel ulang database. Tidak ada penghapusan keanggotaan otomatis.

## Android: apa yang sudah dan belum dibuktikan
APK integrasi berhasil dibangun dan dipasang. Runner Flutter Driver tertahan sebelum kasus uji berjalan. APK normal kemudian dipasang; halaman login benar-benar tampil dan screenshot aktual diperiksa. Otomasi input mengalami kehilangan karakter. Percobaan ulang setelah boot dengan RAM Android lebih besar kembali tertutup dialog System UI isn't responding.

Karena itu, login sukses, gabung kelas, dan logout pada emulator dalam sesi ini BELUM terverifikasi. Tidak ditemukan bukti yang cukup untuk menyatakan masalah tersebut berasal dari kode produk; hambatan yang terlihat adalah System UI Android dan ketidakstabilan otomasi input. Resolusi/density emulator yang sempat disesuaikan sudah dikembalikan, lalu emulator QA dihentikan. Pengujian pada HP fisik belum dilakukan.

## Bukti
- class-live-before.json: akun dan kondisi keanggotaan sebelum tes.
- class-live-widget-first-enrollment.log: pendaftaran baru berhasil, dilanjutkan kegagalan selector profil.
- class-live-widget-scroll-before.log: kegagalan pemilihan area gulir sebelum diperbaiki.
- class-live-widget-resume.log: pengujian lanjutan yang lulus hingga logout.
- class-live-database.json: pemeriksaan SQL read-only, 2 → 3 anggota, teskelas tepat 1, pengumpulan 0.
- teacher-class-live-result.json: hasil browser dosen dan jumlah anggota.
- teacher-class-live-dashboard.png dan teacher-class-live-members.png: screenshot browser yang diperiksa visual.
- class-ui-login.png: screenshot login APK normal pada emulator.
- class-live-emulator-current.png dan class-live-emulator-retry-current.png: dialog System UI tidak merespons.
- student-class-live-android.log: runner integrasi yang belum mencapai keberhasilan.
- class-live-analyze.log: hasil analisis kode.

Semua bukti berada dalam docs/evidence. Screenshot website adalah browser nyata; screenshot login/dialog adalah emulator nyata. Tidak ada klaim screenshot dashboard mahasiswa baru dari emulator.

## Berkas, artefak, dan layanan
Perubahan hanya pada .gitignore, alat QA di tools/, tes live di test/live/ dan integration_test/, serta laporan/bukti di folder mobile. Kode produk lib/, kode website, dan kode backend tidak diubah untuk melewatkan tes.

APK normal: D:\Dexa_Assessment_Mobile\build\app\outputs\flutter-apk\app-debug.apk
SHA256: 0a37a3aa2993b012c856a39be646cd233c370328d1b154d412508527857b3a8a

APK pengujian berada dalam .local/artifacts, bukan artefak yang disarankan untuk dibagikan. Backend lokal menjalankan source yang ada dengan konfigurasi autentikasi frontend yang sama; tidak ada perubahan .env. Frontend dev di http://127.0.0.1:3000 dan backend di http://127.0.0.1:3001. Docker/PostgreSQL tetap berjalan.

## Berikutnya
1. Ulangi alur pada emulator yang stabil atau HP fisik; jangan menganggap hasil widget menggantikannya.
2. Jika disetujui sebagai tahap implementasi berikutnya, tambahkan pengumpulan jawaban/upload tugas mobile sesuai kontrak backend, lalu uji sampai kiriman teskelas terlihat di daftar pengumpulan dosen.
