import 'package:flutter/material.dart';
import '../data/sample_data.dart';
import '../models/announcement.dart';
import '../models/notification_item.dart';
import '../services/notification_storage.dart';

/// State aplikasi terpadu untuk pengumuman, filter/pencarian, notifikasi lokal,
/// persistensi status baca, dan navigasi tab.
class AppState extends ChangeNotifier {
  final List<Announcement> _announcements;
  final List<NotificationItem> _notifications;
  final NotificationStorage _storage;

  int _currentTabIndex = 0;
  bool _isInitialized = false;
  String? _storageErrorMessage;

  // Filter dan pencarian informasi
  String _searchQuery = '';
  String _selectedCategory = 'Semua';

  AppState({
    List<Announcement>? announcements,
    List<NotificationItem>? notifications,
    NotificationStorage? storage,
  })  : _announcements = announcements ?? SampleData.initialAnnouncements,
        _notifications = notifications ?? SampleData.initialNotifications,
        _storage = storage ?? SharedPreferencesNotificationStorage();

  List<Announcement> get announcements => List.unmodifiable(_announcements);
  List<NotificationItem> get notifications => List.unmodifiable(_notifications);
  int get currentTabIndex => _currentTabIndex;
  bool get isInitialized => _isInitialized;
  String? get storageErrorMessage => _storageErrorMessage;

  // Getter filter dan pencarian
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;

  /// Daftar kategori yang benar-benar tersedia dalam data informasi, diawali opsi 'Semua'.
  List<String> get availableCategories {
    final categories = <String>{'Semua'};
    for (final item in _announcements) {
      categories.add(item.category);
    }
    return categories.toList();
  }

  /// Daftar informasi hasil pencarian dan filter kategori saat ini.
  List<Announcement> get filteredAnnouncements {
    final query = _searchQuery.trim().toLowerCase();
    return _announcements.where((item) {
      // 1. Filter kategori
      final matchCategory = _selectedCategory == 'Semua' ||
          item.category.toLowerCase() == _selectedCategory.toLowerCase();
      if (!matchCategory) return false;

      // 2. Filter kata kunci pencarian (judul, ringkasan, atau isi lengkap)
      if (query.isEmpty) return true;
      final matchTitle = item.title.toLowerCase().contains(query);
      final matchSummary = item.summary.toLowerCase().contains(query);
      final matchContent = item.content.toLowerCase().contains(query);

      return matchTitle || matchSummary || matchContent;
    }).toList();
  }

  /// Total informasi akademik keseluruhan (tidak terpengaruh oleh pencarian/filter di tab Informasi).
  int get totalAnnouncementCount => _announcements.length;

  /// Jumlah informasi yang cocok dengan filter aktif.
  int get filteredAnnouncementCount => filteredAnnouncements.length;

  /// Jumlah notifikasi yang belum dibaca dari sumber kebenaran tunggal.
  int get unreadNotificationCount =>
      _notifications.where((n) => !n.isRead).length;

  /// Memulihkan status baca yang tersimpan pada penyimpanan lokal ke dalam state.
  Future<void> loadPersistedState() async {
    try {
      final savedReadIds = await _storage.getReadNotificationIds();
      if (savedReadIds.isNotEmpty) {
        for (final item in _notifications) {
          // Hanya ubah status jika ID ada di data tersimpan
          if (savedReadIds.contains(item.id)) {
            item.isRead = true;
          }
        }
      }
      _storageErrorMessage = null;
    } catch (e) {
      _storageErrorMessage = 'Gagal memulihkan status baca lokal.';
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }

  /// Mengatur tab aktif.
  void setTabIndex(int index) {
    if (_currentTabIndex != index) {
      _currentTabIndex = index;
      notifyListeners();
    }
  }

  /// Memperbarui kata kunci pencarian (mengabaikan spasi di awal dan akhir pada saat penyaringan).
  void setSearchQuery(String query) {
    if (_searchQuery != query) {
      _searchQuery = query;
      notifyListeners();
    }
  }

  /// Memperbarui pilihan filter kategori.
  void setSelectedCategory(String category) {
    if (_selectedCategory != category) {
      _selectedCategory = category;
      notifyListeners();
    }
  }

  /// Mereset seluruh pencarian dan filter ke kondisi awal daftar lengkap.
  void resetFilters() {
    if (_searchQuery.isNotEmpty || _selectedCategory != 'Semua') {
      _searchQuery = '';
      _selectedCategory = 'Semua';
      notifyListeners();
    }
  }

  /// Menandai notifikasi sebagai terbaca dan menyimpan ID-nya ke penyimpanan persisten.
  /// Operasi ini idempoten: membaca ulang item yang sudah dibaca tidak memicu simpan ulang
  /// dan tidak mengurangi jumlah notifikasi dua kali.
  Future<bool> markNotificationAsRead(String id) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index == -1) {
      // ID tidak ditemukan dalam data contoh
      return false;
    }

    final item = _notifications[index];
    if (item.isRead) {
      // Sudah terbaca, tidak perlu mengubah state maupun storage
      return true;
    }

    // Ubah status di memori terlebih dahulu agar antarmuka responsif
    item.isRead = true;
    notifyListeners();

    // Simpan ke penyimpanan lokal
    final success = await _storage.saveReadNotificationId(id);
    if (!success) {
      _storageErrorMessage = 'Status tersimpan sementara, namun gagal diperbarui di penyimpanan lokal.';
      notifyListeners();
      return false;
    }

    _storageErrorMessage = null;
    return true;
  }

  /// Membersihkan pesan error penyimpanan setelah ditampilkan ke pengguna.
  void clearStorageErrorMessage() {
    if (_storageErrorMessage != null) {
      _storageErrorMessage = null;
      notifyListeners();
    }
  }
}

/// InheritedNotifier untuk membagikan AppState ke seluruh widget tree tanpa dependency eksternal.
class AppStateScope extends InheritedNotifier<AppState> {
  const AppStateScope({
    super.key,
    required AppState super.notifier,
    required super.child,
  });

  static AppState of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<AppStateScope>();
    assert(scope != null, 'AppStateScope tidak ditemukan pada context');
    return scope!.notifier!;
  }
}
