import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../data/models/order_model.dart';

class OrdersProvider extends ChangeNotifier {
  List<OrderModel> _orders = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _errorMessage;

  int _page = 1;
  static const int _limit = 10;
  int _total = 0;
  bool _hasMore = false;

  List<OrderModel> get orders => List.unmodifiable(_orders);
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get errorMessage => _errorMessage;
  int get total => _total;
  bool get hasMore => _hasMore;

  List<OrderModel> ordersForUser(String userId) =>
      _orders.where((o) => o.userId == userId || userId.isEmpty).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  Future<void> init() async {
    await fetchOrders();
  }

  /// Ambil riwayat order dari backend (GET /api/orders?page=1&limit=10)
  Future<void> fetchOrders() async {
    _isLoading = true;
    _errorMessage = null;
    _page = 1;
    notifyListeners();

    try {
      final res = await ApiClient.get('/orders', queryParameters: {
        'page': _page,
        'limit': _limit,
      });
      if (res != null && res['orders'] != null) {
        final list = (res['orders'] as List<dynamic>)
            .map((e) => OrderModel.fromJson(e as Map<String, dynamic>))
            .toList();
        _orders = list;

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

  /// Muat halaman order berikutnya
  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    _isLoadingMore = true;
    notifyListeners();

    try {
      final nextPage = _page + 1;
      final res = await ApiClient.get('/orders', queryParameters: {
        'page': nextPage,
        'limit': _limit,
      });
      if (res != null && res['orders'] != null) {
        final list = (res['orders'] as List<dynamic>)
            .map((e) => OrderModel.fromJson(e as Map<String, dynamic>))
            .toList();
        _orders.addAll(list);
        _page = nextPage;

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
    } finally {
      _isLoadingMore = false;
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
    try {
      final res = await ApiClient.post('/orders/$id/pay');
      if (res != null && res['snap'] != null) {
        final snapData = res['snap'] as Map<String, dynamic>;
        final idx = _orders.indexWhere((o) => o.id == id);
        if (idx != -1) {
          _orders[idx] = _orders[idx].copyWith(snap: snapData);
          notifyListeners();
        }
        return snapData;
      }
      return null;
    } on ApiException catch (e) {
      // 409 PAYMENT_ALREADY_CREATED: Pembayaran sudah dibuat sebelumnya di Midtrans
      if (e.status == 409 || e.code == 'PAYMENT_ALREADY_CREATED') {
        final idx = _orders.indexWhere((o) => o.id == id);
        if (idx != -1 && _orders[idx].snap != null) {
          return _orders[idx].snap;
        }
      }
      rethrow;
    }
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
