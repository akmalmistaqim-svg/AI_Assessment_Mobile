# Kelas Saya dan Gabung kelas — Dexa Mobile

Tanggal: 29 Oktober 2026. Status: SELESAI untuk implementasi Kelas Saya/Gabung kelas dan verifikasi yang dijelaskan di bawah. APK debug normal berhasil dibuat.

## Alur yang ditambahkan

Masuk sebagai mahasiswa → Kelas Saya → masukkan kode dari dosen → Gabung kelas → daftar kelas diperbarui → buka detail kelas → buka tugas → kembali ke kelas. Beranda menampilkan jumlah kelas aktif. Navigasi menjadi Beranda, Kelas Saya, Informasi, Notifikasi, Profil.

Daftar memuat nama kelas, mata kuliah, dosen, serta penanda kelas arsip. Kode dirapikan dan diubah ke huruf besar mengikuti backend. Sukses hanya berasal dari respons API, lalu kelas dan feed dimuat ulang. Jika penyegaran setelah join gagal, aplikasi tetap mengakui join yang sudah berhasil dan menampilkan retry data, bukan mengulang POST otomatis. Klik ganda dibatasi; respons sesi lama tidak mengubah akun baru.

## Kesamaan dengan website dan batas cakupan

Menggunakan data/keanggotaan PostgreSQL dan kontrak FastAPI yang sama: GET /classes, POST /classes/join dengan enrollmentKey, GET /classes/{id}/assignments. Tidak ada endpoint tiruan dalam aplikasi produksi. DRAFT tidak ditampilkan. Tidak ada perubahan source backend, website, skema, atau seed database.

Kesamaan yang ditambahkan adalah alur keanggotaan kelas dan membaca tugas. Pengumpulan jawaban, scan/AI, seluruh fitur website, dan akses dosen mobile belum termasuk. Status baca pemberitahuan tetap lokal seperti tahap sebelumnya.

## Pengujian

- Suite mobile: 63 lulus, 0 gagal; 2 dari jumlah tersebut merupakan generator preview opsional yang tidak melakukan capture pada run default.
- Kontrak HTTP native ke server uji terisolasi: normalisasi kode, header Bearer, data dosen, tugas non-draft, kode salah, kelas arsip, sudah terdaftar, 401, dan 403.
- Controller/UI: join dari akun tanpa kelas, pemuatan ulang, detail tugas, kembali Android, logout, ketukan ganda, hasil terlambat setelah logout, sesi kedaluwarsa, gagal memuat ulang setelah join berhasil, layar 320dp dengan teks 150%, keyboard, dan retry detail.
- Bug retry detail ditemukan dan diperbaiki: callback setState semula mengembalikan Future; diubah menjadi callback sinkron. Tes tidak dihapus atau dilemahkan. Posisi tab notifikasi pada tes lama diperbarui dari indeks 2 menjadi 3 karena menu kelas ditambahkan.
- Alat capture menggambar widget aplikasi asli dengan Roboto/MaterialIcons dan data uji. Preview di docs/evidence/student-classes-design bukan screenshot emulator dan bukan bukti data akun Ihsan.

## Pemeriksaan backend asli

Backend HTTP localhost:3001 tidak merespons saat verifikasi ulang. Maka tools/verify_class_contract_readonly.py memakai FastAPI TestClient dengan kode aplikasi asli dan PostgreSQL asli yang dipaksa transaction_read_only=on, tanpa server baru atau perubahan backend.

Akun fixture yang sudah ada berhasil login; daftar kelas dan tugas berhasil dibaca. Kode tidak dikenal menghasilkan 404. Bergabung ulang ke kelas fixture yang memang sudah diikuti menghasilkan 400. Jumlah keanggotaan tetap sama. Bukti: docs/evidence/student-classes-backend-contract.json.

Keberhasilan join baru diuji melalui repository/HTTP terisolasi, bukan dengan menambah keanggotaan permanen di database pengguna. Akun Ihsan masih 0 kelas dan belum diuji login karena tidak ada sesi/kredensial yang diberikan. Tidak ada reset password, pembuatan token sendiri, atau penyamaran akun.

## Berkas

lib/student/student_repository.dart, fastapi_student_repository.dart, student_controller.dart, student_app.dart; baru student_class_pages.dart. Tes student_classes_test.dart ditambahkan; tes adapter, navigasi, dan capture diperbarui. README menjelaskan penggunaan dan batasan.

Bukti utama: student-classes-tests-final.log, student-classes-visual-final.log, student-classes-analyze-final.log, student-classes-backend-contract.json di docs/evidence.

## Mencoba menggunakan Ihsan

1. Jalankan backend normal serta PostgreSQL. Runner run_backend_readonly.py sengaja memblokir POST /classes/join dan tidak cocok untuk penggunaan fitur ini.
2. Jalankan/pasang APK terbaru; URL default 10.0.2.2:3001 khusus emulator Android. Perangkat fisik memerlukan konfigurasi alamat backend yang dapat dijangkau.
3. Login sendiri dengan akun Ihsan.
4. Ambil kode kelas Rekayasa Perangkat Lunak A dari dosen/website, lalu isi di Kelas Saya → Gabung kelas.
5. Pastikan kelas dan tugas muncul. Muat ulang website dengan akun yang sama untuk memeriksa keanggotaannya.

Build APK debug normal berhasil (Gradle 107,9 detik), analisis final bersih (5 detik). Setelah perapian ikon, 5 tes kelas dan 1 capture visual dijalankan ulang dan semuanya lulus. Suite lengkap sebelumnya lulus 63/63.

APK: `D:\Dexa_Assessment_Mobile\build\app\outputs\flutter-apk\app-debug.apk`. Ukuran 194,709,489 bytes. SHA256 `0a37a3aa2993b012c856a39be646cd233c370328d1b154d412508527857b3a8a`. Kernel memuat fitur kelas dan endpoint join; marker TestRepository/email fixture tidak ditemukan. Ini pemeriksaan artefak terarah, bukan audit keamanan menyeluruh.

Bukti build: docs/evidence/student-classes-build-final.log; metadata: student-classes-apk-final.json. APK ini belum dipasang/dijalankan ulang di emulator setelah build. Tidak ada klaim pengujian emulator ulang untuk revisi ini atau aplikasi bebas seluruh bug.
