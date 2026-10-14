import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../data/models/order_model.dart';

class OrdersProvider extends ChangeNotifier {
  List<OrderModel> _orders = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<OrderModel> get orders => List.unmodifiable(_orders);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<OrderModel> ordersForUser(String userId) =>
      _orders.where((o) => o.userId == userId || userId.isEmpty).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  Future<void> init() async {
    await fetchOrders();
  }

  /// Ambil riwayat order dari backend (GET /api/orders)
  Future<void> fetchOrders() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await ApiClient.get('/orders');
      if (res != null && res['orders'] != null) {
        final list = (res['orders'] as List<dynamic>)
            .map((e) => OrderModel.fromJson(e as Map<String, dynamic>))
            .toList();
        _orders = list;
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Ambil detail order dari backend (GET /api/orders/:id)
  Future<OrderModel?> getOrderDetail(String id) async {
    try {
      final res = await ApiClient.get('/orders/$id');
      if (res != null && res['order'] != null) {
        final order = OrderModel.fromJson(res['order'] as Map<String, dynamic>);
        final idx = _orders.indexWhere((o) => o.id == id);
        if (idx != -1) {
          _orders[idx] = order;
        } else {
          _orders.insert(0, order);
        }
        notifyListeners();
        return order;
      }
    } catch (_) {}
    return _orders.cast<OrderModel?>().firstWhere((o) => o?.id == id, orElse: () => null);
  }

  /// Buat reservasi order baru (POST /api/orders)
  Future<OrderModel> createOrder({
    required String productId,
    String? variantId,
    required DateTime pickupDate,
    required String pickupSlot,
    required String paymentMethod, // "midtrans" | "cod"
  }) async {
    final body = <String, dynamic>{
      'productId': productId,
      if (variantId != null && variantId.isNotEmpty) 'variantId': variantId,
      'pickupDate': pickupDate.toIso8601String().substring(0, 10),
      'pickupSlot': pickupSlot,
      'paymentMethod': paymentMethod.toLowerCase(),
    };

    final res = await ApiClient.post('/orders', body: body);
    if (res != null && res['order'] != null) {
      final orderMap = res['order'] as Map<String, dynamic>;
      if (res['snap'] != null) {
        orderMap['snap'] = res['snap'];
      }
      final newOrder = OrderModel.fromJson(orderMap);
      _orders.insert(0, newOrder);
      notifyListeners();
      return newOrder;
    }
    throw ApiException(500, 'Gagal membuat reservasi.');
  }

  /// Batalkan order (PATCH /api/orders/:id/cancel)
  Future<void> cancelOrder(String id) async {
    final res = await ApiClient.patch('/orders/$id/cancel');
    if (res != null && res['order'] != null) {
      final updated = OrderModel.fromJson(res['order'] as Map<String, dynamic>);
      final idx = _orders.indexWhere((o) => o.id == id);
      if (idx != -1) {
        _orders[idx] = updated;
        notifyListeners();
      }
    }
  }

  /// Bayar ulang order Midtrans yang menunggu bayar (POST /api/orders/:id/pay)
  Future<Map<String, dynamic>?> payAgain(String id) async {
    final res = await ApiClient.post('/orders/$id/pay');
    if (res != null && res['snap'] != null) {
      return res['snap'] as Map<String, dynamic>;
    }
    return null;
  }

  void addOrder(OrderModel order) {
    _orders.insert(0, order);
    notifyListeners();
  }

  void setStatus(String id, OrderStatus status) {
    final idx = _orders.indexWhere((o) => o.id == id);
    if (idx != -1) {
      _orders[idx] = _orders[idx].copyWith(status: status);
      notifyListeners();
    }
  }

  void markReviewed(String id) {
    final idx = _orders.indexWhere((o) => o.id == id);
    if (idx != -1) {
      _orders[idx] = _orders[idx].copyWith(reviewed: true);
      notifyListeners();
    }
  }
}
