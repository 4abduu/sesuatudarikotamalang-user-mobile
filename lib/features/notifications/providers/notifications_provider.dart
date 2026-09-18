import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/dummy/dummy_notifications.dart';
import '../../../data/models/notification_model.dart';

/// Persists user notifications in SharedPreferences (key: sdkm-notifications).
/// Seeds from [dummyNotifications] on first launch.
///
/// Exposes:
///   - [notifications] (newest first)
///   - [unreadCount]
///   - [addNotification] (prepends + persists)
///   - [markRead(id)]
///   - [markAllRead]
class NotificationsProvider extends ChangeNotifier {
  List<NotificationModel> _items = [];
  bool _hydrated = false;
  static const _key = 'sdkm-notifications';

  List<NotificationModel> get notifications => List.unmodifiable(_items);
  bool get hydrated => _hydrated;

  int get unreadCount => _items.where((n) => !n.read).length;

  Future<void> init() async {
    try {
      final sp = await SharedPreferences.getInstance();
      final raw = sp.getString(_key);
      if (raw != null) {
        final list = jsonDecode(raw) as List;
        _items = list.map((j) => _fromJson(j as Map<String, dynamic>)).toList();
      } else {
        _items = List.from(dummyNotifications);
        await _persist();
      }
    } catch (_) {
      _items = List.from(dummyNotifications);
    }
    _hydrated = true;
    notifyListeners();
  }

  Future<void> addNotification(NotificationModel n) async {
    _items = [n, ..._items];
    notifyListeners();
    await _persist();
  }

  Future<void> markRead(String id) async {
    final idx = _items.indexWhere((n) => n.id == id);
    if (idx < 0) return;
    if (_items[idx].read) return;
    _items[idx] = _copyWith(_items[idx], read: true);
    notifyListeners();
    await _persist();
  }

  Future<void> markAllRead() async {
    if (_items.every((n) => n.read)) return;
    _items = _items.map((n) => n.read ? n : _copyWith(n, read: true)).toList();
    notifyListeners();
    await _persist();
  }

  Future<void> _persist() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_key, jsonEncode(_items.map(_toJson).toList()));
  }

  static NotificationModel _copyWith(NotificationModel n, {bool? read}) =>
    NotificationModel(id: n.id, type: n.type, title: n.title, body: n.body, date: n.date, read: read ?? n.read);

  static NotificationModel _fromJson(Map<String, dynamic> j) => NotificationModel(
    id: j['id'] as String,
    type: _typeFromStr(j['type'] as String),
    title: j['title'] as String,
    body: j['body'] as String,
    date: j['date'] as String,
    read: (j['read'] as bool?) ?? false,
  );

  static Map<String, dynamic> _toJson(NotificationModel n) => {
    'id': n.id, 'type': _typeToStr(n.type), 'title': n.title,
    'body': n.body, 'date': n.date, 'read': n.read,
  };

  static NotificationType _typeFromStr(String s) {
    switch (s) {
      case 'order': return NotificationType.order;
      case 'review': return NotificationType.review;
      case 'creator': return NotificationType.creator;
      default: return NotificationType.system;
    }
  }

  static String _typeToStr(NotificationType t) {
    switch (t) {
      case NotificationType.order: return 'order';
      case NotificationType.review: return 'review';
      case NotificationType.creator: return 'creator';
      case NotificationType.system: return 'system';
    }
  }
}
