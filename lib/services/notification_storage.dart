import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Kontrak penyimpanan status baca notifikasi lokal.
abstract class NotificationStorage {
  /// Mengambil kumpulan ID notifikasi yang telah ditandai sebagai dibaca.
  Future<Set<String>> getReadNotificationIds();

  /// Menyimpan ID notifikasi baru sebagai telah dibaca secara persisten.
  Future<bool> saveReadNotificationId(String id);

  /// Menyimpan sekumpulan ID notifikasi yang telah dibaca sekaligus.
  Future<bool> saveAllReadNotificationIds(Set<String> ids);
}

/// Implementasi penyimpanan lokal berbasis SharedPreferences untuk platform Android/iOS/Desktop.
class SharedPreferencesNotificationStorage implements NotificationStorage {
  static const String _storageKey = 'dexa_read_notification_ids';

  // Antrean future untuk mencegah race condition saat pembaruan status terjadi berurutan cepat
  Future<void>? _pendingWriteOperation;

  @override
  Future<Set<String>> getReadNotificationIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_storageKey);
      if (list == null) {
        return <String>{};
      }
      return list.toSet();
    } catch (e) {
      debugPrint('Gagal membaca status notifikasi dari penyimpanan lokal: $e');
      // Fallback aman jika data penyimpanan rusak atau tidak valid: kembalikan set kosong tanpa crash
      return <String>{};
    }
  }

  @override
  Future<bool> saveReadNotificationId(String id) async {
    // Sinkronisasi antrean penulisan agar beberapa panggilan cepat tidak saling menimpa
    final previousOperation = _pendingWriteOperation ?? Future.value();
    final completer = Completer<bool>();

    _pendingWriteOperation = previousOperation.catchError((_) {}).then((_) async {
      try {
        final prefs = await SharedPreferences.getInstance();
        List<String>? currentList;
        try {
          currentList = prefs.getStringList(_storageKey);
        } catch (_) {
          // Fallback aman jika data penyimpanan lama rusak atau salah tipe
          currentList = null;
        }
        final currentSet = (currentList ?? <String>[]).toSet();

        if (currentSet.contains(id)) {
          completer.complete(true);
          return;
        }

        currentSet.add(id);
        final success = await prefs.setStringList(_storageKey, currentSet.toList());
        completer.complete(success);
      } catch (e) {
        debugPrint('Gagal menyimpan status notifikasi $id ke penyimpanan lokal: $e');
        completer.complete(false);
      }
    });

    return completer.future;
  }

  @override
  Future<bool> saveAllReadNotificationIds(Set<String> ids) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setStringList(_storageKey, ids.toList());
    } catch (e) {
      debugPrint('Gagal menyimpan seluruh status notifikasi ke penyimpanan: $e');
      return false;
    }
  }
}

/// Implementasi penyimpanan memori untuk kebutuhan unit test dan simulasi kegagalan.
class InMemoryNotificationStorage implements NotificationStorage {
  final Set<String> _readIds;
  bool shouldFailOnSave;

  InMemoryNotificationStorage({
    Set<String>? initialReadIds,
    this.shouldFailOnSave = false,
  }) : _readIds = initialReadIds != null ? Set<String>.from(initialReadIds) : <String>{};

  @override
  Future<Set<String>> getReadNotificationIds() async {
    return Set<String>.unmodifiable(_readIds);
  }

  @override
  Future<bool> saveReadNotificationId(String id) async {
    if (shouldFailOnSave) {
      return false;
    }
    _readIds.add(id);
    return true;
  }

  @override
  Future<bool> saveAllReadNotificationIds(Set<String> ids) async {
    if (shouldFailOnSave) {
      return false;
    }
    _readIds.clear();
    _readIds.addAll(ids);
    return true;
  }
}
