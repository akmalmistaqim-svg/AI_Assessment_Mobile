# Laporan QA dan Perbaikan Layout Mobile

Tanggal: 28 Oktober 2026 (Asia/Jakarta).

## Status

Empat kasus bug layout berhasil direproduksi melalui widget test dan diperbaiki. Analisis, seluruh tes, dan build APK terbaru lulus. Pemeriksaan visual langsung pada emulator belum selesai; jangan menafsirkan hasil ini sebagai jaminan bahwa seluruh tampilan/perangkat bebas bug.

## Ruang lingkup dan kondisi awal

- Perubahan berkas proyek hanya di `D:\Dexa_Assessment_Mobile`.
- Tidak mengubah frontend web, backend, database, dependency, konfigurasi build, atau logika penyimpanan notifikasi.
- Menggunakan Flutter/Android SDK yang sudah terpasang untuk tes, build, dan menjalankan emulator; tidak memasang ulang atau meningkatkan versi tool.
- Proyek sudah memiliki perubahan pengguna sebelum pekerjaan ini. Perubahan tersebut dipertahankan.
- Pemeriksaan awal: `flutter analyze` lulus (6,7 detik); 23 tes sebelumnya lulus.
- Empat tes layout tambahan gagal sebelum perbaikan. Log tersimpan di `docs/evidence/qa-regression-before.log`.

## Temuan dan perbaikan

| Kasus | Penyebab yang direproduksi | Perbaikan |
| --- | --- | --- |
| Informasi terfilter pada lebar 320 dp dan teks 150% | Baris jumlah hasil/reset dan tautan baca melampaui lebar tersedia | Status filter memakai Wrap; teks tautan diberi batas fleksibel |
| Detail notifikasi pada lebar 320 dp dan teks 150% | Kategori/status/demo dipaksa satu baris, tanggal tidak dibatasi | Label dapat berpindah baris; tanggal menggunakan ruang fleksibel |
| Detail informasi pada lebar 320 dp dan teks 150% | Kategori/demo dan tanggal melampaui lebar tersedia | Header memakai Wrap; tanggal diberi batas fleksibel |
| Pencarian lanskap 640×360 dp dengan inset keyboard 180 dp | Header tetap menghabiskan ruang vertikal pada Column | Header dan hasil menjadi satu CustomScrollView dengan sliver, sehingga dapat digulir |

Pencarian tetap mendukung kategori, hasil kosong, reset, dan detail. Keyboard dilepas ketika membuka detail hasil pencarian. Gaya, warna, data demo, dan fitur produk dipertahankan.

## Berkas yang diubah/ditambahkan

Kode aplikasi yang diubah:
- `lib/pages/announcements_page.dart`
- `lib/pages/notification_detail_page.dart`
- `lib/pages/announcement_detail_page.dart`

Tes baru: `test/ui_regression_test.dart` (5 skenario). Tes lama tidak dihapus atau dilemahkan.

Bukti:
- `docs/evidence/qa-layout-before-20261028/*.dart.txt`: salinan tiga file sebelum perbaikan.
- `docs/evidence/qa-layout.diff`: perbandingan terhadap salinan awal pekerjaan ini, bukan terhadap seluruh perubahan pengguna di Git.
- `docs/evidence/qa-changed-files.json`: hash sebelum/sesudah.
- `docs/evidence/qa-regression-before.log`: empat kasus gagal sebelum perbaikan.
- `docs/evidence/qa-regression-after.log`: empat kasus berhasil sesudah perbaikan.
- `docs/evidence/qa-keyboard-before.log`: verifikasi tambahan reset dengan keyboard dan pelepasan fokus ketika berpindah tab.
- `docs/evidence/qa-analyze-final.log`, `qa-tests-final.log`, `qa-build-final.log`: hasil akhir.

Salinan cadangan awal sempat berekstensi `.dart` dan ikut diperiksa analyzer sebagai source terpisah. Salinan tersebut diubah menjadi `.dart.txt`; aturan analisis tidak dilonggarkan. Analisis kemudian lulus.

## Hasil pengujian akhir

- `flutter analyze`: **LULUS**, No issues found, 4,7 detik.
- `flutter test`: **28 LULUS, 0 GAGAL** (23 tes lama dan 5 tes tambahan).
- Empat kasus layout yang sebelumnya gagal sekarang lulus.
- Reset filter dapat diakses dengan menggulir saat keyboard terbuka dalam simulasi lanskap.
- Berpindah ke Profil melepaskan fokus pencarian dan mempertahankan kata pencarian; perilaku ini sudah lulus tanpa perlu perubahan navigasi.
- Tes navigasi, pencarian/filter, status baca, pemulihan data, data salah tipe, dan antrean penulisan sebelumnya tetap lulus.
- `flutter build apk --debug`: **BERHASIL**, exit code 0, Gradle 79,4 detik. Peringatan native access Java tidak menggagalkan build.

## APK terbaru

- Lokasi: `D:\Dexa_Assessment_Mobile\build\app\outputs\flutter-apk\app-debug.apk`
- Ukuran: 154.617.916 bytes.
- Waktu perubahan: 28 Oktober 2026, 08:01:47 WIB (01:01:47 UTC).
- SHA256: `0387903045D4346BFB3374ED300E7B639644C28F92A19EC7168CBED24A64423C`.

## Pengujian emulator dan batas verifikasi

APK dipasang melalui `flutter run --use-application-binary` pada `emulator-5554` (Android 17/API 37). Log menunjukkan pemasangan selesai, Flutter engine dimuat, sinkronisasi perangkat berhasil, dan Dart VM Service tersedia. Tidak dilakukan penghapusan data aplikasi.

Koneksi kemudian terputus (`Lost connection to device`); pemeriksaan berikutnya menunjukkan emulator tidak terdaftar. Log juga memuat peringatan skipped frames dan error sistem Bluetooth emulator. Bukti ini tidak cukup untuk menyimpulkan penyebab emulator berhenti ataupun menyebutnya crash aplikasi Dexa. Satu percobaan menjalankan ulang emulator dilakukan untuk pemeriksaan startup lanjutan.

Pemeriksaan visual sebelumnya terhalang kegagalan penangkapan jendela di luar monitor dan dihentikan melalui Escape. Tidak ada screenshot baru yang diklaim sebagai bukti visual setelah perbaikan. Skenario ukuran layar/font/keyboard di atas adalah widget test, bukan uji visual langsung emulator atau ponsel fisik.

Belum memverifikasi perangkat fisik, performa produksi, seluruh ukuran layar/font, ataupun integrasi backend. Tidak ada pengembangan Tahap 4 atau perubahan desain baru.

### Hasil percobaan startup ulang

Emulator kembali terdeteksi sebagai `emulator-5554` dan `sys.boot_completed=1`. Peluncuran ulang APK menghasilkan `Status: timeout`, `LaunchState: UNKNOWN (-1)`, dan `WaitTime: 18216` dari `am start -W`. Proses aplikasi terdeteksi dengan PID 3243 setelah perintah tersebut. Keberadaan proses tidak dijadikan bukti bahwa seluruh layar/interaksi telah tampil dengan benar. Startup ulang dan verifikasi visual tetap memiliki keterbatasan; tidak dilakukan perubahan konfigurasi emulator/sistem untuk memaksa hasil lulus. Log aplikasi percobaan ini disimpan di `docs/evidence/qa-startup-retry.log`.

Log aplikasi pada percobaan ulang kemudian menunjukkan renderer Flutter aktif dan Dart VM Service mendengarkan. Tidak ada exception Dart/AndroidRuntime pada keluaran log terfilter yang diambil; hal ini tetap tidak menggantikan pemeriksaan visual layar. Alamat debug lokal disamarkan pada log yang disimpan.
