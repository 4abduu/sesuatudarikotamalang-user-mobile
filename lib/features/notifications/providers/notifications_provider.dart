import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../data/models/notification_model.dart';

class NotificationsProvider extends ChangeNotifier {
  List<NotificationModel> _items = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _errorMessage;

  int _page = 1;
  static const int _limit = 20;
  int _total = 0;
  bool _hasMore = false;
  int _unreadCount = 0;

  List<NotificationModel> get notifications => List.unmodifiable(_items);
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get errorMessage => _errorMessage;

  int get unreadCount => _unreadCount;
  int get total => _total;
  bool get hasMore => _hasMore;

  Future<void> init() async {
    await fetchNotifications();
  }

  /// Ambil notifikasi dari backend (GET /api/notifications?page=1&limit=20)
  Future<void> fetchNotifications() async {
    _isLoading = true;
    _errorMessage = null;
    _page = 1;
    notifyListeners();

    try {
      final res = await ApiClient.get('/notifications', queryParameters: {
        'page': _page,
        'limit': _limit,
      });
      if (res != null && res['notifications'] != null) {
        final list = (res['notifications'] as List<dynamic>)
            .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
            .toList();
        _items = list;
        _unreadCount = (res['unreadCount'] as num?)?.toInt() ?? _items.where((n) => !n.read).length;

        final pagination = res['pagination'] as Map<String, dynamic>?;
        if (pagination != null) {
          _total = (pagination['total'] as num?)?.toInt() ?? list.length;
          final totalPages = (pagination['totalPages'] as num?)?.toInt() ?? 1;
          _hasMore = _page < totalPages;
        } else {
          _total = list.length;
          _hasMore = false;
        }
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Muat halaman berikutnya (infinite scroll)
  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    _isLoadingMore = true;
    notifyListeners();

    try {
      final nextPage = _page + 1;
      final res = await ApiClient.get('/notifications', queryParameters: {
        'page': nextPage,
        'limit': _limit,
      });
      if (res != null && res['notifications'] != null) {
        final list = (res['notifications'] as List<dynamic>)
            .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
            .toList();
        _items.addAll(list);
        _page = nextPage;
        _unreadCount = (res['unreadCount'] as num?)?.toInt() ?? _unreadCount;

        final pagination = res['pagination'] as Map<String, dynamic>?;
        if (pagination != null) {
          _total = (pagination['total'] as num?)?.toInt() ?? _total;
          final totalPages = (pagination['totalPages'] as num?)?.toInt() ?? 1;
          _hasMore = _page < totalPages;
        } else {
          _hasMore = false;
        }
      }
    } catch (_) {
      // Diamkan error saat load more agar tidak mengganggu list yang sudah tampil
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  /// Tambah notifikasi baru (lokal)
  void addNotification(NotificationModel n) {
    _items = [n, ..._items];
    _total++;
    if (!n.read) _unreadCount++;
    notifyListeners();
  }

  /// Tandai 1 notifikasi sudah dibaca (PATCH /api/notifications/:id/read)
  Future<void> markRead(String id) async {
    final idx = _items.indexWhere((n) => n.id == id);
    if (idx < 0) return;
    if (_items[idx].read) return;

    _items[idx] = _items[idx].copyWith(read: true);
    if (_unreadCount > 0) _unreadCount--;
    notifyListeners();

    try {
      await ApiClient.patch('/notifications/$id/read');
    } catch (_) {}
  }

  /// Tandai semua notifikasi sudah dibaca (PATCH /api/notifications/read-all)
  Future<void> markAllRead() async {
    if (_items.every((n) => n.read) && _unreadCount == 0) return;
    _items = _items.map((n) => n.copyWith(read: true)).toList();
    _unreadCount = 0;
    notifyListeners();

    try {
      await ApiClient.patch('/notifications/read-all');
    } catch (_) {}
  }

  /// Hapus 1 notifikasi (DELETE /api/notifications/:id) secara optimistik
  Future<void> deleteOne(String id) async {
    final idx = _items.indexWhere((n) => n.id == id);
    if (idx < 0) return;

    final removed = _items.removeAt(idx);
    _total = (_total - 1).clamp(0, 999999);
    if (!removed.read && _unreadCount > 0) {
      _unreadCount--;
    }
    notifyListeners();

    try {
      await ApiClient.delete('/notifications/$id');
    } catch (e) {
      // Rollback jika gagal
      _items.insert(idx, removed);
      _total++;
      if (!removed.read) _unreadCount++;
      notifyListeners();
      rethrow;
    }
  }

  /// Hapus seluruh notifikasi (DELETE /api/notifications)
  Future<void> deleteAll() async {
    final oldItems = List<NotificationModel>.from(_items);
    final oldTotal = _total;
    final oldUnread = _unreadCount;

    _items = [];
    _total = 0;
    _unreadCount = 0;
    _hasMore = false;
    notifyListeners();

    try {
      await ApiClient.delete('/notifications');
    } catch (e) {
      // Rollback jika gagal
      _items = oldItems;
      _total = oldTotal;
      _unreadCount = oldUnread;
      notifyListeners();
      rethrow;
    }
  }
}
