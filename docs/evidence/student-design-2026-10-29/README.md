# Preview desain mobile — 29 Oktober 2026

Delapan PNG dirender langsung dari StudentApp terbaru melalui Flutter widget testing, pada viewport 390 x 844 logical pixels (PNG 780 x 1688), dengan font Roboto dan MaterialIcons asli. Ini bukan screenshot Android dan bukan hasil koneksi backend; seluruh identitas/informasi memakai TestRepository lokal. NIM dan program studi pada gambar hanya contoh.

Alur capture lulus: login, beranda, informasi, detail informasi, pemberitahuan, detail/status dibaca, profil, dialog keluar. Semua layer dicat ulang sebelum capture untuk menghindari offset cache screenshot pada IndexedStack. Source aplikasi tidak diubah untuk preview.

Pengambilan Android sempat dicoba, tetapi dihentikan sebelum aplikasi berhasil terbuka karena memori bebas sekitar 400 MB saat emulator aktif. Emulator yang dibuat untuk tugas ini sudah dihentikan. APK normal dipulihkan dan hash tetap 99247ef9a8cf780ee5f520366437540c241cd6a04ed5a549626e4d1daa830221.

Reproduksi dari folder mobile:

```powershell
flutter test --no-pub test/student_design_capture_test.dart --dart-define=CAPTURE_DESIGN=true --dart-define=FLUTTER_FONT_DIR=D:/flutter/bin/cache/artifacts/material_fonts
```

Bukti: ../student-design-render.log. File integration_test/student_design_preview_test.dart dan test_driver/student_design_driver.dart tersedia untuk capture Android berikutnya, tetapi belum berhasil dijalankan pada percobaan ini.
