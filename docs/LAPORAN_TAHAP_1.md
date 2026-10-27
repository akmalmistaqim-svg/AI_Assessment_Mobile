# LAPORAN TAHAP 1 — FONDASI MOBILE DEXA

Pemeriksaan awal: 26 Oktober 2026. Pekerjaan dilanjutkan: 27 Oktober 2026 (Asia/Jakarta).

## 1. Status: SEBAGIAN

Dokumen sementara selama pekerjaan berlangsung. Proyek dan pemeriksaan kode sudah tersedia; build APK serta verifikasi interaksi pada Android belum selesai. Status akan diperbarui setelah ada bukti pengujian. Ini belum menyatakan target keseluruhan 50% tercapai.

## 2. Kondisi awal folder dan lingkungan

- Folder `D:\Dexa_Assessment_Mobile` ada dan kosong, termasuk berkas tersembunyi, saat pemeriksaan awal.
- Tidak ditemukan `AGENTS.md` di dalam folder mobile.
- Flutter, Android SDK, Java, dan AVD sudah terpasang; belum ada perangkat Android aktif pada pemeriksaan awal.
- Android toolchain dan lisensi lolos. Peringatan awal: Visual Studio tidak tersedia untuk target Windows desktop, yang bukan target tahap ini.
- Saat pekerjaan dilanjutkan, 31 berkas dalam inventaris dibandingkan dengan SHA256 sebelumnya: tidak ada perubahan. Sesi build sebelumnya tidak lagi tersedia dan APK belum ditemukan.

## 3. Berkas yang dibuat atau diubah

- Template Flutter Android dibuat melalui `flutter create --platforms=android --project-name dexa_assessment_mobile .` (Flutter melaporkan 35 berkas).
- Struktur utama: `lib/main.dart`, `test/widget_test.dart`, `pubspec.yaml`, `pubspec.lock`, `analysis_options.yaml`, `.gitignore`, `.metadata`, serta `android/`.
- Aplikasi penghitung bawaan Flutter dan tesnya dipertahankan. Tidak ada desain final atau fitur produk baru.
- `README.md`: panduan menjalankan, memilih emulator, analisis, tes, dan build.
- `docs/evidence/baseline-and-checks.json`: catatan pemeriksaan awal dan hasil analisis/tes.
- `docs/evidence/initial-project-files.json`: inventaris berkas dan SHA256.
- `docs/evidence/build-debug.log`: log build yang gagal memasang NDK secara otomatis.
- `docs/evidence/ndk-install.log`: proses pemasangan satu versi NDK yang diperlukan.
- `docs/LAPORAN_TAHAP_1.md`: laporan ini.
- Berkas proyek hanya dibuat/diubah di folder mobile. Frontend web, backend, dan database tidak dikerjakan. Flutter/Gradle/Android menggunakan cache tool yang sudah terpasang.

## 4. Versi Flutter, Java, dan perangkat

| Komponen | Hasil pemeriksaan |
| --- | --- |
| Flutter | 3.47.6 stable, framework 5fc346839b |
| Dart | 3.13.5 |
| Java | OpenJDK 25.0.3, JBR bawaan Android Studio |
| Java executable | `D:\android studio\jbr\bin\java` |
| Gradle wrapper | 9.3.1 |
| Android Gradle Plugin | 9.1.0 |
| Kotlin plugin | 2.4.0 |
| SDK Build-Tools awal | 36.0.0 |
| NDK yang diminta Flutter | 28.2.13676358, pemasangan masih berjalan |
| AVD | Medium_Phone_API_37.0 |
| Perangkat saat emulator aktif | emulator-5554, Android 17 / API 37, android-x64 |

## 5. Hasil flutter analyze

**LULUS** — `No issues found`, durasi 22,7 detik pada pemeriksaan 26 Oktober 2026. Kode sumber tidak berubah sesudah pemeriksaan tersebut.

## 6. Hasil tes

**1 lulus, 0 gagal** — tes bawaan `Counter increments smoke test` memeriksa nilai 0 berubah menjadi 1 setelah tombol tambah ditekan. Hasil ini merupakan widget test, bukan bukti interaksi langsung pada emulator.

## 7. Hasil build APK debug dan lokasi absolut APK

**Belum berhasil.** Percobaan pada 27 Oktober berhenti dengan `Android sdkmanager did not install NDK 28.2.13676358` dan `Gradle task assembleDebug failed with exit code 1`.

Lokasi keluaran yang dituju (belum terverifikasi ada): `D:\Dexa_Assessment_Mobile\build\app\outputs\flutter-apk\app-debug.apk`.

## 8. Hasil menjalankan aplikasi dan interaksi yang diperiksa

AVD berhasil dinyalakan dan layar utama Android pernah diperiksa. Aplikasi Flutter belum terverifikasi berjalan karena APK belum tersedia. Tombol penghitung pada emulator belum diperiksa langsung.

## 9. Lokasi screenshot

Screenshot aplikasi belum tersedia; akan disimpan setelah aplikasi berhasil dijalankan dan interaksinya diperiksa.

## 10. Error yang ditemukan dan perbaikannya

1. Sesi build awal terputus/tidak lagi tersedia saat pekerjaan dilanjutkan; tidak ada APK yang dapat dijadikan bukti. Build diulang dengan log tersimpan, tanpa mengklaim percobaan sebelumnya berhasil.
2. Flutter memanggil shim `sdkmanager.bat` untuk `ndk;28.2.13676358`, tetapi log menunjukkan `Package ndk not found` dan `Package 28.2.13676358 not found`. Paket yang benar tersedia di Android CLI sebagai `ndk/28.2.13676358`. Pemasangan khusus paket tersebut sedang berjalan melalui Android CLI, tanpa memperbarui semua tool.
3. RAM bebas teramati sekitar 600 MB ketika emulator dan Gradle aktif. Emulator pengujian ditutup sementara untuk memberi ruang pada build. Ini bukan bukti bahwa terjadi out-of-memory. Emulator akan dinyalakan kembali untuk pengujian setelah build.
4. Peringatan Java native access dan flag AGP hasil template dicatat; belum terbukti sebagai penyebab kegagalan, sehingga versi/config tidak diganti untuk menghilangkan peringatan saja.

## 11. Bagian yang belum dapat diverifikasi

- Keberhasilan akhir build dan keberadaan APK.
- Aplikasi terbuka pada emulator serta interaksi tombol penghitung secara visual.
- Perangkat Android fisik, release signing, distribusi produksi, dan platform lain tidak termasuk tahap ini.
- Login, API, notifikasi, scan, AI, dan desain final belum dikerjakan sesuai batas tugas.

## 12. Informasi yang dibutuhkan untuk tahap berikutnya

Setelah tahap 1 berhasil dan laporan diterima, diperlukan instruksi tahap berikutnya serta keputusan cakupan pengguna/fitur awal. Application ID `com.example.dexa_assessment_mobile` masih sementara; identitas rilis dapat diputuskan sebelum tahap publikasi. Tidak ada pekerjaan tahap berikutnya yang dimulai.
