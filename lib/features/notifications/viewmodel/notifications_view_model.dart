import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../core/viewmodel/paged_state.dart';
import '../../../data/repositories/notification_repository.dart';
import '../../../data/models/notification_model.dart';
import '../../auth/viewmodel/auth_view_model.dart';

class NotificationsViewModel extends ChangeNotifier {
  NotificationsViewModel({required NotificationRepository repository}) : _repository = repository;
  final NotificationRepository _repository;
  final PagedState<NotificationModel> _list = PagedState(limit: 20);
  String? _userId;
  int _session = 0;
  int _revision = 0;
  int _unreadCount = 0;
  bool _disposed = false;
  String? _actionError;

  List<NotificationModel> get notifications => List.unmodifiable(_list.items);
  bool get isLoading => _list.isLoading;
  bool get isLoadingMore => _list.isLoadingMore;
  String? get errorMessage => _list.error;
  String? get actionError => _actionError;
  int get unreadCount => _unreadCount;
  int get total => _list.total;
  bool get hasMore => _list.hasMore;

  /// Dipanggil proxy; tidak melakukan notify sinkron ketika tree sedang dibangun.
  void updateAuth(AuthViewModel auth) {
    final next = auth.user?.id;
    if (_disposed || next == _userId) return;
    _userId = next;
    final session = ++_session;
    _revision++;
    _list.beginFirstPage();
    _list.items = [];
    _list.total = 0;
    _list.hasMore = false;
    _list.isLoading = false;
    _unreadCount = 0;
    _actionError = null;
    scheduleMicrotask(() {
      if (!_active(session)) return;
      _notify();
      if (_userId != null) unawaited(fetchNotifications());
    });
  }

  bool _active(int session) => !_disposed && session == _session;
  Future<void> init() => fetchNotifications();

  Future<void> fetchNotifications() async {
    if (_disposed || _userId == null) return;
    final session = _session;
    final revision = _revision;
    final id = _list.beginFirstPage();
    _notify();
    try {
      final result = await _repository.getNotifications(page: 1, limit: _list.limit);
      if (!_active(session) || _list.isStale(id) || revision != _revision) return;
      _list.applyFirstPage(result);
      _unreadCount = result.unreadCount ?? _list.items.where((n) => !n.read).length;
    } catch (e) {
      if (_active(session) && !_list.isStale(id)) _list.error = e.toString();
    } finally {
      if (_active(session) && !_list.isStale(id)) {
        _list.isLoading = false;
        _notify();
      }
    }
  }

  Future<void> loadMore() async {
    if (_disposed || _userId == null || isLoading || isLoadingMore || !hasMore) return;
    final session = _session;
    final revision = _revision;
    final id = _list.beginNextPage();
    _notify();
    try {
      final result = await _repository.getNotifications(page: _list.page + 1, limit: _list.limit);
      if (!_active(session) || _list.isStale(id) || revision != _revision) return;
      _list.applyNextPage(result);
      _unreadCount = result.unreadCount ?? _unreadCount;
    } catch (e) {
      if (_active(session) && !_list.isStale(id)) _list.error = e.toString();
    } finally {
      if (_active(session) && !_list.isStale(id)) {
        _list.isLoadingMore = false;
        _notify();
      }
    }
  }

  Future<void> markRead(String id) async {
    if (_disposed || _userId == null) return;
    final idx = _list.items.indexWhere((n) => n.id == id);
    if (idx < 0 || _list.items[idx].read) return;
    final session = _session;
    _revision++;
    _actionError = null;
    _list.items[idx] = _list.items[idx].copyWith(read: true);
    if (_unreadCount > 0) _unreadCount--;
    _notify();
    try { await _repository.markRead(id); }
    catch (e) { if (_active(session)) { _actionError = e.toString(); _notify(); } }
  }

  Future<void> markAllRead() async {
    if (_disposed || _userId == null || (_list.items.every((n) => n.read) && _unreadCount == 0)) return;
    final session = _session;
    _revision++;
    _actionError = null;
    _list.items = _list.items.map((n) => n.copyWith(read: true)).toList();
    _unreadCount = 0;
    _notify();
    try { await _repository.markAllRead(); }
    catch (e) { if (_active(session)) { _actionError = e.toString(); _notify(); } }
  }

  Future<void> deleteOne(String id) async {
    if (_disposed || _userId == null) return;
    final idx = _list.items.indexWhere((n) => n.id == id);
    if (idx < 0) return;
    final session = _session;
    _revision++;
    _actionError = null;
    final removed = _list.items.removeAt(idx);
    _list.total = (_list.total - 1).clamp(0, 999999);
    if (!removed.read && _unreadCount > 0) _unreadCount--;
    _notify();
    try { await _repository.deleteOne(id); }
    catch (e) {
      if (_active(session)) {
        _revision++;
        if (!_list.items.any((n) => n.id == id)) {
          _list.items.insert(idx.clamp(0, _list.items.length), removed);
          _list.total++;
          if (!removed.read) _unreadCount++;
        }
        _actionError = e.toString();
        _notify();
      }
      rethrow;
    }
  }

  Future<void> deleteAll() async {
    if (_disposed || _userId == null) return;
    final session = _session;
    _revision++;
    _actionError = null;
    final oldItems = List<NotificationModel>.of(_list.items);
    final oldTotal = _list.total;
    final oldUnread = _unreadCount;
    final oldHasMore = _list.hasMore;
    _list.items = [];
    _list.total = 0;
    _unreadCount = 0;
    _list.hasMore = false;
    _notify();
    try { await _repository.deleteAll(); }
    catch (e) {
      if (_active(session)) {
        _revision++;
        _list.items = oldItems;
        _list.total = oldTotal;
        _unreadCount = oldUnread;
        _list.hasMore = oldHasMore;
        _actionError = e.toString();
        _notify();
      }
      rethrow;
    }
  }

  void _notify() { if (!_disposed) notifyListeners(); }
  @override
  void dispose() { _disposed = true; _session++; super.dispose(); }
}
