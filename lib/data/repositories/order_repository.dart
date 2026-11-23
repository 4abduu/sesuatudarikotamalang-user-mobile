import 'package:shared_preferences/shared_preferences.dart';
import '../../core/network/api_service.dart';
import '../../core/network/api_exception.dart';
import '../../core/viewmodel/paged_state.dart';
import '../models/order_model.dart';

class OrderRepository {
  OrderRepository(this._api);
  final ApiService _api;
  static final Set<String> _reviewedOrderIds = <String>{};
  static bool _prefsLoaded = false;
  static const _prefsKey = 'reviewed_order_ids_cache';

  static Future<void> _ensureLoaded() async {
    if (_prefsLoaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_prefsKey) ?? [];
      _reviewedOrderIds.addAll(list);
      _prefsLoaded = true;
    } catch (_) {}
  }

  static void markAsReviewed(String orderId) {
    if (orderId.isEmpty) return;
    _reviewedOrderIds.add(orderId);
    SharedPreferences.getInstance().then((prefs) {
      prefs.setStringList(_prefsKey, _reviewedOrderIds.toList());
    }).catchError((_) {});
  }

  static bool isReviewedLocally(String orderId) => _reviewedOrderIds.contains(orderId);

  Future<PageResult<OrderModel>> getOrders({int page = 1, int limit = 10}) async {
    await _ensureLoaded();
    final res = await _api.get('/orders', query: {'page': page, 'limit': limit});
    final orders = ((res?['orders'] as List?) ?? [])
        .map((item) {
          final model = OrderModel.fromJson(item as Map<String, dynamic>);
          if (_reviewedOrderIds.contains(model.id)) {
            return model.copyWith(reviewed: true);
          }
          return model;
        }).toList();
    final pagination = res?['pagination'] as Map<String, dynamic>?;
    return PageResult(items: orders,
      total: (pagination?['total'] as num?)?.toInt() ?? orders.length,
      totalPages: (pagination?['totalPages'] as num?)?.toInt() ?? 1);
  }

  Future<OrderModel> getOrder(String id) async {
    await _ensureLoaded();
    final res = await _api.get('/orders/$id');
    final model = OrderModel.fromJson(res['order'] as Map<String, dynamic>);
    if (_reviewedOrderIds.contains(model.id)) {
      return model.copyWith(reviewed: true);
    }
    return model;
  }

  Future<OrderModel> create({required String productId, String? variantId,
    required DateTime pickupDate, required String pickupSlot, required String paymentMethod, int quantity = 1}) async {
    final res = await _api.post('/orders', body: {
      'productId': productId,
      if (variantId != null && variantId.isNotEmpty) 'variantId': variantId,
      'pickupDate': pickupDate.toIso8601String().substring(0, 10),
      'pickupSlot': pickupSlot,
      'paymentMethod': paymentMethod.toLowerCase(),
      'quantity': quantity,
    });
    if (res?['order'] == null) throw ApiException(500, 'Gagal membuat pembelian.');
    final order = Map<String, dynamic>.from(res['order'] as Map);
    if (res['snap'] != null) order['snap'] = res['snap'];
    return OrderModel.fromJson(order);
  }

  Future<OrderModel> createMany({required List<Map<String, dynamic>> items, required DateTime pickupDate, required String pickupSlot, required String paymentMethod, String source = 'direct'}) async {
    final res = await _api.post('/orders', body: {'items': items, 'source': source, 'pickupDate': pickupDate.toIso8601String().substring(0, 10), 'pickupSlot': pickupSlot, 'paymentMethod': paymentMethod.toLowerCase()});
    if (res?['order'] == null) throw ApiException(500, 'Gagal membuat pembelian.');
    final order = Map<String, dynamic>.from(res['order'] as Map);
    if (res['snap'] != null) order['snap'] = res['snap'];
    return OrderModel.fromJson(order);
  }

  Future<OrderModel?> cancel(String id) async {
    final res = await _api.patch('/orders/$id/cancel');
    return res?['order'] == null ? null : OrderModel.fromJson(res['order'] as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>?> pay(String id) async {
    final res = await _api.post('/orders/$id/pay');
    return res?['snap'] as Map<String, dynamic>?;
  }
}
