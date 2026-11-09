# Dexa Assessment Mobile — Alur Mahasiswa

Aplikasi utama sekarang membuka halaman masuk mahasiswa dan membaca data dari FastAPI. Desain memakai putih, biru langit, dan biru tua. Fitur demo tahap sebelumnya tetap tersedia melalui entrypoint terpisah.

## Menjalankan aplikasi utama

```powershell
cd D:\Dexa_Assessment_Mobile
flutter pub get
flutter run -d emulator-5554
```

APK debug secara default memakai `http://10.0.2.2:3001`, yaitu akses emulator Android ke backend host. Backend dan PostgreSQL harus aktif. Untuk server lain:

```powershell
flutter run -d emulator-5554 --dart-define=DEXA_API_BASE_URL=https://api.example.com
flutter build apk --debug
```

URL `api.example.com` di atas hanya contoh, bukan layanan Dexa. Build release memerlukan URL HTTPS eksplisit; tidak ada fallback HTTP di release. Tidak ada fitur web Flutter yang diverifikasi pada tahap ini.

## Fitur dan sumber data

| Bagian | Sumber asli | Perilaku |
| --- | --- | --- |
| Masuk | `POST /auth/login`, JSON email/password | Hanya role `MAHASISWA`; Bearer token disimpan di memori |
| Kelas Saya | `GET /classes` | Kelas terdaftar, mata kuliah, dosen, dan status arsip |
| Gabung kelas | `POST /classes/join`, JSON `enrollmentKey` | Kode dinormalisasi; keberhasilan memuat ulang kelas dan informasi tugas |
| Detail kelas | `GET /classes/{id}/assignments` | Tugas PUBLISHED/CLOSED; tidak menampilkan draft |
| Jawaban tugas | `GET /classes/{classId}/assignments/{assignmentId}` dan `POST .../submissions` | Teks JSON atau multipart `file`; riwayat versi dan nilai yang sudah dirilis |
| Profil | `GET /auth/me` | Nama dan email asli; NIM/program studi belum disediakan API |
| Informasi | `GET /classes` dan `GET /classes/{id}/assignments` | Tugas PUBLISHED/CLOSED dari kelas aktif; DRAFT disaring |
| Pemberitahuan | `GET /grades` | Nilai RELEASED yang masih merupakan revisi nilai aktif |
| Status baca | SharedPreferences mobile | Terpisah berdasarkan server dan akun; tidak tersinkron ke perangkat lain |
| Keluar | Menghapus token dan data sesi lokal | Backend belum memiliki pencabutan Bearer token; token tidak dipersistenkan |

Tidak ada endpoint pengumuman/notifikasi khusus pada backend yang diperiksa. Aplikasi tidak mengarang endpoint maupun data akademik. Pemberitahuan diperbarui ketika data dimuat ulang, bukan push notification. Tugas dapat dibaca dan dijawab melalui mobile, menggunakan teks atau dokumen PDF/DOCX sesuai ketentuan dosen. Data akun dan isi feed tidak dicache ke disk. Aplikasi yang ditutup penuh memerlukan login kembali.

Kondisi gagal jaringan, kredensial salah, rate limit, sesi kedaluwarsa, respons tidak valid, data kosong, dan kegagalan menyimpan status baca ditangani di UI. Respons lama dari akun sebelumnya tidak boleh mengisi sesi baru.

## Alur kelas mahasiswa

Masuk → **Kelas Saya** → isi kode dari dosen → **Gabung kelas** → buka kartu kelas → pilih tugas. Keanggotaan disimpan oleh backend PostgreSQL yang sama sehingga dapat dibaca website. Aplikasi tidak memilih kelas/dosen secara otomatis. Beranda, Kelas Saya, Informasi, Notifikasi, dan Profil menjadi lima tab utama.

**Gabung kelas memerlukan backend normal yang mengizinkan `POST /classes/join`.** Runner `run_backend_readonly.py` hanya untuk QA baca-saja dan sengaja menolak bergabung; jangan memakainya untuk penggunaan fitur ini. Docker/PostgreSQL saja tidak menjalankan FastAPI.

Buka tugas → tulis jawaban atau pilih PDF/DOCX (maksimal 10 MiB) → periksa → kirim. Keberhasilan dikonfirmasi backend; versi aktif dan riwayat dibaca dari sumber yang sama dengan website dosen. Pengiriman versi baru mengikuti tenggat, status tugas, dan status nilai. Tugas khusus SCAN/OCR belum didukung di mobile. Draft yang belum dikirim belum disimpan permanen.

## Pengujian

```powershell
flutter analyze
flutter test
flutter build apk --debug
```

- `test/student_flow_test.dart`: alur akun, navigasi, layout kecil/landscape, dan kondisi gagal memakai repository uji.
- `test/fastapi_student_repository_test.dart`: HTTP nyata ke server loopback terisolasi dengan kontrak FastAPI; tidak mengubah database asli.
- `integration_test/student_live_test.dart`: alur Android terhadap backend nyata dengan akun pengujian. Driver menyimpan screenshot di `docs/evidence/student-android/`.
- Tes demo lama tetap dipertahankan.

Untuk QA lokal khusus akun fixture yang sudah tersedia (script tidak menjalankan seeder):

```powershell
python -B tools/run_backend_readonly.py
# Terminal kedua, backend siap dan emulator aktif:
python -B tools/run_student_live_test.py
```

Runner API QA membaca kode dari `D:\Dexa_Assessment_Backend\DeXa_Assessment_Backend`, memakai secret sementara di memori, memaksa transaksi PostgreSQL read-only, membatasi endpoint mutasi, dan menempatkan output/storage uji di folder mobile. Ini server pengujian sementara, bukan pengganti konfigurasi deployment backend. Jangan menjalankannya bila port 3001 telah dipakai backend lain. Kredensial fixture tidak disimpan dalam source aplikasi atau laporan.

APK normal: `D:\Dexa_Assessment_Mobile\build\app\outputs\flutter-apk\app-debug.apk`. Build ulang APK normal setelah menjalankan integration test agar artefak yang dibagikan bukan build pengujian.

## Demo lama

```powershell
flutter run -t lib/main_demo.dart -d emulator-5554
```

Dokumentasi lama di bawah menjelaskan mode demo tahap 3, bukan alur backend aplikasi utama.

---

# Dexa Assessment Mobile — Tahap 3

Aplikasi mobile Dexa Assessment untuk informasi akademik, simulasi notifikasi dengan penyimpanan status baca lokal persisten, serta fitur pencarian dan penyaringan pengumuman dinamis.

## Ringkasan Fitur Tahap 3

1. **Penyimpanan Lokal Status Baca Notifikasi**:
   - Status baca notifikasi disimpan secara persisten di penyimpanan perangkat menggunakan ID stabil (`notif-1`, `notif-2`).
   - Ketika aplikasi ditutup sepenuhnya (`force stop`) dan dibuka kembali, status baca tetap bertahan dan dipulihkan sebelum tampilan antarmuka di-render sehingga angka ringkasan di Beranda dan badge tab navigasi selalu akurat.
   - Bersifat idempoten: membuka ulang notifikasi yang sudah dibaca tidak memicu simpan ganda dan tidak mengurangi counter dua kali.
   - Concurrency safe: pembaruan beruntun cepat (*rapid updates*) disinkronkan melalui antrean sequential agar tidak saling menimpa.
2. **Pencarian dan Filter Informasi**:
   - Kolom pencarian teks berdasarkan judul, ringkasan, maupun isi lengkap pengumuman.
   - Bersifat tidak peka huruf besar/kecil (*case-insensitive*) dan mengabaikan spasi di awal/akhir (*trimmed*).
   - Filter kategori berbasis chip horizontal dinamis sesuai data pengumuman yang tersedia, dilengkapi pilihan "Semua Kategori".
   - Pencarian dan filter kategori dapat dikombinasikan secara bersamaan.
   - Dilengkapi tombol hapus pencarian (*clear*), indikator jumlah hasil, serta tombol reset filter.
   - Tampilan ramah "Tidak ada informasi yang cocok" saat hasil kosong dengan tombol cepat "Kembali ke Daftar Lengkap".
   - Membuka pengumuman dari hasil pencarian menuju detail yang benar, dan saat kembali kata kunci serta filter tetap utuh.
   - Berpindah tab lalu kembali tetap mempertahankan pencarian/filter selama sesi aplikasi.
   - Ringkasan total pengumuman di Beranda tetap konsisten menghitung data riil (4 informasi aktif), bukan hasil filter.
3. **Penyempurnaan Navigasi Android**:
   - Halaman detail -> tombol kembali mengarahkan ke daftar sebelumnya.
   - Tab selain Beranda -> tombol kembali Android membawa pengguna ke Beranda.
   - Tab Beranda -> tombol kembali Android keluar aplikasi sesuai perilaku standar.

---

## Dependency Baru dan Rasional Pemilihannya

- **`shared_preferences` (versi 2.5.6)**:
  - Dipilih karena merupakan paket resmi (*first-party*) Flutter Team yang paling ringan, stabil, dan teruji untuk penyimpanan pasangan kunci-nilai (*key-value storage*) pada Android (SharedPreferences) dan iOS (NSUserDefaults).
  - Digunakan secara spesifik untuk menyimpan kumpulan ID notifikasi yang telah dibaca (`dexa_read_notification_ids`) tanpa memerlukan database SQL yang berat atau runtime engine tambahan.
  - Arsitektur dibuat dengan abstraksi interface `NotificationStorage` sehingga memisahkan layer penyimpanan dari state aplikasi dan memudahkan pengujian dengan `InMemoryNotificationStorage`.

---

## Data yang Disimpan Lokal dan Batasan Simulasi

- **Data yang Disimpan**: Hanya kumpulan ID unik notifikasi bertipe string (`Set<String>`) yang telah ditandai terbaca. Tidak ada password, token autentikasi, maupun data pribadi (PII) yang disimpan.
- **Penanganan Kegagalan**:
  - Jika data penyimpanan rusak atau tidak valid, aplikasi melakukan fallback aman dengan mengembalikan set kosong tanpa mengalami crash.
  - Jika proses penyimpanan gagal, status tetap diterapkan sementara pada sesi aktif di memori dan banner peringatan ramah pengguna ditampilkan tanpa mengekspos detail teknis sistem.
  - ID tersimpan yang tidak lagi ada dalam data contoh diabaikan secara aman.
- **Batas Simulasi**: Seluruh informasi pengumuman, notifikasi, dan profil tetap merupakan simulasi data lokal bertanda **Mode Demo**. Tidak ada koneksi ke server remote, backend API Dexa, push notification nyata, OCR/scan, maupun fitur AI.

---

## Struktur Kode Aplikasi

```text
lib/
├── main.dart                      # Titik masuk utama & inisialisasi pemulihan state
├── theme/
│   └── app_theme.dart             # Konfigurasi tema resmi Material 3 (Deep Blue & Sky Blue)
├── models/
│   ├── announcement.dart          # Model data pengumuman akademik
│   └── notification_item.dart     # Model data notifikasi dengan status baca
├── data/
│   └── sample_data.dart           # Data contoh lokal bertanda mode demo
├── services/
│   └── notification_storage.dart  # Abstraksi NotificationStorage & SharedPreferencesStorage
├── state/
│   └── app_state.dart             # Pengelola state terpadu (filter, search, read status, tab)
├── widgets/
│   └── demo_badge.dart            # Komponen lencana 'Mode demo' yang dapat digunakan ulang
└── pages/
    ├── main_navigation_page.dart  # Shell navigasi 4 tab dengan IndexedStack & PopScope
    ├── home_page.dart             # Halaman Beranda (ringkasan terhitung & pratinjau)
    ├── announcements_page.dart    # Halaman Informasi (search bar, filter chip, empty view)
    ├── announcement_detail_page.dart # Detail pengumuman & navigasi kembali
    ├── notifications_page.dart    # Halaman Notifikasi (lencana status, error banner)
    ├── notification_detail_page.dart # Detail notifikasi & auto-read
    └── profile_page.dart          # Halaman Profil akun demo & spesifikasi sistem
```

---

## Menjalankan dan Menguji Aplikasi

1. **Jalankan analisis statis kode:**
   ```powershell
   flutter analyze
   ```
2. **Jalankan seluruh pengujian otomatis (15 skenario unit & widget test):**
   ```powershell
   flutter test
   ```
3. **Membangun APK debug:**
   ```powershell
   flutter build apk --debug
   ```
   Berkas keluaran: `build\app\outputs\flutter-apk\app-debug.apk`.
4. **Memasang ke emulator Android:**
   ```powershell
   adb install -r build\app\outputs\flutter-apk\app-debug.apk
   adb shell am start -n com.example.dexa_assessment_mobile/.MainActivity
   ```
## Verifikasi pengumpulan mobile — 1 November 2026

Tes kontrak dan formulir: `test/student_submission_api_test.dart`, `test/student_submission_ui_test.dart`. Tes backend asli bersifat opt-in: `flutter test --dart-define=RUN_LIVE_SUBMISSION_QA=true test/live/student_submission_backend_test.dart`. Tes ini membuat versi jawaban nyata pada tugas QA dan memerlukan konfigurasi privat `.local/`. Pemilih berkas diinjeksi dalam widget test; ini tidak menggantikan verifikasi pemilih dokumen Android.

Laporan dan batas verifikasi: `docs/LAPORAN_PENGUMPULAN_MOBILE_2026-11-01.md`. Konfigurasi kredensial dan berkas QA berada di `.local/` yang diabaikan Git.

## HP fisik melalui Wi-Fi (debug)

APK emulator menggunakan 10.0.2.2; alamat itu tidak menunjuk laptop jika APK dijalankan di HP fisik. Docker menjalankan PostgreSQL, sedangkan FastAPI harus dijalankan terpisah.

1. Sambungkan HP dan laptop ke Wi-Fi yang sama.
2. Dari folder mobile jalankan `powershell -File tools/start_backend_wifi.ps1 -BackendHost <IP_WIFI_LAPTOP>`. Runner bind hanya ke IP itu, tanpa mengubah frontend/backend source.
3. Buka `http://<IP_WIFI_LAPTOP>:3001/health/ready` di browser HP. Ini harus merespons sebelum menguji login aplikasi. Jika tidak, periksa isolasi perangkat pada router atau firewall; jangan menonaktifkan firewall seluruhnya.
4. Buat APK yang sesuai: `powershell -File tools/build_phone_debug.ps1 -BackendHost <IP_WIFI_LAPTOP>`.
5. APK HP tersedia di `build/qa-artifacts/dexa-phone-wifi-arm64-v8a-debug.apk` (ARM64), atau `dexa-phone-wifi-armeabi-v7a-debug.apk` (ARM32). Install sesuai arsitektur HP, lalu gunakan akun mahasiswa backend.

Alamat yang dipakai pada 4 November 2026: `192.168.1.66`. Jika IP Wi-Fi laptop berubah, jalankan backend pada IP baru dan build ulang APK debug. Jangan memakai URL localhost pada HP untuk mengarah ke laptop. Pengaturan ini untuk pengujian lokal. Release tetap memerlukan URL HTTPS dan konfigurasi signing produksi; bukan APK debug ini.

## Menjalankan HP tanpa salah alamat backend (9 November 2026)

`flutter run` tanpa `--dart-define` memakai alamat emulator `10.0.2.2:3001` dan tidak cocok untuk HP fisik. IP Wi-Fi dapat berubah. Jangan hardcode alamat lama di perintah build.

Terminal pertama (biarkan tetap berjalan; Docker harus aktif):

```powershell
cd D:\Dexa_Assessment_Mobile
powershell -File tools/start_backend_wifi.ps1
```

Terminal kedua, jika HP terhubung lewat ADB (USB atau debugging nirkabel):

```powershell
powershell -File tools/run_phone_wifi.ps1
```

Runner mendeteksi IP Wi-Fi laptop, memeriksa readiness/database, lalu meneruskan URL itu ke Flutter. Koneksi aplikasi ke API memakai Wi-Fi, bukan ADB reverse. Jika ada lebih dari satu HP, tambahkan `-DeviceId <id>`.

Tanpa USB/ADB, buat APK untuk dipasang manual di HP:

```powershell
powershell -File tools/run_phone_wifi.ps1 -BuildOnly
```

Salin `build\qa-artifacts\dexa-phone-wifi-arm64-v8a-debug.apk` ke HP dan pasang sebagai pembaruan. HP dan laptop harus pada jaringan yang dapat saling mengakses. Buka URL `/health/ready` yang dicetak runner dari browser HP; harus menampilkan status ready dan database connected. Runner memeriksa sisi laptop; pemeriksaan browser HP tetap diperlukan untuk memastikan jalur Wi-Fi.

Jika IP laptop berganti, ulangi runner backend dan build. Perubahan `--dart-define` memerlukan run/build ulang, bukan hanya hot reload. Docker menjalankan PostgreSQL; FastAPI juga harus tetap aktif. Tampilan warning keyboard/Insets Android bukan bukti bahwa request HTTP berhasil atau gagal.
