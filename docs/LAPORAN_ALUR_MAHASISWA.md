# Laporan — Alur Mahasiswa Mobile Dexa

> Pembaruan 29 Oktober 2026: APK pada lokasi yang sama sudah diganti oleh revisi desain/login. Metadata dan batas verifikasi terbaru ada di [laporan UI/login](LAPORAN_UI_LOGIN_2026-10-29.md). Hash dan screenshot di bawah merupakan bukti historis sebelum revisi visual.

Implementasi dan pengujian: 28 Oktober 2026. Verifikasi artefak akhir: 29 Oktober 2026. Status: SELESAI untuk lingkup alur mahasiswa ini; analisis kode, tes unit/widget, tes integrasi Android, dan build APK debug normal berhasil.

## Ruang lingkup

Semua perubahan berkas dilakukan di `D:\Dexa_Assessment_Mobile`. Setelah pengguna memberi izin tambahan, kode backend `D:\Dexa_Assessment_Backend\DeXa_Assessment_Backend` dibaca untuk memastikan kontrak API. Tidak ada perubahan source backend, frontend web, migrasi, atau seeding. Server QA sementara memakai backend asli dengan transaksi PostgreSQL read-only.

## Perubahan

- Entry aplikasi utama mengarah ke alur mahasiswa. Demo tahap 2/3 tetap tersedia melalui `lib/main_demo.dart`; kode dan tes lamanya dipertahankan.
- Tampilan masuk, beranda, informasi dan detail, pemberitahuan dan detail, profil, serta dialog keluar. Palet putih, biru langit, dan biru tua; form dan daftar dapat digulir.
- Login memakai email/password melalui `/auth/login`; role mahasiswa diperiksa dan profil diverifikasi lewat `/auth/me`.
- Informasi berasal dari tugas kelas aktif melalui `/classes` dan `/classes/{id}/assignments`. Tugas draft tidak tampil, termasuk bila akun mahasiswa memiliki peran asisten.
- Pemberitahuan berasal dari nilai RELEASED yang masih aktif melalui `/grades`. Tidak ada API pengumuman/notifikasi khusus pada backend saat diperiksa.
- Status baca dipersistenkan per server dan akun di perangkat. Tidak ada push notification atau sinkronisasi status baca antarperangkat.
- Token hanya berada di memori; logout menghapus token, profil, feed, query, filter, dan badge. Respons asynchronous milik sesi lama diabaikan. Login kembali diperlukan setelah aplikasi ditutup penuh.
- Error jaringan, timeout, 401, 403, 429, respons tidak valid, penyimpanan gagal, dan data kosong memiliki keadaan UI yang jelas.

## Berkas utama

- `lib/student/student_repository.dart`: kontrak data dan jenis kegagalan.
- `lib/student/fastapi_student_repository.dart`: HTTP JSON dan Bearer, pemetaan data backend, status baca per akun.
- `lib/student/student_controller.dart`: lifecycle sesi, pemuatan data, filter, badge, dan retry.
- `lib/student/student_app.dart`: antarmuka mahasiswa dan navigasi Android.
- `lib/main.dart`, `lib/main_student.dart`, `lib/main_demo.dart`: entry aplikasi dan demo lama.
- Manifest Android: izin jaringan aplikasi; HTTP hanya di debug untuk backend lokal; label aplikasi Dexa Assessment.
- `pubspec.yaml` / lock: integration_test dari Flutter SDK dan dependensi pengujiannya. Dependency runtime tidak ditambah.
- Tes baru di `test/`, `integration_test/`, `test_driver/`; runner QA di `tools/`.
- README diperbarui dengan kontrak endpoint, langkah menjalankan, dan keterbatasan.

## Pemeriksaan awal dan perbaikan regresi

Baseline sebelumnya tersedia di `LAPORAN_QA_LAYOUT_2026-10-28.md`: 28 tes lama lulus. Folder mobile sebelumnya hanya menggunakan data demo dan belum memiliki kontrak API atau login. Banyak berkas tahap sebelumnya sudah dimodifikasi/untracked; semuanya dipertahankan.

Pada implementasi baru ditemukan tombol kembali Android tidak diteruskan ke navigator dalam. Diperbaiki dengan NavigatorPopHandler dan diuji detail → daftar → beranda. Banner gagal memuat data dibuat ikut menggulir agar tidak overflow ketika keyboard tampil di landscape. Tes scroll juga diperbaiki agar menargetkan daftar yang benar dan menunggu perpindahan viewport; peringatan tap yang tidak mengenai widget dijadikan kegagalan tes.

Tambahan temuan pada pemeriksaan akhir: ikon tab terpilih kurang kontras dan terjadi null access pada profil yang sedang keluar ketika tema dibangun ulang setelah logout. Ikon dibuat biru tua di atas biru langit; tema dibuat sekali per instance aplikasi; halaman yang sedang keluar aman ketika profil sudah dibersihkan. Tes yang semula gagal disimpan sebagai `student-logout-regression-before.log`, dan perbaikannya lulus pada `student-logout-regression-after.log` serta keseluruhan suite final.

## Hasil yang sudah terverifikasi

- `flutter analyze`: tidak ada issue pada source final (14,9 detik).
- `flutter test`: 55 lulus, 0 gagal. Termasuk 28 tes lama, 8 tes HTTP terhadap server loopback terisolasi, dan 19 kasus controller/UI mahasiswa. Satu kasus di antaranya hanya generator preview opsional dan tidak menghasilkan screenshot pada run default.
- Probe API asli: `/health/ready` menyatakan database connected; login fixture mahasiswa berhasil; `/auth/me` cocok dengan akun login; 1 kelas tersedia; 0 nilai dirilis.
- Tidak ada pembuatan nilai atau data fiktif di database demi membuat uji positif terlihat lulus.

Bukti: `docs/evidence/student-all-tests-final.log`, `student-api-tests-initial.log`, `student-analyze-final.log`, dan `student-live-api-probe.json`.

## Batas fitur dan verifikasi

- NIM dan program studi tidak tersedia dalam UserResponse backend; UI menampilkan Belum tersedia, bukan mengarang identitas.
- Akun fixture saat ini belum memiliki nilai yang dirilis. Pembukaan detail pemberitahuan dan perubahan status baca diverifikasi memakai data uji; keadaan kosong diverifikasi terhadap backend asli.
- Endpoint logout backend hanya menghapus cookie browser dan tidak mencabut Bearer token. Mobile menghapus token lokal; tidak mengklaim revokasi server.
- Backend belum memiliki konfigurasi `.env` pada folder yang diberikan. Runner QA memakai secret sementara di memori dan konfigurasi koneksi lokal dari default backend/Compose. Runner QA bukan deployment produksi.
- Pengujian perangkat fisik, release signing, push notification, autentikasi persisten, dan iOS berada di luar pekerjaan ini.
- Tidak ada klaim bahwa aplikasi bebas dari seluruh kemungkinan bug atau bahwa target keseluruhan proyek 50% sudah tercapai.

## Android dan artefak final

Tes integrasi Android final **LULUS** (1 alur utama, sekitar 80 detik setelah tes mulai; angka +2 pada log mencakup teardown framework). APK test yang dijalankan diverifikasi memuat perbaikan tema/logout terkini sebelum dipasang.

Perangkat: emulator `Medium_Phone_API_37.0`, Android 17/API 37, `emulator-5554`. Pengujian memakai Flutter integration_test pada perangkat, bukan menebak dari log startup. Alur yang benar-benar diperiksa: layar masuk → login fixture mahasiswa melalui FastAPI → beranda → daftar informasi → membuka detail tugas asli → kembali → pemberitahuan kosong sesuai database → profil dengan email akun yang sama → konfirmasi logout → kembali ke layar masuk tanpa navigasi akun.

Screenshot asli dari frame aplikasi Android telah diperiksa secara visual. Kontras ikon tab aktif sudah diperbaiki pada screenshot final. Semua file berikut berada di `D:\Dexa_Assessment_Mobile\docs\evidence\student-android`:

- `student-login-android.png`
- `student-home-android.png`
- `student-information-android.png`
- `student-information-detail-android.png`
- `student-notifications-android.png`
- `student-profile-android.png`

Bukti tes final: `docs/evidence/student-live-android.log`. Bukti kelulusan run sebelumnya: `student-live-android-first-pass.log`. Screenshot di `student-preview/` merupakan render widget dengan font tes, bukan bukti tampilan Android final.

Kendala lingkungan yang ditangani: wrapper log Python Windows awalnya gagal pada simbol Unicode; encoding output diperbaiki. Emulator sempat terputus dan package manager belum siap; pemasangan diulang hanya setelah boot selesai dan package manager merespons. Tidak ada penghapusan data emulator, reinstall SDK, perubahan validasi, atau seed database. Kinerja debug emulator dengan software GPU bukan hasil benchmark performa perangkat fisik.

Server QA sementara dan emulator headless yang dibuat untuk tes dihentikan setelah tes final. Docker/PostgreSQL tidak dihentikan. Untuk menggunakan aplikasi lagi, aktifkan backend normal, atau jalankan runner QA read-only dari README. Docker aktif saja belum menjalankan FastAPI.

APK debug normal berhasil dibangun dari entry `lib/main.dart` setelah tes integrasi selesai.

- Lokasi: `D:\Dexa_Assessment_Mobile\build\app\outputs\flutter-apk\app-debug.apk`.
- Ukuran: 194,709,489 bytes.
- SHA256: `908336910ca515ad65c76ee59b2576d563574fca2e68fe720552cde985571f98`.
- Pemeriksaan kernel APK: antarmuka mahasiswa dan perbaikan tema tersedia; judul tes integrasi, email fixture, dan password fixture tidak ditemukan. Ini pemeriksaan artefak terarah, bukan audit keamanan menyeluruh.
- Bukti build: `docs/evidence/student-build-final.log`; metadata: `docs/evidence/student-apk-final.json`.
- APK normal ini belum dijalankan ulang setelah build akhir. Alur Android sebelumnya diuji melalui APK integrasi yang memakai source aplikasi final yang sama.
- Waktu build pada log mencakup jeda lingkungan/host dan tidak digunakan sebagai tolok ukur performa build.
