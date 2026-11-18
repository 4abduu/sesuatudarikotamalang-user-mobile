import '../../core/network/api_service.dart';
import '../../core/network/api_exception.dart';
import '../../core/viewmodel/paged_state.dart';
import '../models/order_model.dart';

class OrderRepository {
  OrderRepository(this._api);
  final ApiService _api;

  Future<PageResult<OrderModel>> getOrders({int page = 1, int limit = 10}) async {
    final res = await _api.get('/orders', query: {'page': page, 'limit': limit});
    final orders = ((res?['orders'] as List?) ?? [])
        .map((item) => OrderModel.fromJson(item as Map<String, dynamic>)).toList();
    final pagination = res?['pagination'] as Map<String, dynamic>?;
    return PageResult(items: orders,
      total: (pagination?['total'] as num?)?.toInt() ?? orders.length,
      totalPages: (pagination?['totalPages'] as num?)?.toInt() ?? 1);
  }

  Future<OrderModel> getOrder(String id) async {
    final res = await _api.get('/orders/$id');
    return OrderModel.fromJson(res['order'] as Map<String, dynamic>);
  }

  Future<OrderModel> create({required String productId, String? variantId,
    required DateTime pickupDate, required String pickupSlot, required String paymentMethod}) async {
    final res = await _api.post('/orders', body: {
      'productId': productId,
      if (variantId != null && variantId.isNotEmpty) 'variantId': variantId,
      'pickupDate': pickupDate.toIso8601String().substring(0, 10),
      'pickupSlot': pickupSlot,
      'paymentMethod': paymentMethod.toLowerCase(),
    });
    if (res?['order'] == null) throw ApiException(500, 'Gagal membuat reservasi.');
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
