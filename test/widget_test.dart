import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dexa_assessment_mobile/main.dart';
import 'package:dexa_assessment_mobile/services/notification_storage.dart';
import 'package:dexa_assessment_mobile/state/app_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Pengujian Fondasi dan Navigasi Tahap 2 (Dipertahankan)', () {
    testWidgets(
        'Tampilan awal beranda menampilkan identitas dan ringkasan konsisten',
        (WidgetTester tester) async {
      final storage = InMemoryNotificationStorage();
      final appState = AppState(storage: storage);
      await appState.loadPersistedState();

      await tester.pumpWidget(DexaAssessmentApp(appState: appState));
      await tester.pumpAndSettle();

      // Verifikasi judul dan penanda mode demo
      expect(find.widgetWithText(AppBar, 'Dexa Assessment'), findsOneWidget);
      expect(find.text('Mode demo'), findsWidgets);
      expect(find.text('Selamat Datang di Dexa Assessment'), findsOneWidget);

      // Verifikasi ringkasan terhitung: 4 informasi dan 2 notifikasi belum dibaca bawaan awal
      expect(find.text('Ringkasan Aktivitas'), findsOneWidget);
      expect(find.text('4'), findsOneWidget); // Total informasi
      expect(find.text('2'), findsWidgets); // Notifikasi belum dibaca
    });

    testWidgets(
        'Navigasi empat tab bawah bekerja dan mempertahankan status halaman',
        (WidgetTester tester) async {
      final storage = InMemoryNotificationStorage();
      final appState = AppState(storage: storage);
      await appState.loadPersistedState();

      await tester.pumpWidget(DexaAssessmentApp(appState: appState));
      await tester.pumpAndSettle();

      final navBar = find.byType(BottomNavigationBar);

      // 1. Pindah ke Tab Informasi
      await tester.tap(find.descendant(of: navBar, matching: find.text('Informasi')));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(AppBar, 'Informasi Akademik'), findsOneWidget);
      expect(find.text('Jadwal Ujian Tengah Semester Genap 2026/2027'), findsOneWidget);

      // 2. Pindah ke Tab Notifikasi
      await tester.tap(find.descendant(of: navBar, matching: find.text('Notifikasi')));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(AppBar, 'Notifikasi'), findsOneWidget);
      expect(find.text('Pengingat Pengisian Kuesioner Evaluasi Dosen'), findsOneWidget);

      // 3. Pindah ke Tab Profil
      await tester.tap(find.descendant(of: navBar, matching: find.text('Profil')));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(AppBar, 'Profil Pengguna'), findsOneWidget);
      expect(find.text('Pengguna Uji Coba Dexa'), findsOneWidget);

      // 4. Kembali ke Tab Beranda
      await tester.tap(find.descendant(of: navBar, matching: find.text('Beranda')));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(AppBar, 'Dexa Assessment'), findsOneWidget);
    });

    testWidgets('Tautan ringkasan di Beranda membuka tab tujuan yang sesuai',
        (WidgetTester tester) async {
      final storage = InMemoryNotificationStorage();
      final appState = AppState(storage: storage);
      await appState.loadPersistedState();

      await tester.pumpWidget(DexaAssessmentApp(appState: appState));
      await tester.pumpAndSettle();

      final navBar = find.byType(BottomNavigationBar);

      // Tekan "Lihat Semua" pada ringkasan Informasi
      await tester.tap(find.widgetWithText(OutlinedButton, 'Lihat Semua'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(AppBar, 'Informasi Akademik'), findsOneWidget);

      // Kembali ke Beranda
      await tester.tap(find.descendant(of: navBar, matching: find.text('Beranda')));
      await tester.pumpAndSettle();

      // Tekan "Buka Pesan" pada ringkasan Notifikasi
      await tester.tap(find.widgetWithText(OutlinedButton, 'Buka Pesan'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(AppBar, 'Notifikasi'), findsOneWidget);
    });

    testWidgets('Membuka detail informasi dan kembali ke daftar',
        (WidgetTester tester) async {
      final storage = InMemoryNotificationStorage();
      final appState = AppState(storage: storage);
      await appState.loadPersistedState();

      await tester.pumpWidget(DexaAssessmentApp(appState: appState));
      await tester.pumpAndSettle();

      final navBar = find.byType(BottomNavigationBar);

      // Pindah ke tab Informasi
      await tester.tap(find.descendant(of: navBar, matching: find.text('Informasi')));
      await tester.pumpAndSettle();

      // Buka pengumuman pertama
      await tester.tap(find.text('Jadwal Ujian Tengah Semester Genap 2026/2027'));
      await tester.pumpAndSettle();

      // Verifikasi di halaman detail
      expect(find.widgetWithText(AppBar, 'Detail Informasi'), findsOneWidget);
      expect(find.text('Kembali ke Daftar Informasi'), findsOneWidget);

      // Tekan tombol kembali di AppBar
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      // Verifikasi kembali ke daftar informasi
      expect(find.widgetWithText(AppBar, 'Informasi Akademik'), findsOneWidget);
    });

    testWidgets(
        'Tata letak aman dari overflow pada layar kecil dan pembesaran teks',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final storage = InMemoryNotificationStorage();
      final appState = AppState(storage: storage);
      await appState.loadPersistedState();

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(360, 640),
            textScaler: TextScaler.linear(1.25),
          ),
          child: DexaAssessmentApp(appState: appState),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.widgetWithText(AppBar, 'Dexa Assessment'), findsOneWidget);

      final navBar = find.byType(BottomNavigationBar);

      // Tab Informasi layar kecil
      await tester.tap(find.descendant(of: navBar, matching: find.text('Informasi')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Tab Notifikasi layar kecil
      await tester.tap(find.descendant(of: navBar, matching: find.text('Notifikasi')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Tab Profil layar kecil
      await tester.tap(find.descendant(of: navBar, matching: find.text('Profil')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  group('Pengujian Tahap 3: Penyimpanan Status Baca Notifikasi', () {
    testWidgets('Pemulihan status baca dari penyimpanan dan konsistensi counter',
        (WidgetTester tester) async {
      // Simulasikan ID notif-1 sudah pernah dibaca sebelumnya dan tersimpan di storage
      final storage = InMemoryNotificationStorage(
        initialReadIds: {'notif-1'},
      );
      final appState = AppState(storage: storage);
      await appState.loadPersistedState();

      await tester.pumpWidget(DexaAssessmentApp(appState: appState));
      await tester.pumpAndSettle();

      // Karena notif-1 sudah dibaca, tersisa 1 belum dibaca (notif-2)
      expect(appState.unreadNotificationCount, 1);
      expect(find.text('1'), findsWidgets); // Ringkasan di beranda bernilai 1

      // Pindah ke tab Notifikasi
      final navBar = find.byType(BottomNavigationBar);
      await tester.tap(find.descendant(of: navBar, matching: find.text('Notifikasi')));
      await tester.pumpAndSettle();

      // Lencana AppBar menunjukkan '1 belum dibaca'
      expect(find.text('1 belum dibaca'), findsOneWidget);
    });

    testWidgets('Membaca ulang notifikasi tidak mengurangi counter dua kali',
        (WidgetTester tester) async {
      final storage = InMemoryNotificationStorage();
      final appState = AppState(storage: storage);
      await appState.loadPersistedState();

      expect(appState.unreadNotificationCount, 2);

      // Tandai notif-1 sebagai dibaca
      final firstRead = await appState.markNotificationAsRead('notif-1');
      expect(firstRead, isTrue);
      expect(appState.unreadNotificationCount, 1);

      // Baca ulang notif-1
      final secondRead = await appState.markNotificationAsRead('notif-1');
      expect(secondRead, isTrue);
      expect(appState.unreadNotificationCount, 1); // Tetap 1, tidak menjadi 0
    });

    testWidgets('Pembaruan beberapa notifikasi secara cepat tidak saling menimpa',
        (WidgetTester tester) async {
      final storage = SharedPreferencesNotificationStorage();
      // Gunakan storage dengan serialized queue
      final appState = AppState(storage: storage);
      await appState.loadPersistedState();

      // Lakukan pemanggilan simultan/cepat
      final futures = [
        appState.markNotificationAsRead('notif-1'),
        appState.markNotificationAsRead('notif-2'),
      ];
      await Future.wait(futures);

      expect(appState.unreadNotificationCount, 0);

      // Periksa isi storage
      final storedIds = await storage.getReadNotificationIds();
      expect(storedIds.contains('notif-1'), isTrue);
      expect(storedIds.contains('notif-2'), isTrue);
    });

    testWidgets('Penyimpanan gagal ditangani dengan aman tanpa crash',
        (WidgetTester tester) async {
      // Storage diset selalu gagal simpan
      final failingStorage = InMemoryNotificationStorage(shouldFailOnSave: true);
      final appState = AppState(storage: failingStorage);
      await appState.loadPersistedState();

      await tester.pumpWidget(DexaAssessmentApp(appState: appState));
      await tester.pumpAndSettle();

      final navBar = find.byType(BottomNavigationBar);
      await tester.tap(find.descendant(of: navBar, matching: find.text('Notifikasi')));
      await tester.pumpAndSettle();

      // Buka notifikasi pertama
      await tester.tap(find.text('Pengingat Pengisian Kuesioner Evaluasi Dosen'));
      await tester.pumpAndSettle();

      // Kembali ke daftar
      await tester.tap(find.text('Kembali ke Daftar Notifikasi'));
      await tester.pumpAndSettle();

      // Tidak crash, pesan error penyimpanan ditampilkan dengan aman
      expect(appState.storageErrorMessage, isNotNull);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    });

    testWidgets('ID asing yang tidak ada dalam data contoh diabaikan secara aman',
        (WidgetTester tester) async {
      final storage = InMemoryNotificationStorage(
        initialReadIds: {'id-asing-tidak-ada', 'notif-1'},
      );
      final appState = AppState(storage: storage);
      await appState.loadPersistedState();

      // Tidak ada error, notif-1 berhasil dibaca, id-asing diabaikan
      expect(appState.unreadNotificationCount, 1);
    });
  });

  group('Pengujian Tahap 3: Pencarian dan Filter Informasi', () {
    testWidgets('Pencarian judul/isi tidak peka huruf besar-kecil dan abaikan spasi',
        (WidgetTester tester) async {
      final storage = InMemoryNotificationStorage();
      final appState = AppState(storage: storage);
      await appState.loadPersistedState();

      await tester.pumpWidget(DexaAssessmentApp(appState: appState));
      await tester.pumpAndSettle();

      final navBar = find.byType(BottomNavigationBar);
      await tester.tap(find.descendant(of: navBar, matching: find.text('Informasi')));
      await tester.pumpAndSettle();

      // Cari dengan huruf campur dan spasi: '   uTs   ' (harus mencocokkan 'UTS' di pengumuman 1)
      final searchField = find.byType(TextField);
      await tester.enterText(searchField, '   uTs   ');
      await tester.pumpAndSettle();

      expect(appState.filteredAnnouncements.length, 1);
      expect(find.text('Jadwal Ujian Tengah Semester Genap 2026/2027'), findsOneWidget);
      expect(find.text('Pemeliharaan Terjadwal Server Portal Pembelajaran'), findsNothing);

      // Verifikasi ringkasan di Beranda tetap menghitung total keseluruhan (4), bukan hasil filter
      expect(appState.totalAnnouncementCount, 4);
    });

    testWidgets('Filter kategori menampilkan pengumuman sesuai kategori terpilih',
        (WidgetTester tester) async {
      final storage = InMemoryNotificationStorage();
      final appState = AppState(storage: storage);
      await appState.loadPersistedState();

      await tester.pumpWidget(DexaAssessmentApp(appState: appState));
      await tester.pumpAndSettle();

      final navBar = find.byType(BottomNavigationBar);
      await tester.tap(find.descendant(of: navBar, matching: find.text('Informasi')));
      await tester.pumpAndSettle();

      // Pilih kategori 'Layanan TI' pada baris filter chip horizontal
      final chipLayananTI = find.descendant(
        of: find.byType(SingleChildScrollView),
        matching: find.text('Layanan TI'),
      );
      await tester.tap(chipLayananTI);
      await tester.pumpAndSettle();

      expect(appState.filteredAnnouncements.length, 1);
      expect(find.text('Pemeliharaan Terjadwal Server Portal Pembelajaran'), findsOneWidget);
      expect(find.text('Pendaftaran Program Magang & Studi Independen Bersertifikat'), findsNothing);

      // Pilih 'Semua Kategori' kembali
      await tester.tap(find.text('Semua Kategori'));
      await tester.pumpAndSettle();
      expect(appState.filteredAnnouncements.length, 4);
    });

    testWidgets('Kombinasi pencarian dan kategori bekerja bersamaan',
        (WidgetTester tester) async {
      final storage = InMemoryNotificationStorage();
      final appState = AppState(storage: storage);
      await appState.loadPersistedState();

      await tester.pumpWidget(DexaAssessmentApp(appState: appState));
      await tester.pumpAndSettle();

      final navBar = find.byType(BottomNavigationBar);
      await tester.tap(find.descendant(of: navBar, matching: find.text('Informasi')));
      await tester.pumpAndSettle();

      // Ketik 'magang' dan pilih kategori 'Kemahasiswaan' pada baris filter chip
      await tester.enterText(find.byType(TextField), 'magang');
      final chipKemahasiswaan = find.descendant(
        of: find.byType(SingleChildScrollView),
        matching: find.text('Kemahasiswaan'),
      );
      await tester.tap(chipKemahasiswaan);
      await tester.pumpAndSettle();

      expect(appState.filteredAnnouncements.length, 1);
      expect(find.text('Pendaftaran Program Magang & Studi Independen Bersertifikat'), findsOneWidget);

      // Ganti kategori ke 'Akademik' saat query 'magang' masih aktif -> harus kosong
      final chipAkademik = find.descendant(
        of: find.byType(SingleChildScrollView),
        matching: find.text('Akademik'),
      );
      await tester.tap(chipAkademik);
      await tester.pumpAndSettle();

      expect(appState.filteredAnnouncements.length, 0);
      expect(find.text('Tidak ada informasi yang cocok'), findsOneWidget);
    });

    testWidgets('Tampilan hasil kosong dan fungsi reset mengembalikan daftar lengkap',
        (WidgetTester tester) async {
      final storage = InMemoryNotificationStorage();
      final appState = AppState(storage: storage);
      await appState.loadPersistedState();

      await tester.pumpWidget(DexaAssessmentApp(appState: appState));
      await tester.pumpAndSettle();

      final navBar = find.byType(BottomNavigationBar);
      await tester.tap(find.descendant(of: navBar, matching: find.text('Informasi')));
      await tester.pumpAndSettle();

      // Masukkan kata kunci yang tidak ada
      await tester.enterText(find.byType(TextField), 'kata-kunci-acak-12345');
      await tester.pumpAndSettle();

      expect(find.text('Tidak ada informasi yang cocok'), findsOneWidget);
      expect(find.text('Kembali ke Daftar Lengkap'), findsOneWidget);

      // Tekan tombol 'Kembali ke Daftar Lengkap'
      await tester.tap(find.text('Kembali ke Daftar Lengkap'));
      await tester.pumpAndSettle();

      expect(appState.filteredAnnouncements.length, 4);
      expect(find.text('Jadwal Ujian Tengah Semester Genap 2026/2027'), findsOneWidget);
    });

    testWidgets('Membuka detail dari hasil pencarian dan kembali mempertahankan query',
        (WidgetTester tester) async {
      final storage = InMemoryNotificationStorage();
      final appState = AppState(storage: storage);
      await appState.loadPersistedState();

      await tester.pumpWidget(DexaAssessmentApp(appState: appState));
      await tester.pumpAndSettle();

      final navBar = find.byType(BottomNavigationBar);
      await tester.tap(find.descendant(of: navBar, matching: find.text('Informasi')));
      await tester.pumpAndSettle();

      // Cari 'beasiswa'
      await tester.enterText(find.byType(TextField), 'beasiswa');
      await tester.pumpAndSettle();

      // Buka item hasil pencarian
      await tester.tap(find.text('Panduan Pengajuan Beasiswa Peningkatan Prestasi Akademik'));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(AppBar, 'Detail Informasi'), findsOneWidget);

      // Kembali ke daftar
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      // Verifikasi kata kunci pencarian masih ada di controller dan daftar tetap terfilter
      expect(find.widgetWithText(AppBar, 'Informasi Akademik'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'beasiswa'), findsOneWidget);
      expect(appState.filteredAnnouncements.length, 1);
    });
  });

  group('Pengujian Verifikasi Akhir: Ketahanan Data Penyimpanan Rusak / Salah Tipe', () {
    testWidgets(
        'Penyimpanan bernilai String korup (bukan list) ditangani aman dan aplikasi tetap mulai normal',
        (WidgetTester tester) async {
      // Simulasikan SharedPreferences lokal terisi data salah tipe (String biasa alih-alih List<String>)
      SharedPreferences.setMockInitialValues({
        'dexa_read_notification_ids': 'data_rusak_bukan_tipe_list',
      });

      final storage = SharedPreferencesNotificationStorage();
      final appState = AppState(storage: storage);

      // Pastikan loadPersistedState tidak melempar uncaught exception
      await appState.loadPersistedState();

      // Render antarmuka aplikasi
      await tester.pumpWidget(DexaAssessmentApp(appState: appState));
      await tester.pumpAndSettle();

      // Verifikasi aplikasi berjalan aman tanpa crash
      expect(tester.takeException(), isNull);
      expect(find.widgetWithText(AppBar, 'Dexa Assessment'), findsOneWidget);

      // Verifikasi fallback ke kondisi aman bawaan (2 notifikasi belum dibaca)
      expect(appState.unreadNotificationCount, 2);
      expect(find.text('2'), findsWidgets);

      // Verifikasi penyimpanan self-healing: saat notifikasi dibaca, data valid disimpan menggantikan data rusak
      final markSuccess = await appState.markNotificationAsRead('notif-1');
      expect(markSuccess, isTrue);
      expect(appState.unreadNotificationCount, 1);

      final recoveredIds = await storage.getReadNotificationIds();
      expect(recoveredIds.contains('notif-1'), isTrue);
    });

    testWidgets(
        'Penyimpanan bernilai numerik ditangani aman tanpa crash pada runtime',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({
        'dexa_read_notification_ids': 99999,
      });

      final storage = SharedPreferencesNotificationStorage();
      final appState = AppState(storage: storage);
      await appState.loadPersistedState();

      await tester.pumpWidget(DexaAssessmentApp(appState: appState));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(appState.unreadNotificationCount, 2);
    });
  });

  group('Pengujian Verifikasi Akhir: Tombol Kembali Android (System Back Navigation)', () {
    testWidgets('Detail Informasi -> kembali ke daftar Informasi melalui tombol kembali sistem',
        (WidgetTester tester) async {
      final storage = InMemoryNotificationStorage();
      final appState = AppState(storage: storage);
      await appState.loadPersistedState();

      await tester.pumpWidget(DexaAssessmentApp(appState: appState));
      await tester.pumpAndSettle();

      final navBar = find.byType(BottomNavigationBar);
      await tester.tap(find.descendant(of: navBar, matching: find.text('Informasi')));
      await tester.pumpAndSettle();

      // Buka pengumuman pertama
      await tester.tap(find.text('Jadwal Ujian Tengah Semester Genap 2026/2027'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(AppBar, 'Detail Informasi'), findsOneWidget);

      // Simulasikan penekanan tombol kembali Android fisik/sistem (handlePopRoute)
      final handled = await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(handled, isTrue);
      expect(find.widgetWithText(AppBar, 'Informasi Akademik'), findsOneWidget);
    });

    testWidgets('Detail Notifikasi -> kembali ke daftar Notifikasi melalui tombol kembali sistem',
        (WidgetTester tester) async {
      final storage = InMemoryNotificationStorage();
      final appState = AppState(storage: storage);
      await appState.loadPersistedState();

      await tester.pumpWidget(DexaAssessmentApp(appState: appState));
      await tester.pumpAndSettle();

      final navBar = find.byType(BottomNavigationBar);
      await tester.tap(find.descendant(of: navBar, matching: find.text('Notifikasi')));
      await tester.pumpAndSettle();

      // Buka notifikasi pertama
      await tester.tap(find.text('Pengingat Pengisian Kuesioner Evaluasi Dosen'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(AppBar, 'Detail Notifikasi'), findsOneWidget);

      // Simulasikan tombol kembali Android sistem
      final handled = await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(handled, isTrue);
      expect(find.widgetWithText(AppBar, 'Notifikasi'), findsOneWidget);
    });

    testWidgets('Tab selain Beranda -> kembali ke Beranda melalui tombol kembali sistem',
        (WidgetTester tester) async {
      final storage = InMemoryNotificationStorage();
      final appState = AppState(storage: storage);
      await appState.loadPersistedState();

      await tester.pumpWidget(DexaAssessmentApp(appState: appState));
      await tester.pumpAndSettle();

      final navBar = find.byType(BottomNavigationBar);

      // 1. Dari Tab Informasi (index 1) -> kembali ke Beranda (index 0)
      await tester.tap(find.descendant(of: navBar, matching: find.text('Informasi')));
      await tester.pumpAndSettle();
      expect(appState.currentTabIndex, 1);

      final handledInfo = await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(handledInfo, isTrue);
      expect(appState.currentTabIndex, 0);
      expect(find.widgetWithText(AppBar, 'Dexa Assessment'), findsOneWidget);

      // 2. Dari Tab Notifikasi (index 2) -> kembali ke Beranda (index 0)
      await tester.tap(find.descendant(of: navBar, matching: find.text('Notifikasi')));
      await tester.pumpAndSettle();
      expect(appState.currentTabIndex, 2);

      final handledNotif = await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(handledNotif, isTrue);
      expect(appState.currentTabIndex, 0);
      expect(find.widgetWithText(AppBar, 'Dexa Assessment'), findsOneWidget);

      // 3. Dari Tab Profil (index 3) -> kembali ke Beranda (index 0)
      await tester.tap(find.descendant(of: navBar, matching: find.text('Profil')));
      await tester.pumpAndSettle();
      expect(appState.currentTabIndex, 3);

      final handledProfil = await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(handledProfil, isTrue);
      expect(appState.currentTabIndex, 0);
      expect(find.widgetWithText(AppBar, 'Dexa Assessment'), findsOneWidget);
    });

    testWidgets('Beranda -> keluar dari aplikasi (canPop true, tidak menahan pop)',
        (WidgetTester tester) async {
      final storage = InMemoryNotificationStorage();
      final appState = AppState(storage: storage);
      await appState.loadPersistedState();

      await tester.pumpWidget(DexaAssessmentApp(appState: appState));
      await tester.pumpAndSettle();

      expect(appState.currentTabIndex, 0);

      // Penekanan tombol kembali saat di root Beranda mengembalikan handled = false
      // artinya PopScope mengizinkan OS Android keluar dari aplikasi
      final handled = await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(handled, isFalse);
      expect(appState.currentTabIndex, 0);
      expect(tester.takeException(), isNull);
    });
  });

  group('Pengujian Verifikasi Akhir: Mekanisme Antrean Serial SharedPreferencesNotificationStorage', () {
    test('Antrean serial mengeksekusi 5 penulisan konkuren tanpa race condition dan data tertimpa',
        () async {
      final storage = SharedPreferencesNotificationStorage();

      // Jalankan 5 operasi penulisan secara simultan/konkuren tanpa await antar pemanggilan
      final futures = [
        storage.saveReadNotificationId('notif-1'),
        storage.saveReadNotificationId('notif-2'),
        storage.saveReadNotificationId('notif-3'),
        storage.saveReadNotificationId('notif-4'),
        storage.saveReadNotificationId('notif-5'),
      ];

      final results = await Future.wait(futures);

      // Seluruh 5 penulisan harus berhasil
      for (final res in results) {
        expect(res, isTrue);
      }

      // Verifikasi seluruh 5 ID tersimpan di SharedPreferences nyata
      final savedIds = await storage.getReadNotificationIds();
      expect(savedIds.length, 5);
      expect(
        savedIds,
        containsAll(['notif-1', 'notif-2', 'notif-3', 'notif-4', 'notif-5']),
      );

      // Verifikasi langsung pada data SharedPreferences underlying
      final prefs = await SharedPreferences.getInstance();
      final rawList = prefs.getStringList('dexa_read_notification_ids');
      expect(rawList, isNotNull);
      expect(rawList!.length, 5);
    });

    test('Antrean tetap konsisten dan tidak deadlock saat menangani ID yang sama secara berulang',
        () async {
      final storage = SharedPreferencesNotificationStorage();

      final futures = [
        storage.saveReadNotificationId('notif-repeat'),
        storage.saveReadNotificationId('notif-repeat'),
        storage.saveReadNotificationId('notif-unique'),
      ];

      final results = await Future.wait(futures);
      for (final res in results) {
        expect(res, isTrue);
      }

      final savedIds = await storage.getReadNotificationIds();
      expect(savedIds.length, 2);
      expect(savedIds, containsAll(['notif-repeat', 'notif-unique']));
    });
  });
}
