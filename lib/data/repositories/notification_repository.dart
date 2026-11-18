import '../../core/network/api_service.dart';
import '../../core/viewmodel/paged_state.dart';
import '../models/notification_model.dart';

class NotificationPage extends PageResult<NotificationModel> {
  const NotificationPage({required super.items, required super.total,
    required super.totalPages, this.unreadCount});
  final int? unreadCount;
}

abstract class NotificationRepository {
  Future<NotificationPage> getNotifications({required int page, required int limit});
  Future<void> markRead(String id);
  Future<void> markAllRead();
  Future<void> deleteOne(String id);
  Future<void> deleteAll();
}

class NotificationRepositoryImpl implements NotificationRepository {
  NotificationRepositoryImpl(this._api);
  final ApiService _api;

  @override
  Future<NotificationPage> getNotifications({required int page, required int limit}) async {
    final res = await _api.get('/notifications', query: {'page': page, 'limit': limit});
    final items = ((res?['notifications'] as List?) ?? const [])
        .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>)).toList();
    final pg = res?['pagination'] as Map<String, dynamic>?;
    return NotificationPage(items: items,
      total: (pg?['total'] as num?)?.toInt() ?? items.length,
      totalPages: (pg?['totalPages'] as num?)?.toInt() ?? 1,
      unreadCount: (res?['unreadCount'] as num?)?.toInt());
  }

  @override
  Future<void> markRead(String id) async { await _api.patch('/notifications/$id/read'); }
  @override
  Future<void> markAllRead() async { await _api.patch('/notifications/read-all'); }
  @override
  Future<void> deleteOne(String id) async { await _api.delete('/notifications/$id'); }
  @override
  Future<void> deleteAll() async { await _api.delete('/notifications'); }
}
