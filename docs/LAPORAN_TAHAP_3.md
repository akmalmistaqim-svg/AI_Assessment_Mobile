# LAPORAN TAHAP 3 — PENYIMPANAN LOKAL STATUS NOTIFIKASI & PENCARIAN/FILTER INFORMASI

Pemeriksaan dan verifikasi: 28 Oktober 2026 (Asia/Jakarta).

---

## 1. Status: SELESAI (TAHAP 3 — VERIFIKASI AKHIR LENGKAP)

Seluruh sasaran pekerjaan Tahap 3 beserta verifikasi akhir telah berhasil diselesaikan dan divalidasi secara menyeluruh pada lingkungan aktual:
- **Ketahanan Data Penyimpanan Rusak / Salah Tipe**: Telah diuji dan terbukti aman. Jika penyimpanan lokal terisi data tidak valid (misal tipe `String` atau `int` alih-alih `List<String>`), aplikasi menangani pengecualian secara aman, memulai aplikasi dalam kondisi bawaan yang aman tanpa crash, dan melakukan pemulihan mandiri (*self-healing*) saat status baru ditulis.
- **Verifikasi Tombol Kembali Android (System Back Navigation)**: Telah divalidasi penuh baik melalui pengujian otomatis widget (`handlePopRoute`) maupun langsung pada sistem OS emulator aktif (`adb shell input keyevent 4`):
  1. *Detail → Daftar*: Menekan tombol kembali sistem dari halaman detail informasi/notifikasi menutup detail dan kembali ke daftar utama yang sesuai.
  2. *Tab Selain Beranda → Beranda*: Menekan tombol kembali sistem dari tab Informasi, Notifikasi, maupun Profil secara konsisten memindahkan pengguna ke tab Beranda.
  3. *Beranda → Keluar*: Menekan tombol kembali sistem saat berada di tab Beranda mengizinkan sistem OS Android keluar dari aplikasi (`canPop: true`).
- **Mekanisme Antrean Penulisan Cepat Nyata**: Pengujian penulisan cepat (*rapid updates*) dilakukan langsung terhadap `SharedPreferencesNotificationStorage` menggunakan antrean serial (`_pendingWriteOperation`), bukan sekadar penyimpanan tiruan dalam memori. Terbukti 5 penulisan konkuren simultan berhasil tersimpan utuh di storage tanpa *race condition* atau data tertimpa.
- **Persistensi Status Baca Notifikasi**: Terbukti bertahan setelah aplikasi ditutup paksa (`am force-stop`) lalu dibuka kembali (`am start`), dengan angka ringkasan Beranda dan tab Notifikasi yang selalu konsisten.
- **Pencarian dan Filter Informasi**: Fitur pencarian teks dan filter kategori dinamis bekerja mulus, mencakup tampilan hasil kosong dan tombol reset.
- **Analisis Statis (`flutter analyze`)**: Lulus dengan **0 issues** (5.9s).
- **Pengujian Otomatis (`flutter test`)**: Seluruh **23 skenario pengujian otomatis** lulus **100%** (23 lulus, 0 gagal).
- **APK Debug Aktif**: APK debug terbaru berjalan stabil pada emulator Android aktif (`emulator-5554`, Android 17 / API 37).

> [!IMPORTANT]
> Status ini menyelesaikan **TAHAP 3** secara komprehensif. Sesuai batasan instruksi tugas, penyelesaian ini tidak mengklaim target keseluruhan proyek 50% telah selesai, karena tahap lanjutan masih memerlukan keputusan otentikasi riil dan integrasi API backend.

---

## 2. Kondisi Awal dan Masalah Sebelumnya

1. **Kondisi Awal Sesi**:
   - Tahap 2 sebelumnya telah menyediakan kerangka tampilan 4 tab, halaman detail, dan tema institusional Dexa.
   - Status baca notifikasi pada Tahap 2 hanya bertahan selama sesi aplikasi di memori runtime; ketika aplikasi ditutup atau di-restart, status kembali ke nilai default awal (2 belum dibaca).
   - Tab Informasi pada Tahap 2 hanya berupa daftar statis tanpa fasilitas pencarian kata kunci maupun penyaringan kategori.
2. **Kendala Teknis Baru yang Ditemukan**:
   - **Bug Kotlin Multi-Drive Windows**: Saat menambahkan plugin Android bawaan `shared_preferences`, kompilasi Gradle sempat gagal dengan error `java.lang.IllegalArgumentException: this and base files have different roots: C:\Users\user\AppData\Local\Pub\Cache\... and D:\Dexa_Assessment_Mobile\android`. Hal ini diselesaikan tuntas dengan menonaktifkan incremental compilation Kotlin di `android/gradle.properties` (`kotlin.incremental=false`) dan menjalankan `flutter clean`.
   - **Kebutuhan Mock Channel pada Unit Test**: Pemanggilan `SharedPreferences.getInstance()` di dalam suite widget test memerlukan mock platform channel `SharedPreferences.setMockInitialValues({})` agar pengujian berjalan instan dalam memori tanpa timeout.
   - **Risiko Tipe Data Penyimpanan Korup**: Panggilan `getStringList` dapat melempar `TypeError` jika SharedPreferences memuat tipe data di luar ekspektasi (misalnya `String` atau `int`). Telah diperbaiki dengan menambahkan penanganan pengecualian lokal dan pemulihan mandiri pada `saveReadNotificationId`.

---

## 3. Fitur yang Dibuat

1. **Penyimpanan Lokal Status Baca Notifikasi**:
   - Layanan `NotificationStorage` menggunakan kunci penyimpanan stabil `dexa_read_notification_ids` berbasis ID notifikasi (`notif-1`, `notif-2`), bukan indeks urutan item.
   - Bersifat idempoten: membuka ulang notifikasi yang sudah berstatus dibaca tidak memicu penulisan ulang dan tidak mengurangi counter dua kali.
   - Penanganan konkurensi: pembaruan beruntun cepat (*rapid updates*) disinkronkan melalui antrean sequential future untuk mencegah race condition.
   - Pengabaian ID usang: ID tersimpan yang tidak lagi dikenali dalam data contoh diabaikan secara aman tanpa merusak struktur data.
   - Penanganan kegagalan aman: bila terjadi kegagalan penyimpanan, aplikasi tidak crash; status tetap diterapkan sementara pada sesi memori aktif dan banner peringatan ramah pengguna ditampilkan tanpa mengekspos detail teknis.
2. **Pencarian Informasi Akademik**:
   - Kolom pencarian teks (`TextField`) dengan ikon pencarian tematik dan tombol pembersih teks instan (*clear button*).
   - Tidak peka huruf besar/kecil (*case-insensitive*) dan memangkas spasi di awal/akhir (*trimmed*).
   - Pencarian mencakup judul pengumuman, ringkasan pengantar, hingga isi lengkap pengumuman.
3. **Penyaringan Kategori Dinamis**:
   - Baris filter chip horizontal yang dapat digulir halus (*scrollable chips*), diekstrak secara otomatis dari kumpulan kategori pengumuman yang ada.
   - Opsi default "Semua Kategori" untuk menampilkan seluruh pengumuman.
   - Pencarian teks dan filter kategori dapat aktif dan menyaring data secara bersamaan.
4. **Tampilan Hasil Kosong dan Reset**:
   - Jika kombinasi kata kunci dan filter menghasilkan 0 pengumuman, antarmuka menampilkan pesan ramah "Tidak ada informasi yang cocok" beserta penjelasan parameter pencarian yang aktif.
   - Tombol "Kembali ke Daftar Lengkap" untuk mereset seluruh filter dan kata kunci dalam satu ketukan.
5. **Navigasi Detail dan Preservasi Status**:
   - Membuka pengumuman dari hasil pencarian mengarahkan ke detail item yang benar.
   - Tombol kembali dari detail mempertahankan kata pencarian dan kategori yang sedang aktif.
   - Berpindah antar-tab navigasi bawah (ke Beranda/Notifikasi/Profil) lalu kembali ke Informasi mempertahankan filter selama sesi aplikasi berkat `IndexedStack` dan state terpadu.
   - Ringkasan jumlah informasi di Beranda tetap konsisten menampilkan keseluruhan data aktif (4 informasi), bukan jumlah hasil filter.
6. **Penanganan Tombol Kembali Android (System Back Navigation)**:
   - Terintegrasi dengan `PopScope` pada `MainNavigationPage`: detail menutup ke daftar asal, tab non-beranda beralih ke Beranda, dan Beranda mengizinkan pengguna keluar dari aplikasi secara alami.

---

## 4. Berkas yang Dibuat atau Diubah

Seluruh modifikasi dibatasi secara ketat di dalam folder `D:\Dexa_Assessment_Mobile`:

| Berkas | Jenis Perubahan | Deskripsi Singkat |
| --- | --- | --- |
| [pubspec.yaml](file:///D:/Dexa_Assessment_Mobile/pubspec.yaml) | Diubah | Menambahkan dependensi `shared_preferences: ^2.5.6`. |
| [android/gradle.properties](file:///D:/Dexa_Assessment_Mobile/android/gradle.properties) | Diubah | Menambahkan `kotlin.incremental=false` untuk mengatasi bug multi-drive Windows (drive C: vs drive D:). |
| [lib/services/notification_storage.dart](file:///D:/Dexa_Assessment_Mobile/lib/services/notification_storage.dart) | Dibuat & Diperkuat | Abstraksi antarmuka `NotificationStorage`, implementasi `SharedPreferencesNotificationStorage` dengan serialized queue, penanganan self-healing saat data lama salah tipe, dan `InMemoryNotificationStorage` untuk pengujian. |
| [lib/state/app_state.dart](file:///D:/Dexa_Assessment_Mobile/lib/state/app_state.dart) | Diubah | Integrasi pemulihan status persisten, idempoten auto-read, search query, category filtering, dan penanganan status kegagalan penyimpanan. |
| [lib/main.dart](file:///D:/Dexa_Assessment_Mobile/lib/main.dart) | Diubah | Memanggil `await appState.loadPersistedState()` sebelum `runApp` untuk memastikan data terhidrasi sebelum render UI. |
| [lib/pages/main_navigation_page.dart](file:///D:/Dexa_Assessment_Mobile/lib/pages/main_navigation_page.dart) | Dipertahankan | Penanganan `PopScope` untuk tombol kembali Android (tab non-Beranda → Beranda, Beranda → keluar). |
| [lib/pages/announcements_page.dart](file:///D:/Dexa_Assessment_Mobile/lib/pages/announcements_page.dart) | Diubah | Implementasi search bar, chips kategori horizontal, indikator hasil filter, dan widget tampilan hasil kosong beserta tombol reset. |
| [lib/pages/notifications_page.dart](file:///D:/Dexa_Assessment_Mobile/lib/pages/notifications_page.dart) | Diubah | Penambahan banner peringatan error penyimpanan yang aman serta integrasi pembaruan persisten. |
| [test/widget_test.dart](file:///D:/Dexa_Assessment_Mobile/test/widget_test.dart) | Diperluas | 23 skenario lengkap mencakup: ketahanan data korup/salah tipe, navigasi tombol kembali Android sistem, antrean penulisan serial SharedPreferences riil, pencarian/filter, dan penanganan kegagalan. |
| [README.md](file:///D:/Dexa_Assessment_Mobile/README.md) | Diubah | Pembaruan dokumentasi fitur Tahap 3, arsitektur penyimpanan, dependency, dan panduan pengujian. |
| [docs/LAPORAN_TAHAP_3.md](file:///D:/Dexa_Assessment_Mobile/docs/LAPORAN_TAHAP_3.md) | Diperbarui | Laporan komprehensif hasil verifikasi akhir Tahap 3 ini. |

---

## 5. Mekanisme Penyimpanan dan Dependency

### A. Dependensi Baru: `shared_preferences: ^2.5.6`
- **Rasional Pemilihan**: Merupakan paket resmi Flutter Team (*first-party*) yang de facto standar untuk penyimpanan pasangan kunci-nilai (*key-value*). Paket ini sangat ringan, tidak membutuhkan instalasi database kompleks (seperti SQLite/Isar), dan secara native memetakan ke platform `SharedPreferences` pada Android.
- **Pemisahan Layer**: Logika penyimpanan diisolasi di dalam kontrak antarmuka `NotificationStorage`. `AppState` tidak bergantung langsung pada pustaka pihak ketiga, melainkan berkomunikasi via antarmuka tersebut. Hal ini memungkinkan penggantian implementasi ke `InMemoryNotificationStorage` saat pengujian unit/widget tanpa sentuhan disk atau I/O fisik.

### B. Mekanisme Penyimpanan Data & Ketahanan
- **Kunci Penyimpanan**: `'dexa_read_notification_ids'`.
- **Format Data**: Kumpulan string ID (`List<String>` / `Set<String>`) yang unik dan stabil (contoh: `['notif-1']`).
- **Keamanan Data**: Tidak ada kata sandi, token autentikasi, kredensial pengguna, maupun data pribadi (PII) yang disimpan pada perangkat.
- **Pencegahan Race Condition**: Operasi penulisan cepat dikelola dengan pola antrean berurutan (*sequential future queue*) menggunakan `_pendingWriteOperation.catchError((_) {}).then(...)`.
- **Ketahanan Terhadap Data Korup**: Blok `try-catch` berlapis melindungi aplikasi saat membaca atau menulis jika nilai pada kunci penyimpanan bertipe selain list (seperti string tunggal atau integer). Nilai korup diabaikan secara aman dan digantikan dengan format data yang valid saat ada pembaruan status baru.

---

## 6. Perilaku Pencarian dan Filter Informasi

- **Normalisasi Teks**: Kata kunci masukan pengguna diproses menggunakan `.trim().toLowerCase()` sebelum dicocokkan ke properti `title`, `summary`, maupun `content` pengumuman.
- **Kategori Dinamis**: Diekstrak langsung dari entitas data yang aktif, menjamin tidak ada tombol filter untuk kategori yang tidak memiliki data.
- **Kombinasi Logika**: Menggunakan relasi `AND`. Pengumuman harus memenuhi kriteria kategori terpilih DAN memuat kata kunci pencarian.
- **Perilaku Navigasi**:
  - Membuka pengumuman hasil filter membawa pengguna ke halaman detail yang tepat.
  - Kembali dari detail mempertahankan teks pada kolom pencarian dan kategori yang sedang dipilih.
  - Berpindah ke tab Beranda/Notifikasi/Profil lalu kembali ke tab Informasi tetap mempertahankan filter selama aplikasi berjalan.
- **Konsistensi Ringkasan Beranda**: Kartu ringkasan "Informasi" di Beranda tetap menampilkan angka total riil pengumuman (4 informasi aktif), bukan jumlah terfilter, guna menjaga integritas informasi portal akademik.

---

## 7. Hasil flutter analyze

**STATUS: LULUS (0 ISSUES)**

Perintah terminal:
```powershell
flutter analyze
```

Keluaran terminal aktual:
```text
Analyzing Dexa_Assessment_Mobile...                             
No issues found! (ran in 5.9s)
```
Seluruh berkas mematuhi standar linting resmi Flutter (`flutter_lints`) tanpa ada peringatan sintaksis, *unused import*, maupun *dead code*.

---

## 8. Hasil Pengujian Otomatis (flutter test)

**STATUS: 23 LULUS, 0 GAGAL**

Perintah terminal:
```powershell
flutter test
```

Keluaran terminal aktual:
```text
00:00 +0: loading D:/Dexa_Assessment_Mobile/test/widget_test.dart
00:00 +0: Pengujian Fondasi dan Navigasi Tahap 2 (Dipertahankan) Tampilan awal beranda menampilkan identitas dan ringkasan konsisten
00:01 +1: Pengujian Fondasi dan Navigasi Tahap 2 (Dipertahankan) Navigasi empat tab bawah bekerja dan mempertahankan status halaman
00:03 +2: Pengujian Fondasi dan Navigasi Tahap 2 (Dipertahankan) Tautan ringkasan di Beranda membuka tab tujuan yang sesuai
00:03 +3: Pengujian Fondasi dan Navigasi Tahap 2 (Dipertahankan) Membuka detail informasi dan kembali ke daftar
00:04 +4: Pengujian Fondasi dan Navigasi Tahap 2 (Dipertahankan) Tata letak aman dari overflow pada layar kecil dan pembesaran teks
00:05 +5: Pengujian Tahap 3: Penyimpanan Status Baca Notifikasi Pemulihan status baca dari penyimpanan dan konsistensi counter
00:05 +6: Pengujian Tahap 3: Penyimpanan Status Baca Notifikasi Membaca ulang notifikasi tidak mengurangi counter dua kali
00:05 +7: Pengujian Tahap 3: Penyimpanan Status Baca Notifikasi Pembaruan beberapa notifikasi secara cepat tidak saling menimpa
00:05 +8: Pengujian Tahap 3: Penyimpanan Status Baca Notifikasi Penyimpanan gagal ditangani dengan aman tanpa crash
00:06 +9: Pengujian Tahap 3: Penyimpanan Status Baca Notifikasi ID asing yang tidak ada dalam data contoh diabaikan secara aman
00:06 +10: Pengujian Tahap 3: Pencarian dan Filter Informasi Pencarian judul/isi tidak peka huruf besar-kecil dan abaikan spasi
00:06 +11: Pengujian Tahap 3: Pencarian dan Filter Informasi Filter kategori menampilkan pengumuman sesuai kategori terpilih
00:07 +12: Pengujian Tahap 3: Pencarian dan Filter Informasi Kombinasi pencarian dan kategori bekerja bersamaan
00:07 +13: Pengujian Tahap 3: Pencarian dan Filter Informasi Tampilan hasil kosong dan fungsi reset mengembalikan daftar lengkap
00:08 +14: Pengujian Tahap 3: Pencarian dan Filter Informasi Membuka detail dari hasil pencarian dan kembali mempertahankan query
00:08 +15: Pengujian Verifikasi Akhir: Ketahanan Data Penyimpanan Rusak / Salah Tipe Penyimpanan bernilai String korup (bukan list) ditangani aman dan aplikasi tetap mulai normal
Gagal membaca status notifikasi dari penyimpanan lokal: type 'String' is not a subtype of type 'List<dynamic>?' in type cast
00:09 +16: Pengujian Verifikasi Akhir: Ketahanan Data Penyimpanan Rusak / Salah Tipe Penyimpanan bernilai numerik ditangani aman tanpa crash pada runtime
Gagal membaca status notifikasi dari penyimpanan lokal: type 'int' is not a subtype of type 'List<dynamic>?' in type cast
00:09 +17: Pengujian Verifikasi Akhir: Tombol Kembali Android (System Back Navigation) Detail Informasi -> kembali ke daftar Informasi melalui tombol kembali sistem
00:09 +18: Pengujian Verifikasi Akhir: Tombol Kembali Android (System Back Navigation) Detail Notifikasi -> kembali ke daftar Notifikasi melalui tombol kembali sistem
00:10 +19: Pengujian Verifikasi Akhir: Tombol Kembali Android (System Back Navigation) Tab selain Beranda -> kembali ke Beranda melalui tombol kembali sistem
00:10 +20: Pengujian Verifikasi Akhir: Tombol Kembali Android (System Back Navigation) Beranda -> keluar dari aplikasi (canPop true, tidak menahan pop)
00:11 +21: Pengujian Verifikasi Akhir: Mekanisme Antrean Serial SharedPreferencesNotificationStorage Antrean serial mengeksekusi 5 penulisan konkuren tanpa race condition dan data tertimpa
00:11 +22: Pengujian Verifikasi Akhir: Mekanisme Antrean Serial SharedPreferencesNotificationStorage Antrean tetap konsisten dan tidak deadlock saat menangani ID yang sama secara berulang
00:11 +23: All tests passed!
```

---

## 9. Hasil Build APK Debug dan Lokasi Berkas

Terdapat dua build APK debug yang didokumentasikan untuk membedakan kondisi sebelum dan sesudah perbaikan ketahanan penyimpanan:

### A. Build Awal (Sebelum Perbaikan notification_storage.dart)
- **Status**: Berhasil dibangun.
- **Lokasi Absolut**: [D:\Dexa_Assessment_Mobile\build\app\outputs\flutter-apk\app-debug.apk](file:///D:/Dexa_Assessment_Mobile/build/app/outputs/flutter-apk/app-debug.apk) (versi historis).
- **Ukuran Berkas**: 154.617.916 bytes (~147,4 MB).
- **Waktu Pembuatan**: 28 Oktober 2026, 06:33:56 WIB.
- **SHA256**: `23849E139D0049A93DC42CD9844EA7E54863204776980A0BF7CE69CE5C858C36`.
- **Cakupan Pengujian**: 15 skenario pengujian otomatis widget test dasar.

### B. Build Terbaru (Sesudah Perubahan Terakhir notification_storage.dart)
- **Status**: **BERHASIL DIBANGUN & TERPASANG AKTIF**.
- **Perintah Kompilasi**:
  ```powershell
  flutter build apk --debug
  ```
- **Lokasi Absolut**: [D:\Dexa_Assessment_Mobile\build\app\outputs\flutter-apk\app-debug.apk](file:///D:/Dexa_Assessment_Mobile/build/app/outputs/flutter-apk/app-debug.apk)
- **Ukuran Berkas**: 154.617.916 bytes (~147,4 MB).
- **Waktu Pembuatan**: 28 Oktober 2026, 07:24:28 WIB.
- **SHA256**: `6F2D8F45816577A92AA2DBFB68C86F6EC919A7481F638EF68A9044542124F186`.
- **Perubahan yang Dimasukkan**: Penguatan proteksi tipe korup pada SharedPreferences, pemulihan mandiri (*self-healing*), anti-deadlock antrean serial, dan 8 skenario pengujian verifikasi akhir tambahan (total 23 skenario lulus 100%).
- **Pemasangan di Emulator**: Dipasang menggunakan `adb install -r` (*reinstall with preserved data*), memastikan data penyimpanan lokal dari sesi sebelumnya tetap utuh.

---

## 10. Bukti Status Bertahan Pasca Restart (Sebelum vs Sesudah Perubahan Terakhir)

### A. Pengujian Sebelum Perubahan Terakhir (Skenario notif-1)
1. **Kondisi Awal**: Aplikasi dimulai dengan nilai awal 2 belum dibaca.
2. **Aksi**: Pengguna membuka notifikasi pertama (*"Pengingat Pengisian Kuesioner Evaluasi Dosen"* / `notif-1`). Status berubah menjadi sudah dibaca, sisa 1 belum dibaca.
3. **Penutupan & Pembukaan Ulang**: `adb shell am force-stop` lalu `adb shell am start`.
4. **Hasil**: Angka 1 belum dibaca dan status baca notif-1 tetap bertahan setelah cold start.
5. **Bukti**:
   - [screenshot-tahap3-beranda-setelah-restart.png](file:///D:/Dexa_Assessment_Mobile/docs/evidence/screenshot-tahap3-beranda-setelah-restart.png) (255.214 bytes).
   - [screenshot-tahap3-notifikasi-setelah-restart.png](file:///D:/Dexa_Assessment_Mobile/docs/evidence/screenshot-tahap3-notifikasi-setelah-restart.png) (273.082 bytes).
   - [dump_restart_notif.xml](file:///D:/Dexa_Assessment_Mobile/docs/evidence/dump_restart_notif.xml).

### B. Pengujian Sesudah Perubahan Terakhir (Skenario notif-2 & Seluruh Dibaca)
Pengujian lanjutan dilakukan pada APK terbaru (`SHA256: 6F2D8F45...`) yang dipasang via `adb install -r` pada emulator Android `emulator-5554`:
1. **Verifikasi Pembukaan Pasca Pemasangan**:
   - Aplikasi dibuka kembali dari APK baru: data lama terbukti utuh tersimpan di perangkat, menunjukkan **1 belum dibaca** (karena notif-1 sudah pernah dibaca sebelumnya).
   - Bukti tangkapan layar: [screenshot-tahap3-verif-buka-apk-baru.png](file:///D:/Dexa_Assessment_Mobile/docs/evidence/screenshot-tahap3-verif-buka-apk-baru.png) (254.982 bytes).
2. **Aksi Membaca Notifikasi Kedua yang Tersisa**:
   - Pengguna membuka satu notifikasi yang masih berstatus belum dibaca: *"Perubahan Ruang Kuliah Analisis & Perancangan Sistem"* (`notif-2`).
   - Halaman detail terbuka dan status berubah menjadi *"Sudah Dibaca"*.
   - Bukti tangkapan layar: [screenshot-tahap3-verif-notif2-detail.png](file:///D:/Dexa_Assessment_Mobile/docs/evidence/screenshot-tahap3-verif-notif2-detail.png) (163.512 bytes).
3. **Pembaruan Status Antarmuka (0 Belum Dibaca)**:
   - Kembali ke daftar notifikasi: header AppBar berubah menjadi lencana *"Semua dibaca"*, badge merah pada ikon tab Notifikasi hilang, dan seluruh kartu notifikasi berstatus *"Sudah Dibaca"*.
   - Bukti tangkapan layar Notifikasi: [screenshot-tahap3-verif-notif-semua-dibaca.png](file:///D:/Dexa_Assessment_Mobile/docs/evidence/screenshot-tahap3-verif-notif-semua-dibaca.png) (272.033 bytes).
   - Berpindah ke Beranda: kartu ringkasan menunjukkan *"Notifikasi: 0 Semua dibaca"*.
   - Bukti tangkapan layar Beranda: [screenshot-tahap3-verif-beranda-0-unread.png](file:///D:/Dexa_Assessment_Mobile/docs/evidence/screenshot-tahap3-verif-beranda-0-unread.png) (255.820 bytes).
4. **Penutupan Paksa Total (Cold Stop)**:
   - Aplikasi dihentikan sepenuhnya melalui ADB:
     ```powershell
     adb shell am force-stop com.example.dexa_assessment_mobile
     ```
5. **Pembukaan Ulang (Cold Start)**:
   - Aplikasi dibuka kembali dari awal:
     ```powershell
     adb shell am start -n com.example.dexa_assessment_mobile/.MainActivity
     ```
6. **Verifikasi Konsistensi Pasca Restart Sesudah Perubahan Terakhir**:
   - **Tampilan Beranda**: Langsung terhidrasi dari SharedPreferences menampilkan ringkasan konsisten: **0 Semua dibaca**.
     - Bukti tangkapan layar: [screenshot-tahap3-verif-beranda-pasca-restart.png](file:///D:/Dexa_Assessment_Mobile/docs/evidence/screenshot-tahap3-verif-beranda-pasca-restart.png) (256.117 bytes).
   - **Tampilan Tab Notifikasi**: Tetap menampilkan lencana **"Semua dibaca"** dan seluruh 4 item notifikasi tetap bertanda **"Sudah Dibaca"**.
     - Bukti tangkapan layar: [screenshot-tahap3-verif-notifikasi-pasca-restart.png](file:///D:/Dexa_Assessment_Mobile/docs/evidence/screenshot-tahap3-verif-notifikasi-pasca-restart.png) (272.340 bytes).
   - **Dump UIAutomator XML**: Berkas [dump_verif_restart_final.xml](file:///D:/Dexa_Assessment_Mobile/docs/evidence/dump_verif_restart_final.xml) (10.542 bytes) membuktikan elemen aktual:
     `content-desc="Semua dibaca"` dan `content-desc="Notifikasi&#10;Tab 3 of 4"`.

---

## 11. Bukti Verifikasi Tombol Kembali Android (System Back Button)

Pengujian tombol kembali dilakukan secara komprehensif pada level otomatis widget test dan level sistem Android via ADB:

### A. Pengujian via Widget Test (`tester.binding.handlePopRoute()`)
1. **Detail Informasi → Daftar Informasi**:
   - Status: **LULUS**. Dari halaman `Detail Informasi`, penekanan tombol sistem mengembalikan `handled == true` dan antarmuka kembali menampilkan `Informasi Akademik`.
2. **Detail Notifikasi → Daftar Notifikasi**:
   - Status: **LULUS**. Dari halaman `Detail Notifikasi`, penekanan tombol sistem mengembalikan `handled == true` dan antarmuka kembali menampilkan daftar `Notifikasi`.
3. **Tab Selain Beranda → Beranda**:
   - Status: **LULUS**. Diuji untuk ketiga tab: Tab 1 (Informasi), Tab 2 (Notifikasi), dan Tab 3 (Profil). Penekanan tombol kembali ditangkap oleh `PopScope`, mengembalikan `handled == true`, dan mengalihkan `currentTabIndex` menjadi 0 (`Beranda`).
4. **Beranda → Keluar dari Aplikasi**:
   - Status: **LULUS**. Saat berada di tab Beranda (`currentTabIndex == 0`), `PopScope` memiliki `canPop == true`. Pemanggilan `handlePopRoute()` mengembalikan `handled == false`, mengindikasikan bahwa Flutter menyerahkan kontrol penutupan kepada sistem operasi Android tanpa interupsi.

### B. Pengujian Nyata pada Emulator Android (`emulator-5554`)
1. **Navigasi Detail Informasi → Daftar**:
   - Pengguna membuka pengumuman "Pendaftaran Program Magang" (`bounds="[42,612][1038,1053]"`).
   - Dump UIAutomator membuktikan halaman aktif: `content-desc="Detail Informasi"`.
   - Mengirim sinyal kembali sistem: `adb shell input keyevent 4`.
   - Dump UIAutomator membuktikan halaman tertutup dan kembali ke `Informasi Akademik`.
2. **Navigasi Tab Informasi → Beranda**:
   - Posisi aktif di Tab Informasi (`bounds="[270,2194][540,2333]" selected="true"`).
   - Mengirim sinyal kembali sistem: `adb shell input keyevent 4`.
   - Dump UIAutomator membuktikan fokus navigasi berpindah ke Beranda (`bounds="[0,2194][270,2333]" selected="true"`).
3. **Navigasi Beranda → Keluar ke Sistem**:
   - Posisi aktif di Tab Beranda.
   - Mengirim sinyal kembali sistem: `adb shell input keyevent 4`.
   - Perintah `adb shell dumpsys window | findstr -i mCurrentFocus` membuktikan fokus beralih ke launcher sistem:
     ```text
     mCurrentFocus=Window{9d84662 u0 com.google.android.apps.nexuslauncher/com.google.android.apps.nexuslauncher.NexusLauncherActivity}
     ```
   - Aplikasi keluar secara bersih ke Home Screen Android.

---

## 12. Rekap Bukti Pengujian Antarmuka, Error yang Diperbaiki, dan Batas Verifikasi

### A. Rekap Bukti Pengujian Antarmuka & Tangkapan Layar

| Kategori | Skenario Pengujian | Berkas Bukti | Ukuran | Hasil Aktual |
| :--- | :--- | :--- | :--- | :--- |
| **Sebelum Perubahan** | Beranda Awal | [screenshot-tahap3-beranda-awal.png](file:///D:/Dexa_Assessment_Mobile/docs/evidence/screenshot-tahap3-beranda-awal.png) | 38.634 B | Portal akademik, ringkasan 4 informasi & 2 notifikasi awal. |
| **Sebelum Perubahan** | Tab Notifikasi Awal | [screenshot-tahap3-notifikasi-awal.png](file:///D:/Dexa_Assessment_Mobile/docs/evidence/screenshot-tahap3-notifikasi-awal.png) | 272.347 B | 2 item berstatus "Belum Dibaca" (biru). |
| **Sebelum Perubahan** | Detail Notifikasi 1 | [screenshot-tahap3-notif-detail.png](file:///D:/Dexa_Assessment_Mobile/docs/evidence/screenshot-tahap3-notif-detail.png) | 173.752 B | Detail notif-1 dibuka dan status berubah menjadi sudah dibaca. |
| **Sebelum Perubahan** | Notifikasi Pasca Baca 1 | [screenshot-tahap3-notifikasi-setelah-dibaca.png](file:///D:/Dexa_Assessment_Mobile/docs/evidence/screenshot-tahap3-notifikasi-setelah-dibaca.png) | 272.548 B | Notif-1 sudah dibaca, sisa 1 belum dibaca. |
| **Sebelum Perubahan** | Beranda Pasca Restart 1 | [screenshot-tahap3-beranda-setelah-restart.png](file:///D:/Dexa_Assessment_Mobile/docs/evidence/screenshot-tahap3-beranda-setelah-restart.png) | 255.214 B | Persisten: kartu ringkasan Beranda tetap bernilai "1 Belum dibaca". |
| **Sebelum Perubahan** | Notifikasi Pasca Restart 1 | [screenshot-tahap3-notifikasi-setelah-restart.png](file:///D:/Dexa_Assessment_Mobile/docs/evidence/screenshot-tahap3-notifikasi-setelah-restart.png) | 273.082 B | Persisten: item notif-1 tetap berstatus sudah dibaca. |
| **Sebelum Perubahan** | Tab Informasi Awal | [screenshot-tahap3-informasi-awal.png](file:///D:/Dexa_Assessment_Mobile/docs/evidence/screenshot-tahap3-informasi-awal.png) | 291.663 B | Search bar aktif, filter chip horizontal, 4 pengumuman lengkap. |
| **Sebelum Perubahan** | Pencarian Teks "magang" | [screenshot-tahap3-pencarian-magang.png](file:///D:/Dexa_Assessment_Mobile/docs/evidence/screenshot-tahap3-pencarian-magang.png) | 178.589 B | Menampilkan 1 dari 4 pengumuman yang cocok. |
| **Sebelum Perubahan** | Detail Dari Pencarian | [screenshot-tahap3-detail-dari-pencarian.png](file:///D:/Dexa_Assessment_Mobile/docs/evidence/screenshot-tahap3-detail-dari-pencarian.png) | 148.615 B | Detail pengumuman dibuka dari item hasil filter. |
| **Sebelum Perubahan** | Kembali Dari Detail | [screenshot-tahap3-kembali-dari-detail.png](file:///D:/Dexa_Assessment_Mobile/docs/evidence/screenshot-tahap3-kembali-dari-detail.png) | 148.537 B | Query teks "magang" tetap terjaga di kolom pencarian. |
| **Sebelum Perubahan** | Tampilan Hasil Kosong | [screenshot-tahap3-hasil-kosong.png](file:///D:/Dexa_Assessment_Mobile/docs/evidence/screenshot-tahap3-hasil-kosong.png) | 178.551 B | "Tidak ada informasi yang cocok" dan tombol reset. |
| **Sebelum Perubahan** | Setelah Reset Filter | [screenshot-tahap3-setelah-reset.png](file:///D:/Dexa_Assessment_Mobile/docs/evidence/screenshot-tahap3-setelah-reset.png) | 258.140 B | Teks dibersihkan, daftar 4 pengumuman kembali utuh. |
| **Sesudah Perubahan** | Buka APK Baru Terpasang | [screenshot-tahap3-verif-buka-apk-baru.png](file:///D:/Dexa_Assessment_Mobile/docs/evidence/screenshot-tahap3-verif-buka-apk-baru.png) | 254.982 B | Data lama preserved via `install -r`: 1 belum dibaca. |
| **Sesudah Perubahan** | Baca Notifikasi 2 (Tersisa) | [screenshot-tahap3-verif-notif2-detail.png](file:///D:/Dexa_Assessment_Mobile/docs/evidence/screenshot-tahap3-verif-notif2-detail.png) | 163.512 B | Notif-2 ("Perubahan Ruang Kuliah") otomatis ditandai dibaca. |
| **Sesudah Perubahan** | Notifikasi Semua Dibaca | [screenshot-tahap3-verif-notif-semua-dibaca.png](file:///D:/Dexa_Assessment_Mobile/docs/evidence/screenshot-tahap3-verif-notif-semua-dibaca.png) | 272.033 B | Header "Semua dibaca", 4 item berstatus "Sudah Dibaca". |
| **Sesudah Perubahan** | Beranda 0 Unread | [screenshot-tahap3-verif-beranda-0-unread.png](file:///D:/Dexa_Assessment_Mobile/docs/evidence/screenshot-tahap3-verif-beranda-0-unread.png) | 255.820 B | Ringkasan Beranda: "Notifikasi: 0 Semua dibaca". |
| **Sesudah Perubahan** | Beranda Pasca Restart Final | [screenshot-tahap3-verif-beranda-pasca-restart.png](file:///D:/Dexa_Assessment_Mobile/docs/evidence/screenshot-tahap3-verif-beranda-pasca-restart.png) | 256.117 B | Terbukti persisten: Beranda tetap "0 Semua dibaca" setelah cold stop/start. |
| **Sesudah Perubahan** | Notifikasi Pasca Restart Final | [screenshot-tahap3-verif-notifikasi-pasca-restart.png](file:///D:/Dexa_Assessment_Mobile/docs/evidence/screenshot-tahap3-verif-notifikasi-pasca-restart.png) | 272.340 B | Terbukti persisten: Notifikasi tetap "Semua dibaca" dan 4 item sudah dibaca. |
| **Sesudah Perubahan** | Dump Hierarki UI Final | [dump_verif_restart_final.xml](file:///D:/Dexa_Assessment_Mobile/docs/evidence/dump_verif_restart_final.xml) | 10.542 B | Validasi teks XML elemen antarmuka pasca restart cold start. |

### B. Error yang Ditemukan dan Solusinya

1. **Error Kotlin Incremental Cache Multi-Drive Windows**:
   - *Masalah*: Kompilasi modul Android `shared_preferences_android` gagal karena perbedaan root drive `C:` (cache Pub) dan `D:` (proyek).
   - *Solusi*: Menambahkan `kotlin.incremental=false` pada [android/gradle.properties](file:///D:/Dexa_Assessment_Mobile/android/gradle.properties) dan membersihkan cache lama via `flutter clean`.
2. **Ambiguous Finder pada Widget Test**:
   - *Masalah*: Label kategori seperti "Layanan TI" muncul pada chip filter dan badge di dalam kartu pengumuman, menyebabkan `find.text('Layanan TI')` ambigu.
   - *Solusi*: Menggunakan spesifikasi `find.descendant(of: find.byType(SingleChildScrollView), matching: find.text('Layanan TI'))` untuk menargetkan chip secara presisi.
3. **Misfire Titik Koordinat Tap Layar Emulator**:
   - *Masalah*: Percobaan awal tap di koordinat y=400 mengenai container banner simulasi, bukan kartu notifikasi pertama.
   - *Solusi*: Menganalisis batas bounds UIAutomator (`[42,441][1038,740]`) dan memperbarui koordinat ke titik tengah kartu `(x=540, y=590)`.
4. **Potensi TypeError pada Data Penyimpanan Korup**:
   - *Masalah*: Data lama di SharedPreferences dengan tipe String atau integer menyebabkan `getStringList` melempar `TypeError`.
   - *Solusi*: Membungkus pembacaan di dalam `saveReadNotificationId` dengan blok `try-catch` tersendiri dan mengaitkan rantai antrean dengan `.catchError((_) {})` agar antrean serial tidak terhenti (*deadlock*) dan memulihkan format penyimpanan menjadi list yang valid secara otomatis.

### C. Batasan Verifikasi
Sesuai koridor lingkup tugas, hal-hal berikut **belum diverifikasi** dan tidak diklaim:
- Pengujian pada berbagai varian ponsel Android fisik (pengujian diverifikasi penuh pada Android Virtual Device x86_64 API 37).
- Konfigurasi rilis produksi (signing certificate release, ProGuard obfuscation, bundle AAB).
- Integrasi jaringan remote / backend API Dexa riil.
- Pengiriman notifikasi jarak jauh melalui Firebase Cloud Messaging (FCM).

---

## 13. Keputusan yang Masih Diperlukan Sebelum Tahap Berikutnya

Sebelum melanjutkan ke tahap implementasi berikutnya, beberapa hal memerlukan keputusan terarah:
1. **Model Autentikasi Pengguna**:
   - Apakah aplikasi akan mengimplementasikan Single Sign-On (SSO) Dexa, OAuth 2.0 / OpenID Connect, atau autentikasi berbasis kredensial username/password?
2. **Hak Akses Berdasarkan Peran**:
   - Apakah data pengumuman dan notifikasi akan dipisah berdasarkan peran pengguna (Mahasiswa vs Dosen), ataukah berbasis audiens tag pada payload data?
3. **Sinkronisasi Data Lokal dengan Cloud**:
   - Menentukan apakah status baca notifikasi yang disimpan di perangkat perlu disinkronkan kembali ke database server saat pengguna beralih perangkat.

