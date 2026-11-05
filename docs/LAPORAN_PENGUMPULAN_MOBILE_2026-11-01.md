# LAPORAN PENGUMPULAN JAWABAN MOBILE DEXA

Tanggal: 1 November 2026.

## Status

**VERDICT: fitur upload belum dapat dinyatakan selesai atau siap digunakan di Android.** Blocker P0: dialog pemilih dokumen, pembacaan URI, dan pengiriman dari runtime Android belum terverifikasi. APK build dan tes widget/backend bukan pengganti verifikasi perangkat.

Implementasi teks/PDF/DOCX dan sinkronisasi web sudah tersedia. Bukti yang lulus: 75 unit/widget test, tes widget dengan backend asli, website dosen/mahasiswa, dan build debug. Tidak ada klaim paritas seluruh fitur website atau target proyek keseluruhan tercapai.

Prioritas:
1. P0 — diagnosis runtime Android dan uji pemilih dokumen native.
2. P1 — uji negatif live, isolasi sesi, validasi konten dokumen, serta koneksi putus.
3. P2 — konfigurasi HP fisik, rencana cleanup QA dan distribusi; scan/draft/push merupakan pekerjaan lanjutan terpisah.

Catatan: pemeriksaan penolakan HTTP cleartext pada konfigurasi release sudah ada di tes repository sebelumnya; itu **bukan** bukti inspeksi APK release atau pengujian transport di perangkat.

## Lingkup dan kondisi awal

Aplikasi mahasiswa sudah memiliki login, profil, Kelas Saya/gabung kelas, informasi tugas, dan pemberitahuan nilai. Sebelumnya detail tugas mengarahkan pengumpulan ke website. APK lama bukan bukti fitur upload baru.

Kode produk diubah hanya di folder mobile. Backend dan frontend web digunakan untuk membaca kontrak dan menjalankan layanan lokal; kode, skema, migrasi, dan dependency kedua proyek tersebut tidak diubah. PostgreSQL/pgvector menggunakan container `ai_assessment_db`; tidak menambahkan SQLite. Tidak menjalankan seeder atau mengubah akun/tugas akademik yang ada.

## Alur yang tersedia

1. Mahasiswa login menggunakan akun backend yang sama dengan website.
2. Buka Kelas Saya, bergabung memakai kode kelas jika diperlukan, lalu pilih tugas. Tugas dari tab Informasi juga membuka detail yang sama.
3. Baca instruksi, tenggat, format, nilai maksimal, dan rubrik yang disediakan dosen.
4. Tulis jawaban atau pilih PDF/DOCX sesuai format tugas, maksimal 10 MiB (10.485.760 byte).
5. Konfirmasi kiriman. Selama proses berjalan, tombol kirim dan perubahan formulir dinonaktifkan.
6. Keberhasilan hanya ditampilkan sesudah backend memberikan receipt. Muat ulang menampilkan versi aktif, waktu kirim, isi hasil ekstraksi, dan riwayat versi.
7. Dosen memeriksa kiriman di website. Nilai dan feedback yang sudah dirilis dapat dibaca mahasiswa; perubahan jawaban setelah nilai dirilis diblokir mengikuti UI website.

Tugas ditutup, tenggat yang berakhir tanpa izin terlambat, format tidak didukung, dan anggota yang bukan STUDENT tidak dapat mengirim. Backend tetap menjadi pemeriksa otoritatif.

Berkas batal dipilih tidak menghapus pilihan sebelumnya. Draft dipertahankan ketika pengiriman gagal. Respons POST yang tidak pasti tidak otomatis dicoba ulang; mahasiswa harus memeriksa status dahulu. Receipt sukses tetap ditampilkan bila pemuatan rincian setelah POST gagal. Keluar halaman dengan draft meminta konfirmasi; respons lama tidak boleh mengisi sesi akun lain.

## Implementasi

- `lib/student/student_assignment.dart`: model tugas, versi, nilai dirilis, validasi teks/berkas, kontrak repository pengumpulan.
- `lib/student/student_assignment_page.dart`: formulir, pemilih mode, konfirmasi, status, riwayat, dan pemulihan error.
- `lib/student/answer_file_picker.dart`: integrasi pemilih dokumen native; membatasi pembacaan berkas sebelum mengirim.
- `lib/student/fastapi_student_repository.dart`: GET detail dan POST JSON/multipart melalui endpoint backend yang sudah ada; receipt divalidasi terhadap akun mahasiswa.
- `lib/student/student_controller.dart`: perlindungan kirim ganda dan isolasi sesi.
- `lib/student/student_app.dart`, `lib/models/announcement.dart`: navigasi tugas ke formulir baru.
- `lib/student/student_repository.dart`: pesan kegagalan yang aman dan dapat ditindaklanjuti.
- `pubspec.yaml`/lock: menambahkan file_selector resmi Flutter beserta dependency transitif, tanpa upgrade massal.
- README, tes regresi, dan alat QA di `tools/`/`test/` diperbarui.

Pemilih dokumen menggunakan file_selector: https://pub.dev/packages/file_selector. Android menjadi target build; platform lain belum diverifikasi.

## Hasil pengujian

| Pemeriksaan | Hasil dan bukti |
| --- | --- |
| Flutter analyze | Lulus, tanpa issue; `docs/evidence/submission-analyze.log` |
| Seluruh unit/widget test | 75 lulus, 0 gagal, 2 tes live opt-in dilewati pada suite default; `submission-all-tests.log` |
| Tes pengumpulan terfokus | 12 lulus: serialisasi teks/multipart, ukuran/format, tenggat/hak akses, receipt, UI, ketidakpastian koneksi, klik ganda, viewport kecil/font besar, isolasi logout; `submission-tests-fixed.log` |
| Formulir Flutter + HTTP/backend asli | 1 tes live lulus: login teskelas, buka kelas/tugas, kirim TEXT → DOCX → PDF, refresh versi aktif; `submission-live-widget.log` |
| Isi tersimpan | Satu submission, tiga versi 1 TEXT / 2 DOCX / 3 PDF; marker isi masing-masing cocok. PDF diunduh kembali dan SHA256 sama dengan file asal; `submission-live-result.json` |
| Website dosen (Chrome/Playwright) | Login, daftar kiriman teskelas, PDF, dan isi jawaban terlihat. Tidak ada pageerror. Analisis AI/nilai tidak dijalankan; `teacher-mobile-submission-result.json` |
| Website mahasiswa (Chrome/Playwright) | Login teskelas, panel Perbarui Pengumpulan Tugas terlihat, API website mengembalikan versi PDF aktif yang sama. Tidak ada pageerror; `student-web-mobile-submission-result.json` |
| Build Android | APK debug berhasil, target lib/main.dart, 234,4 detik; `submission-build.log` |
| Android runtime/pemilih dokumen | Belum lulus. Emulator API 37 akhirnya melaporkan boot selesai. Percobaan install awal gagal saat boot. Percobaan berikutnya berhasil (ADB: Success), tetapi pembukaan MainActivity mengembalikan Status: timeout / LaunchState: UNKNOWN; interaksi dan pemilih dokumen belum terverifikasi. Screenshot hanya menunjukkan wallpaper Android, bukan aplikasi Dexa. Emulator yang dibuat untuk QA kemudian dihentikan. Jangan menyamakan widget test dengan tes native Android. |

Tes live menggunakan widget aplikasi dan repository produksi dengan jaringan asli. Pemilih dokumen diganti callback yang membaca fixture PDF/DOCX lokal; karena itu dialog penyimpanan Android dan pembacaan URI dari penyedia dokumen belum dibuktikan.

## Data QA dan bukti visual

Akun teskelas yang sudah ada digunakan; tidak ada akun mahasiswa asli yang diubah. Tugas baru berlabel `[UJI MOBILE] Pengumpulan jawaban teskelas 2026-11-01` dibuat di Rekayasa Perangkat Lunak A. Tugas ini adalah data QA, bukan tugas akademik.

- Assignment ID: c2b06c1a87b37498e8f08902a.
- Submission ID: c1c29c703c79845578979febc.
- Screenshot dosen: `docs/evidence/teacher-mobile-submission.png` dan `teacher-mobile-answer.png` (isi jawaban diperiksa secara visual).
- Screenshot mahasiswa web: `docs/evidence/student-web-mobile-submission.png`.
- Dokumen dan konfigurasi QA privat: `.local/`, diabaikan Git. Tidak menyertakan password/token pada laporan/APK.

Backend QA dijalankan oleh `tools/run_backend_local.py`, menggunakan database dan konfigurasi autentikasi yang sudah ada tanpa migrasi. Berkas pengujian disimpan di `.local/backend-storage`. Agar file QA ini tetap dapat diunduh, gunakan STORAGE_DIR yang sama ketika menjalankan ulang backend QA. Deployment normal perlu storage persisten yang dikonfigurasi oleh backend.

## Error yang ditemukan dan diperbaiki

Panel expandable hasil jawaban awalnya berbagi PageStorage dengan posisi scroll sehingga double terbaca sebagai bool. Diperbaiki dengan key terpisah per tugas/versi; dua tes UI yang gagal kemudian lulus. Receipt POST dengan bentuk JSON salah kini dianggap tidak pasti sehingga aplikasi tidak menampilkan sukses palsu atau langsung mencoba ulang.

Tes live awal gagal karena pemanggilan konstruktor berkas dan selector tugas pada kode tes, bukan kegagalan backend; diperbaiki sebelum pengiriman live berhasil. Tes web mahasiswa awal menunggu nama file yang memang tidak ditampilkan desain website; pemeriksaan disesuaikan dengan panel status dan versi aktif API, tanpa mengubah kode website.

## APK

Lokasi: `D:\Dexa_Assessment_Mobile\build\app\outputs\flutter-apk\app-debug.apk`.

Ukuran: 194709547 byte.
SHA256: `643580a7819bf2e7e56c7ef63617a82673e7451d8fc82082adfa9db7ac953bbb`.

APK menggunakan entrypoint produksi mahasiswa, berisi kode pemilih berkas dan formulir baru. Pemeriksaan kernel APK tidak menemukan email teskelas maupun marker QA. Endpoint default debug `http://10.0.2.2:3001` untuk emulator; FastAPI dan PostgreSQL harus aktif. HP fisik membutuhkan alamat backend yang dapat diakses perangkat. Ini APK debug, bukan distribusi release.

## Batas dan tindak lanjut

- Verifikasi pemilih dokumen dan pengiriman end-to-end pada emulator/HP yang stabil masih diperlukan.
- Scan kamera/OCR untuk tugas tipe SCAN tetap belum diimplementasikan; UI menjelaskan batas ini.
- Draft belum dipersistenkan lintas penutupan aplikasi; token login tetap di memori.
- Notifikasi masih pembacaan nilai dirilis, bukan push notification.
- Build release/signing, perangkat fisik, dan iOS belum diuji.
- Tidak menjanjikan bebas bug secara mutlak; kesimpulan berdasarkan pemeriksaan di atas.

Bukti batas Android: `docs/evidence/submission-android-status.json`, `submission-emulator-current.png`, dan `submission-android-launched.png` (nama berkas terakhir menunjukkan tujuan pengambilan, bukan bukti aplikasi berhasil terbuka). Tidak ada reset/wipe data emulator.

## Pembaruan 4 November 2026

Lihat `LAPORAN_WIFI_DAN_API35_2026-11-04.md`: APK Wi-Fi tersedia, koneksi readiness HP dikonfirmasi pengguna, 16 uji negatif live lulus, dan API 35 sedang diunduh. Verifikasi UI Android masih terbuka. Terdapat satu kiriman fixture tambahan dari tes cookie yang dijelaskan pada laporan baru; inventaris dan rencana cleanup disertakan.
