# LAPORAN TAHAP 1 — FONDASI MOBILE DEXA

Pemeriksaan awal: 26 Oktober 2026. Verifikasi selesai: 27 Oktober 2026 (Asia/Jakarta).

## 1. Status: SELESAI (TAHAP 1)

Fondasi mobile Tahap 1 telah berhasil dibangun dan diverifikasi secara menyeluruh. Seluruh kriteria Tahap 1 terpenuhi: kode template Android bersih dari lint/analisis, widget test lulus, APK debug berhasil dibangun, aplikasi berhasil dipasang dan dijalankan pada emulator Android aktif, interaksi penambahan counter dari 0 ke 1 terbukti bekerja melalui pengujian otomatis, serta tampilan visual diverifikasi melalui tangkapan layar. Catatan penting: status ini menyelesaikan Tahap 1 dan tidak menyatakan target keseluruhan 50% proyek selesai (pekerjaan tetap berada dalam batas Tahap 1).

## 2. Kondisi awal folder dan lingkungan

- Folder `D:\Dexa_Assessment_Mobile` ada dan awalnya kosong (termasuk berkas tersembunyi) saat inisialisasi awal.
- Tidak ditemukan `AGENTS.md` di dalam folder mobile.
- Flutter, Android SDK, Java, dan AVD sudah terpasang di sistem.
- Lisensi Android SDK telah diterima secara menyeluruh. Peringatan ketiadaan Visual Studio untuk target Windows desktop tidak memengaruhi proyek karena target murni Android.
- Pada awal sesi lanjutan, APK debug ditemukan sudah terbentuk di [app-debug.apk](file:///D:/Dexa_Assessment_Mobile/build/app/outputs/flutter-apk/app-debug.apk) (ukuran 150.491.232 bytes, SHA256: `9C11DF5D5F216CB4501140B9F553E652C94A92ACC3AF291578FD6DBA5A50D9FD`), namun status emulator, interaksi tombol, dan verifikasi visual belum tercatat dalam laporan.

## 3. Berkas yang dibuat atau diubah

- Template Flutter Android dibuat melalui `flutter create --platforms=android --project-name dexa_assessment_mobile .`.
- Struktur kode utama dipertahankan: [lib/main.dart](file:///D:/Dexa_Assessment_Mobile/lib/main.dart), [test/widget_test.dart](file:///D:/Dexa_Assessment_Mobile/test/widget_test.dart), [pubspec.yaml](file:///D:/Dexa_Assessment_Mobile/pubspec.yaml), [pubspec.lock](file:///D:/Dexa_Assessment_Mobile/pubspec.lock), [analysis_options.yaml](file:///D:/Dexa_Assessment_Mobile/analysis_options.yaml), dan folder `android/`.
- Berkas bukti pengujian di folder `docs/evidence/`:
  - [baseline-and-checks.json](file:///D:/Dexa_Assessment_Mobile/docs/evidence/baseline-and-checks.json): ringkasan baseline awal dan hasil pemeriksaan awal.
  - [initial-project-files.json](file:///D:/Dexa_Assessment_Mobile/docs/evidence/initial-project-files.json): inventaris SHA256 berkas awal.
  - [build-debug.log](file:///D:/Dexa_Assessment_Mobile/docs/evidence/build-debug.log): log percobaan build awal.
  - [ndk-install.log](file:///D:/Dexa_Assessment_Mobile/docs/evidence/ndk-install.log): log instalasi paket NDK.
  - [build-debug-retry.log](file:///D:/Dexa_Assessment_Mobile/docs/evidence/build-debug-retry.log): log build debug APK yang berhasil (`BUILD SUCCESSFUL in 8m 12s`).
  - [screen-initial.png](file:///D:/Dexa_Assessment_Mobile/docs/evidence/screen-initial.png): tangkapan layar dialog respon sistem saat emulator baru aktif.
  - [screenshot-counter-0.png](file:///D:/Dexa_Assessment_Mobile/docs/evidence/screenshot-counter-0.png): tangkapan layar tampilan awal aplikasi pada emulator dengan counter bernilai 0.
  - [screenshot-counter-1.png](file:///D:/Dexa_Assessment_Mobile/docs/evidence/screenshot-counter-1.png): tangkapan layar tampilan aplikasi pada emulator setelah tombol ditekan dengan counter bernilai 1.
  - [window_dump_counter_0.xml](file:///D:/Dexa_Assessment_Mobile/docs/evidence/window_dump_counter_0.xml): dump hierarki UI Android saat counter bernilai 0.
  - [window_dump_counter_1.xml](file:///D:/Dexa_Assessment_Mobile/docs/evidence/window_dump_counter_1.xml): dump hierarki UI Android saat counter bernilai 1.
- [LAPORAN_TAHAP_1.md](file:///D:/Dexa_Assessment_Mobile/docs/LAPORAN_TAHAP_1.md): laporan dokumentasi verifikasi ini.
- Batasan ketat dipatuhi: tidak ada perubahan pada frontend web, backend, database, maupun berkas di luar `D:\Dexa_Assessment_Mobile`.

## 4. Versi Flutter, Java, dan perangkat

| Komponen | Hasil pemeriksaan |
| --- | --- |
| Flutter | 3.47.6 stable, framework revision 5fc346839b |
| Dart | 3.13.5 |
| Java | OpenJDK 25.0.3, JBR Android Studio (`D:\android studio\jbr\bin\java`) |
| Gradle wrapper | 9.3.1 |
| Android Gradle Plugin (AGP) | 9.1.0 |
| Kotlin plugin | 2.4.0 |
| Android SDK Platform / Build-Tools | android-37.0 / 36.0.0 |
| NDK | 28.2.13676358 |
| AVD terdaftar | Medium_Phone_API_37.0 |
| Perangkat emulator saat pengujian aktif | `emulator-5554`, Android 17 / API 37, android-x64 (sdk gphone64 x86 64) |

## 5. Hasil flutter analyze

**LULUS** — `No issues found! (ran in 4.4s)` pada pemeriksaan ulang 27 Oktober 2026. Analisis kode sumber Dart tidak menghasilkan error maupun warning.

## 6. Hasil tes

**1 lulus, 0 gagal** — Pengujian `Counter increments smoke test` pada [test/widget_test.dart](file:///D:/Dexa_Assessment_Mobile/test/widget_test.dart) dieksekusi dengan `flutter test` dan lulus sempurna dalam 1 detik.
*Catatan pemisahan*: Hasil ini merupakan widget test pada lingkungan simulasi unit test Flutter, dibedakan secara tegas dari pengujian interaksi langsung pada emulator Android.

## 7. Hasil build APK debug dan lokasi absolut APK

**BERHASIL** — APK debug dibuat secara penuh menggunakan Gradle task `assembleDebug`:
- Lokasi absolut: [app-debug.apk](file:///D:/Dexa_Assessment_Mobile/build/app/outputs/flutter-apk/app-debug.apk)
- Ukuran: 150.491.232 bytes (~143,5 MB)
- SHA256: `9C11DF5D5F216CB4501140B9F553E652C94A92ACC3AF291578FD6DBA5A50D9FD`
- Log proses build tersimpan pada [build-debug-retry.log](file:///D:/Dexa_Assessment_Mobile/docs/evidence/build-debug-retry.log).

## 8. Hasil menjalankan aplikasi dan interaksi yang diperiksa

Aplikasi berhasil dipasang dan diuji secara otomatis pada emulator aktif tanpa mengambil alih mouse/keyboard fisik pengguna:
1. Emulator `Medium_Phone_API_37.0` dinyalakan dan dipastikan siap (`sys.boot_completed=1`).
2. APK dipasang ke emulator melalui ADB (`Performing Streamed Install -> Success`).
3. Aktivitas utama diluncurkan melalui ADB: `com.example.dexa_assessment_mobile/.MainActivity`.
4. Status fokus jendela diverifikasi melalui dumpsys: `mCurrentFocus=Window{... com.example.dexa_assessment_mobile.MainActivity}`.
5. Pemeriksaan UI sebelum interaksi (dump UI via UIAutomator):
   - Elemen teks counter terdeteksi dengan isi `0` (`content-desc="0"`, bounds: `[519,1284][561,1379]`).
   - Tombol FloatingActionButton terdeteksi dengan deskripsi `Increment` (`content-desc="Increment"`, bounds: `[891,2148][1038,2295]`).
6. Interaksi otomatis dieksekusi via `adb shell input tap 964 2221` (koordinat tengah tombol Increment).
7. Pemeriksaan UI sesudah interaksi:
   - Elemen teks counter terverifikasi berubah menjadi `1` (`content-desc="1"`, bounds: `[519,1284][561,1379]`).
   - Log UIAutomator disimpan di [window_dump_counter_0.xml](file:///D:/Dexa_Assessment_Mobile/docs/evidence/window_dump_counter_0.xml) dan [window_dump_counter_1.xml](file:///D:/Dexa_Assessment_Mobile/docs/evidence/window_dump_counter_1.xml).

## 9. Lokasi screenshot dan pemeriksaan visual

Tangkapan layar aktual diambil langsung dari emulator melalui ADB dan diverifikasi secara visual (bukan sekadar interpretasi log teks):
- [screenshot-counter-0.png](file:///D:/Dexa_Assessment_Mobile/docs/evidence/screenshot-counter-0.png): Menampilkan antarmuka aplikasi dengan AppBar ungu ("Flutter Demo Home Page"), teks "You have pushed the button this many times:", angka counter "0", dan tombol "+" di pojok kanan bawah.
- [screenshot-counter-1.png](file:///D:/Dexa_Assessment_Mobile/docs/evidence/screenshot-counter-1.png): Menampilkan antarmuka aplikasi dengan angka counter yang telah berubah menjadi "1" setelah tombol ditekan.
- [screen-initial.png](file:///D:/Dexa_Assessment_Mobile/docs/evidence/screen-initial.png): Menampilkan dialog konfirmasi sistem saat booting awal emulator sebelum penanganan interaksi.

## 10. Error yang ditemukan dan perbaikannya

1. **NDK tidak ditemukan oleh shim sdkmanager**: Pada percobaan build awal, `sdkmanager.bat` gagal mengunduh NDK karena format nama paket. Diselesaikan dengan memasang versi spesifik `ndk/28.2.13676358` via Android CLI tanpa memperbarui pustaka yang tidak diperlukan.
2. **Emulator offline / belum menyala**: Saat verifikasi dimulai, belum ada perangkat Android aktif. Emulator dijalankan langsung melalui CLI SDK emulator dan ditunggu hingga status `sys.boot_completed=1` selesai sebelum menjalankan instalasi.
3. **Dialog System UI Unresponsive saat emulator baru menyala**: Karena beban I/O saat cold boot emulator, dialog respon sistem sempat muncul. Hal ini ditangani secara otomatis melalui ADB input tap pada tombol dialog "Wait", sehingga fokus berpindah ke aplikasi Flutter tanpa kendala.

## 11. Bagian yang belum dapat diverifikasi

- Pengujian pada perangkat Android fisik (pengujian diverifikasi pada Android Virtual Device x86_64 API 37).
- Konfigurasi rilis produksi (keystore signing, ProGuard/R8 optimization, dan bundle AAB).
- Fitur bisnis lanjutan seperti otentikasi/login, integrasi API Dexa, push notification, barcode/OCR scan, dan integrasi AI (belum diimplementasikan sesuai batasan ruang lingkup Tahap 1).

## 12. Informasi yang dibutuhkan untuk tahap berikutnya

1. Spesifikasi kebutuhan fitur untuk Tahap 2 (misalnya arsitektur modul, manajemen state, autentikasi, atau desain UI yang ditetapkan).
2. Penentuan identitas paket final rilis (menggantikan identitas default `com.example.dexa_assessment_mobile`) jika diperlukan sebelum implementasi integrasi layanan.
3. Seluruh pekerjaan Tahap 1 telah selesai dan diverifikasi; tidak ada pekerjaan di luar Tahap 1 yang dimulai.
