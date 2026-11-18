import 'package:flutter/foundation.dart';
import '../../../core/viewmodel/paged_state.dart';
import '../../../data/models/order_model.dart';
import '../../../data/repositories/order_repository.dart';

class OrdersViewModel extends ChangeNotifier {
  OrdersViewModel({required OrderRepository repository}) : _repository = repository;
  final OrderRepository _repository;
  final PagedState<OrderModel> list = PagedState(limit: 10);
  bool _disposed = false;
  List<OrderModel> get orders => List.unmodifiable(list.items);
  bool get isLoading => list.isLoading;
  bool get isLoadingMore => list.isLoadingMore;
  String? get errorMessage => list.error;
  int get total => list.total;
  bool get hasMore => list.hasMore;

  List<OrderModel> ordersForUser(String userId) =>
      list.items.where((o) => o.userId == userId || userId.isEmpty).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  Future<void> fetchOrders() async {
    if (_disposed) return;
    final id = list.beginFirstPage();
    _notify();
    try {
      final result = await _repository.getOrders(page: 1, limit: list.limit);
      if (_disposed || list.isStale(id)) return;
      list.applyFirstPage(result);
    } catch (e) {
      if (_disposed || list.isStale(id)) return;
      list.error = e.toString();
    } finally {
      if (!_disposed && !list.isStale(id)) { list.isLoading = false; _notify(); }
    }
  }

  Future<void> loadMore() async {
    if (_disposed || list.isLoading || list.isLoadingMore || !list.hasMore) return;
    final id = list.beginNextPage();
    _notify();
    try {
      final result = await _repository.getOrders(page: list.page + 1, limit: list.limit);
      if (_disposed || list.isStale(id)) return;
      list.applyNextPage(result);
    } catch (e) {
      if (_disposed || list.isStale(id)) return;
      list.error = e.toString();
    } finally {
      if (!_disposed && !list.isStale(id)) { list.isLoadingMore = false; _notify(); }
    }
  }

  Future<OrderModel?> getOrderDetail(String id) async {
    try {
      final order = await _repository.getOrder(id);
      final index = list.items.indexWhere((item) => item.id == id);
      if (index >= 0) {
        list.items[index] = order;
      } else {
        list.items.insert(0, order);
      }
      _notify();
      return order;
    } catch (_) {
      return list.items.where((item) => item.id == id).firstOrNull;
    }
  }

  void _notify() { if (!_disposed) notifyListeners(); }
  @override
  void dispose() { _disposed = true; super.dispose(); }
}
