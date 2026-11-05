# Laporan koneksi HP dan penyiapan API 35 — 4 November 2026

## Status utama

Alur Android belum dinyatakan selesai. APK khusus HP sudah dibangun, koneksi browser HP ke FastAPI dikonfirmasi pengguna, tetapi agen belum mempunyai koneksi ADB ke HP untuk menguji login/dashboard/pemilih dokumen. API 35 masih dalam proses unduh; belum ada klaim AVD siap atau tes emulator lulus.

## Penyebab konfigurasi yang ditemukan

- Docker PostgreSQL aktif dan healthy, tetapi saat pemeriksaan awal tidak ada FastAPI yang mendengarkan port 3001.
- APK lama memakai `http://10.0.2.2:3001`, alamat host khusus emulator. Alamat tersebut tidak menunjuk laptop dari HP Wi-Fi.
- FastAPI sekarang tersedia pada loopback untuk emulator dan pada alamat Wi-Fi spesifik `192.168.1.66:3001` untuk HP. Kedua proses menggunakan database serta storage yang sama.
- Login teskelas melalui IP Wi-Fi dan GET profil, kelas, nilai semuanya HTTP 200 dari laptop. Pengguna melaporkan respons JSON dari URL readiness di HP. Bukti ini belum menyatakan login UI Android berhasil.
- Tidak ada perubahan firewall. Approval review menolak bind wildcard dan aturan firewall persisten; bind diganti IP Wi-Fi spesifik, dan akses HP berhasil tanpa aturan tambahan.

## APK HP

- ARM64: `build/qa-artifacts/dexa-phone-wifi-arm64-v8a-debug.apk`, 82.807.981 byte.
- ARM32: `build/qa-artifacts/dexa-phone-wifi-armeabi-v7a-debug.apk`, 61.843.223 byte.
- Kedua APK memakai endpoint `http://192.168.1.66:3001`, target `lib/main.dart`, signing debug. Bukan build release.
- Pemeriksaan kernel memastikan endpoint yang benar dan tidak memuat email QA. SHA256 tersedia pada `docs/evidence/phone-wifi-apk-2026-11-04.json`.
- Build sukses dalam 121,9 detik. Ada peringatan pemeriksaan Git Flutter gagal DNS dan perbedaan format SDK XML; tidak mengganti versi tool karena kompilasi berhasil.
- APK emulator terdahulu disimpan terpisah sebagai `build/qa-artifacts/dexa-emulator-debug.apk`.
- Jika IP DHCP laptop berubah, jalankan ulang backend dengan IP baru dan build ulang APK HP.

Perintah yang dapat diulang:

```powershell
powershell -File tools/start_backend_wifi.ps1 -BackendHost 192.168.1.66
powershell -File tools/build_phone_debug.ps1 -BackendHost 192.168.1.66
```

## API 35

Pengguna mengizinkan instalasi system image API 35. Paket resmi yang diunduh: `system-images/android-35/google_apis/x86_64` (tanpa Play Store), sekitar 1,6 GB. Download sangat lambat saat pemeriksaan; status belum selesai.

`tools/finish_api35_setup.py` berjalan di latar belakang. Setelah package.xml dan system.img hasil instalasi tersedia, ia membuat AVD baru bernama Dexa_API35 di `.local/avd/`, RAM 2048 MB, 2 core, layar 720×1280. Ia tidak menimpa AVD yang sudah ada dan tidak otomatis menyalakan emulator. Batas menunggu 12 jam; jika unduhan belum selesai setelah itu, status dicatat sebagai belum siap. Proses memerlukan laptop tetap menyala.

Status aktual: `docs/evidence/api35-setup-status.json`. Log pembuatan: `api35-create.log` bila langkah tersebut sudah berjalan. Setelah status siap:

```powershell
powershell -File tools/start_api35.ps1 -Visible
```

SDK image diinstal melalui tool Android yang terpasang; tidak memperbarui keseluruhan SDK/Flutter. Data AVD baru dibatasi ke folder mobile. API 37 sebelumnya dipertahankan.

## Uji negatif backend asli

`tools/check_submission_live_rejections.py` menjalankan 16 pemeriksaan yang lulus pada FastAPI nyata:
- Tanpa autentikasi 401 dan token salah 401.
- Dosen mencoba mengumpulkan 403.
- Jawaban kosong, ekstensi salah, PDF/DOCX palsu dan rusak ditolak 400.
- File 10 MiB + 1 byte ditolak 400.
- Mahasiswa lain membaca submission atau mengunduh file ditolak 403.
- Tugas nyata yang tenggatnya lewat menolak kiriman 400.
- Bergantian header sesi dua akun hanya mengembalikan submission milik akun tersebut.
- Versi pengumpulan teskelas tetap sama sebelum dan sesudah tes penolakan.

Bukti: `docs/evidence/submission-negative-live-2026-11-04.json`. Ini bukan pengujian pergantian akun atau koneksi putus pada Android. Tugas CLOSED, role ASSISTANT, serta kebijakan upload setelah nilai dirilis belum diuji live.

Pada percobaan awal tes tanpa Authorization, HTTP client ternyata masih membawa cookie login fixture mhs_a. Request tersebut sah terautentikasi dan menghasilkan satu kiriman QA tambahan. Tes diperbaiki dengan mengosongkan cookie sebelum pemeriksaan, lalu mengulang seluruh skenario. Ini bukan bukti bypass autentikasi backend. Catatan awal disimpan terpisah, tidak dihapus.

## Data QA dan rencana pembersihan

Inventaris terbaru: `docs/evidence/submission-qa-inventory-2026-11-04.json`. Tugas QA tetap c2b06c1a87b37498e8f08902a di kelas cc4fccf2b48bc440bbadfff2c, judul `[UJI MOBILE] Pengumpulan jawaban teskelas 2026-11-01`. Selain tiga versi teskelas, ada kiriman fixture mhs_a dari percobaan cookie di atas. Tidak ada tugas akademik lain yang diubah.

Pembersihan belum dijalankan. Urutan yang aman setelah bukti diterima:
1. Konfirmasi ID dan judul tugas QA melalui akun dosen pemilik; cocokkan seluruh submission/version dengan inventaris.
2. Catat fileUrl yang masih direferensikan sebelum menghapus record.
3. Hapus hanya tugas QA itu melalui endpoint DELETE tugas yang sudah ada, bukan kelas, akun, database, atau volume Docker. Penghapusan harus mendapat instruksi pengguna.
4. Verifikasi cascade record dan periksa referensi file yang tersisa. Endpoint hapus tugas belum terbukti membersihkan file storage; jangan menganggap file otomatis terhapus.
5. Hapus hanya objek file QA yang sudah tidak direferensikan dan berada dalam `.local/backend-storage` setelah memverifikasi resolved path. Jangan menghapus seluruh direktori storage.

## Hal yang masih membutuhkan bukti

Pairing ADB Wi-Fi HP untuk agen belum tersedia. Tanpa pairing, agen hanya dapat menguji backend dan menyiapkan APK. Berikutnya: install APK yang tepat, login hingga dashboard, pilih PDF/DOCX via pemilih Android asli, kirim, lalu cocokkan hasil di backend/website. Pengujian Drive, berkas mendekati batas, orientasi/font besar, dan koneksi putus harus dilaporkan sesuai pengujian perangkat yang benar-benar dilakukan.
