import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../data/models/notification_model.dart';

class NotificationsProvider extends ChangeNotifier {
  List<NotificationModel> _items = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<NotificationModel> get notifications => List.unmodifiable(_items);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int get unreadCount => _items.where((n) => !n.read).length;

  Future<void> init() async {
    await fetchNotifications();
  }

  /// Ambil notifikasi dari backend (GET /api/notifications)
  Future<void> fetchNotifications() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await ApiClient.get('/notifications');
      if (res != null && res['notifications'] != null) {
        final list = (res['notifications'] as List<dynamic>)
            .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
            .toList();
        _items = list;
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Tambah notifikasi baru (lokal)
  void addNotification(NotificationModel n) {
    _items = [n, ..._items];
    notifyListeners();
  }

  /// Tandai 1 notifikasi sudah dibaca (PATCH /api/notifications/:id/read)
  Future<void> markRead(String id) async {
    final idx = _items.indexWhere((n) => n.id == id);
    if (idx < 0) return;
    if (_items[idx].read) return;

    _items[idx] = _items[idx].copyWith(read: true);
    notifyListeners();

    try {
      await ApiClient.patch('/notifications/$id/read');
    } catch (_) {}
  }

  /// Tandai semua notifikasi sudah dibaca (PATCH /api/notifications/read-all)
  Future<void> markAllRead() async {
    if (_items.every((n) => n.read)) return;
    _items = _items.map((n) => n.copyWith(read: true)).toList();
    notifyListeners();

    try {
      await ApiClient.patch('/notifications/read-all');
    } catch (_) {}
  }
}
