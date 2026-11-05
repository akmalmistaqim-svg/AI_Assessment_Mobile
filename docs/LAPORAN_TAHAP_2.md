# LAPORAN TAHAP 2 — KERANGKA TAMPILAN DAN NAVIGASI INFORMASI & NOTIFIKASI

Pemeriksaan dan verifikasi: 27 Oktober 2026 (Asia/Jakarta).

## 1. Status: SELESAI (TAHAP 2)

Kerangka tampilan dan navigasi aplikasi mobile Dexa Assessment untuk fitur Informasi dan Notifikasi telah berhasil dibangun, diuji, dan diverifikasi secara menyeluruh. Seluruh batasan dan kriteria Tahap 2 telah dipenuhi dengan sempurna:
- Kerangka antarmuka navigasi 4 tab utama (Beranda, Informasi, Notifikasi, dan Profil) bekerja mulus dengan `IndexedStack` sehingga status halaman tidak hilang saat berpindah tab.
- Penanda hitungan notifikasi belum dibaca (*unread badge*) pada tab bawah dan kartu ringkasan beranda terhubung secara reaktif dengan state management lokal.
- Detail informasi dan notifikasi dapat dibuka dan status dibaca diperbarui secara otomatis.
- Analisis statis (`flutter analyze`) lulus tanpa masalah (0 issues).
- Pengujian otomatis 6 skenario widget test (`flutter test`) lulus 100%.
- APK debug berhasil dibangun ulang dan dipasang ke emulator Android aktif (`emulator-5554`, Android 17 / API 37).
- Verifikasi visual berhasil dilakukan melalui 5 tangkapan layar emulator nyata.

**Penting:** Status ini menandakan penyelesaian penuh pada **TAHAP 2**. Sesuai batasan tugas, hal ini tidak menyatakan target keseluruhan proyek 50% telah selesai, karena tahap selanjutnya masih memerlukan keputusan fitur peran dan integrasi backend.

---

## 2. Kondisi Awal dan Masalah yang Ditemukan

1. **Kondisi Awal Proyek**:
   - Kode proyek pada akhir Tahap 1 hanya berupa template bawaan counter Flutter (angka 0 ke 1) dengan AppBar ungu default.
   - Belum memiliki sistem navigasi, tema identitas Dexa, model data, maupun tata letak portal akademik.
2. **Keterbatasan Lingkungan & Masalah Teknis**:
   - Flutter SDK versi 3.47.6 menerapkan pengetatan tipe data pada `ThemeData.cardTheme` yang memerlukan `CardThemeData`, bukan `CardTheme`.
   - Penyimpanan tangkapan layar emulator ke direktori `/sdcard/` sempat mengalami *I/O error* akibat status emulated storage yang belum siap sepenuhnya pasca-boot, sehingga dialihkan ke `/data/local/tmp/`.
   - Pada layar berukuran sempit (320 dp) atau pembesaran teks aksesibilitas (text scale 1.5x), baris metadata tanggal dan kategori pada kartu notifikasi berpotensi mengalami `RenderFlex` overflow jika menggunakan `Row` kaku.

---

## 3. Halaman dan Interaksi yang Dibuat

1. **Beranda (`HomePage`)**:
   - Salam portal akademik dengan identitas **Dexa Assessment Mobile**.
   - Lencana visual eksplisit **Mode Demo / Simulasi Lokal** untuk menjamin transparansi data.
   - Kartu ringkasan interaktif: menampilkan jumlah pengumuman aktif (4) dan notifikasi belum dibaca (2), yang dapat diklik langsung untuk berpindah ke tab tujuan terkait.
   - Seksi pratinjau pengumuman terbaru dengan aksi cepat "Lihat Semua".
2. **Tab Informasi (`AnnouncementsPage`)**:
   - Daftar 4 pengumuman akademik berkategori (Akademik, Ujian, Beasiswa, Layanan).
   - Kartu pengumuman memuat judul, tanggal publikasi, kategori, dan cuplikan ringkas.
   - Mengklik kartu membuka halaman **Detail Pengumuman (`AnnouncementDetailPage`)** dengan konten lengkap dan tombol navigasi kembali ke daftar.
3. **Tab Notifikasi (`NotificationsPage`)**:
   - Daftar 4 notifikasi lokal dengan lencana visual status ("Belum Dibaca" berlatar biru vs "Sudah Dibaca" netral).
   - Mengklik item notifikasi membuka **Detail Notifikasi (`NotificationDetailPage`)**, yang secara otomatis menandai notifikasi tersebut sebagai telah dibaca (*read*).
   - Penurunan angka *unread* langsung tercermin pada lencana tab navigasi bawah dan kartu ringkasan di Beranda secara konsisten.
4. **Tab Profil (`ProfilePage`)**:
   - Tampilan profil akun simulasi umum (Nama: Demo User, NIM/NIP: DEXA-2026-DEMO, Peran: Pengguna Demo Umum).
   - Menghindari tombol non-fungsional atau alur login palsu; hanya menyajikan informasi akun demo, status mode aplikasi, serta kartu informasi versi dan arsitektur sistem.
5. **Navigasi Utama (`MainNavigationPage`)**:
   - 4 menu pada `BottomNavigationBar` dengan ikon tematik Material 3.
   - Lencana dinamis pada tab Notifikasi yang otomatis hilang jika seluruh notifikasi telah dibaca.
   - Dukungan `PopScope` untuk tombol *Back* fisik/gesture Android (jika berada di tab selain Beranda, tombol *Back* mengembalikan pengguna ke tab Beranda terlebih dahulu sebelum keluar aplikasi).

---

## 4. Struktur dan Berkas yang Dibuat atau Diubah

Seluruh perubahan terbatas ketat di dalam folder `D:\Dexa_Assessment_Mobile`:

```text
D:\Dexa_Assessment_Mobile\
├── lib/
│   ├── data/
│   │   └── sample_data.dart            # Data statis 4 pengumuman & 4 notifikasi
│   ├── models/
│   │   ├── announcement.dart           # Model entitas pengumuman akademik
│   │   └── notification_item.dart      # Model entitas notifikasi
│   ├── pages/
│   │   ├── announcement_detail_page.dart # Detail pengumuman
│   │   ├── announcements_page.dart       # Daftar pengumuman
│   │   ├── home_page.dart                # Beranda portal & ringkasan
│   │   ├── main_navigation_page.dart     # Shell 4-tab IndexedStack & PopScope
│   │   ├── notification_detail_page.dart # Detail notifikasi & auto-read
│   │   ├── notifications_page.dart       # Daftar notifikasi & badge unread
│   │   └── profile_page.dart             # Profil akun demo umum
│   ├── state/
│   │   └── app_state.dart              # ChangeNotifier & InheritedNotifier
│   ├── theme/
│   │   └── app_theme.dart              # Desain sistem Material 3 palet Dexa
│   ├── widgets/
│   │   └── demo_badge.dart             # Komponen visual penanda mode demo
│   └── main.dart                       # Titik masuk utama aplikasi
├── test/
│   └── widget_test.dart                # 6 skenario pengujian otomatis
├── docs/
│   ├── evidence/                       # Tangkapan layar & bukti pengujian
│   ├── LAPORAN_TAHAP_1.md              # Laporan Tahap 1 terdahulu
│   └── LAPORAN_TAHAP_2.md              # Laporan Tahap 2 ini
└── README.md                           # Panduan arsitektur dan eksekusi
```

---

## 5. Keputusan Desain dan Palet Warna

- **Palet Warna Profesional Dexa**:
  - Warna Utama (*Primary*): Deep Dexa Blue (`#0F2C59`) — melambangkan kredibilitas dan stabilitas portal institusi.
  - Warna Aksen (*Secondary / Accent*): Sky Blue (`#0284C7`) — memberikan kontras yang jelas pada tombol aksi, lencana kategori, dan indikator tab aktif.
  - Latar Belakang (*Background*): Slate Tint (`#F8FAFC`) — abu-abu sangat muda yang nyaman di mata untuk membaca teks panjang.
  - Kartu & Kontainer (*Surface*): Putih murni (`#FFFFFF`) dengan batas halus (`#E2E8F0`) dan elevasi minimalis (0–1 dp) bergaya Material 3.
- **Tipografi & Keterbacaan**:
  - Menggunakan hierarki tipografi sans-serif bawaan platform dengan rasio kontras warna teks di atas 4.5:1 (memenuhi standar aksesibilitas WCAG AA).
- **Ketahanan Tata Letak**:
  - Seluruh baris metadata menggunakan `Wrap` dan fleksibilitas teks (`Expanded`/`Flexible`) dengan pemotongan teks rapi (`ellipsis`) untuk menjamin bebas dari *overflow* saat dijalankan pada perangkat berlayar kecil atau saat pengguna mengaktifkan pembesaran huruf.

---

## 6. Data Demo dan Batasan Fitur

- **Sifat Data**:
  - 4 pengumuman akademik dan 4 notifikasi tersimpan secara lokal di [lib/data/sample_data.dart](file:///D:/Dexa_Assessment_Mobile/lib/data/sample_data.dart).
  - Tiap halaman memuat penanda eksplisit bahwa data bersifat simulasi lokal (*demo mode*).
- **Batasan Ruang Lingkup Tahap 2**:
  - Tidak ada hak akses atau fitur khusus peran (dosen vs mahasiswa) yang dikarang sebelum ada keputusan bisnis.
  - Tidak menggunakan autentikasi/login nyata, integrasi API backend, push notification remote (FCM), OCR/kamera/scan, atau pustaka AI.
  - Tidak ada perubahan di luar folder proyek mobile.

---

## 7. Hasil flutter analyze

**STATUS: LULUS (0 ISSUES)**

Perintah yang dijalankan pada terminal:
```powershell
flutter analyze
```

Hasil verifikasi aktual:
```text
Analyzing Dexa_Assessment_Mobile...                             
No issues found! (ran in 4.1s)
```
Seluruh kode mematuhi kaidah `flutter_lints` tanpa adanya peringatan sintaks, *unused import*, maupun *deprecated API*.

---

## 8. Hasil Pengujian Otomatis (flutter test)

**STATUS: 6 LULUS, 0 GAGAL**

Pengujian otomatis dieksekusi melalui widget testing di [test/widget_test.dart](file:///D:/Dexa_Assessment_Mobile/test/widget_test.dart):
```powershell
flutter test
```

Hasil eksekusi riil:
```text
00:00 +0: loading D:/Dexa_Assessment_Mobile/test/widget_test.dart
00:00 +0: Tampilan awal beranda menampilkan identitas dan ringkasan konsisten
00:01 +1: Navigasi empat tab bawah bekerja dan mempertahankan status halaman
00:02 +2: Tautan ringkasan di Beranda membuka tab tujuan yang sesuai
00:02 +3: Membuka detail informasi dan kembali ke daftar
00:03 +4: Membuka notifikasi mengubah status dibaca dan konsisten di seluruh tab
00:03 +5: Tata letak aman dari overflow pada layar kecil dan pembesaran teks
00:04 +6: All tests passed!
```

*Catatan metodologis*: Hasil widget test ini menguji fungsionalitas logika widget dalam memori dan dibedakan secara tegas dari pengujian interaksi langsung di emulator Android.

---

## 9. Hasil Build APK Debug dan Lokasi Berkas

**STATUS: BERHASIL**

Perintah build Gradle:
```powershell
flutter build apk --debug
```

Spesifikasi berkas APK aktual:
- **Lokasi Absolut**: [D:\Dexa_Assessment_Mobile\build\app\outputs\flutter-apk\app-debug.apk](file:///D:/Dexa_Assessment_Mobile/build/app/outputs/flutter-apk/app-debug.apk)
- **Ukuran Berkas**: 165.489.496 bytes (~157,8 MB)
- **Waktu Modifikasi Terakhir**: 27 Oktober 2026, 20:36:22 WIB
- **SHA256**: `FA2FEAEA1A8BB61422B9E08EE98F752A7C2B9344BBACA8DE8F5A4AA96B14D575`

---

## 10. Hasil Pengujian Emulator dan Lokasi Bukti Screenshot

Aplikasi dipasang dan diuji secara otomatis pada emulator aktif `emulator-5554` (AVD: `Medium_Phone_API_37.0`, Android 17 / API 37 x86_64). Navigasi antar-tab dan perpindahan halaman detail dieksekusi menggunakan input perintah ADB serta diverifikasi melalui dump UIAutomator dan tangkapan layar visual:

| Halaman / Fitur | Lokasi Berkas Bukti | Ukuran Berkas | Deskripsi Visual Aktual |
| --- | --- | --- | --- |
| **Beranda** | [screenshot-tahap2-beranda.png](file:///D:/Dexa_Assessment_Mobile/docs/evidence/screenshot-tahap2-beranda.png) | 256.671 bytes | Header Dexa Assessment, badge "Mode Demo", kartu 4 Informasi & 2 Notifikasi Baru, preview pengumuman, dan 4 tab bawah. |
| **Tab Informasi** | [screenshot-tahap2-informasi.png](file:///D:/Dexa_Assessment_Mobile/docs/evidence/screenshot-tahap2-informasi.png) | 290.002 bytes | Daftar lengkap 4 pengumuman akademik dengan lencana kategori warna-warni dan tanggal terstruktur. |
| **Tab Notifikasi** | [screenshot-tahap2-notifikasi.png](file:///D:/Dexa_Assessment_Mobile/docs/evidence/screenshot-tahap2-notifikasi.png) | 276.738 bytes | Daftar notifikasi lokal dengan lencana status "Belum Dibaca" (biru) dan "Sudah Dibaca" (abu-abu). |
| **Detail Notifikasi** | [screenshot-tahap2-notif-detail.png](file:///D:/Dexa_Assessment_Mobile/docs/evidence/screenshot-tahap2-notif-detail.png) | 276.672 bytes | Tampilan detail pesan lengkap notifikasi, waktu, penanda otomatis terbaca, dan tombol kembali. |
| **Tab Profil** | [screenshot-tahap2-profil.png](file:///D:/Dexa_Assessment_Mobile/docs/evidence/screenshot-tahap2-profil.png) | 239.969 bytes | Profil pengguna demo umum ("Demo User", ID DEXA-2026-DEMO), status mode demo, serta kartu spesifikasi versi aplikasi. |
| **Hierarki UI** | [dump_tahap2.xml](file:///D:/Dexa_Assessment_Mobile/docs/evidence/dump_tahap2.xml) | 12.879 bytes | Dump UIAutomator membuktikan elemen tab `Informasi` terpilih (`selected="true"`) dan teks pengumuman ter-render pada layar. |

---

## 11. Error yang Ditemukan dan Solusinya

1. **Inkompatibilitas Tipe `cardTheme` pada Flutter 3.47**:
   - *Masalah*: Konstruktor `ThemeData(cardTheme: CardTheme(...))` memicu error kompilasi karena Flutter 3.47 mengharuskan `CardThemeData`.
   - *Solusi*: Mengganti instansiasi menjadi `CardThemeData` di [lib/theme/app_theme.dart](file:///D:/Dexa_Assessment_Mobile/lib/theme/app_theme.dart).
2. **Potensi RenderFlex Overflow pada Baris Metadata**:
   - *Masalah*: Kartu notifikasi yang memadukan status, kategori, dan tanggal dalam satu `Row` kaku memicu peringatan overflow pada pengujian layar sempit / font besar.
   - *Solusi*: Mengganti `Row` dengan `Wrap(spacing: 8, runSpacing: 4)` di [lib/pages/notifications_page.dart](file:///D:/Dexa_Assessment_Mobile/lib/pages/notifications_page.dart) serta menambahkan flex constraint pada [lib/pages/profile_page.dart](file:///D:/Dexa_Assessment_Mobile/lib/pages/profile_page.dart) dan [lib/pages/home_page.dart](file:///D:/Dexa_Assessment_Mobile/lib/pages/home_page.dart).
3. **Penyimpanan Screenshot Android 17 / API 37**:
   - *Masalah*: Eksekusi `screencap -p /sdcard/...` menghasilkan error `Input/output error` saat storage emulated belum siap sempurna pasca-booting.
   - *Solusi*: Mengalihkan target penyimpanan sementara ke `/data/local/tmp/...` lalu menarik berkas via `adb pull`.

### Bagian yang Belum Diverifikasi

Sesuai dengan batasan ketat Tahap 2, hal-hal berikut secara eksplisit **belum diverifikasi** dan tidak diklaim:
- **Pengujian pada Perangkat Android Fisik**: Pengujian diverifikasi menggunakan Android Virtual Device x86_64 API 37 (`emulator-5554`), belum diuji pada berbagai varian ponsel Android fisik.
- **Konfigurasi Rilis Produksi**: Build signing key rilis, obfuscation ProGuard/R8, dan app bundle (`.aab`) belum dikonfigurasi (masih menggunakan debug build).
- **Integrasi Backend Nyata**: Aplikasi belum terhubung ke server/database API Dexa riil (seluruh data masih berupa simulasi lokal dalam memori).
- **Otentikasi & Push Notification Riil**: Alur login/token sesi dan penerimaan notifikasi jarak jauh (FCM/APNS) belum diimplementasikan.

---

## 12. Keputusan yang Dibutuhkan untuk Tahap Berikutnya

Sebelum melangkah ke tahap selanjutnya, terdapat beberapa hal manajerial dan arsitektural yang perlu disepakati:
1. **Spesifikasi Peran Pengguna (*User Roles*)**:
   - Apakah aplikasi mobile akan memiliki antarmuka/fitur yang berbeda antara **Mahasiswa**, **Dosen**, dan **Tenaga Kependidikan**, ataukah menggunakan satu antarmuka terpadu berbasis hak akses dinamis?
2. **Mekanisme Autentikasi**:
   - Penentuan protokol autentikasi resmi (misalnya OAuth 2.0, OpenID Connect portal Dexa, atau REST API token JWT).
3. **Spesifikasi Kontrak API Backend**:
   - Ketersediaan endpoint REST/GraphQL untuk pengumuman akademik, riwayat notifikasi, dan profil pengguna.
4. **Identitas Aplikasi Resmi**:
   - Konfirmasi penamaan *Application ID* final pengganti `com.example.dexa_assessment_mobile` sebelum konfigurasi rilis produksi.
