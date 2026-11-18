import 'package:flutter/foundation.dart';
import '../../../data/models/order_model.dart';
import '../../../data/repositories/order_repository.dart';
import '../../../data/repositories/catalog_repositories.dart';

class WriteReviewViewModel extends ChangeNotifier {
  WriteReviewViewModel(this.orderId, {required OrderRepository orders, required ReviewRepository reviews})
      : _orders = orders, _reviews = reviews;
  final String orderId;
  final OrderRepository _orders;
  final ReviewRepository _reviews;
  OrderModel? _order;
  int _rating = 0;
  int get rating => _rating;
  bool _isSubmitting = false;
  bool get isSubmitting => _isSubmitting;
  String? _errorMessage;
  String? get errorMessage => _errorMessage;
  bool _disposed = false;
  void setRating(int rating) { _rating = rating; _notify(); }

  Future<bool> submit(String comment) async {
    if (_disposed || _isSubmitting) return false;
    if (_rating == 0 || comment.trim().isEmpty) {
      _errorMessage = 'Pilih rating dan tulis komentar';
      _notify();
      return false;
    }
    _isSubmitting = true;
    _errorMessage = null;
    _notify();
    try {
      // Detail dimuat sendiri agar tautan langsung tidak bergantung cache daftar.
      _order = await _orders.getOrder(orderId);
      if (_disposed) return false;
      final items = _order!.items;
      await _reviews.submit(orderItemId: items.isNotEmpty ? items.first.id : null,
          rating: _rating, comment: comment.trim());
      return !_disposed;
    } catch (e) {
      _errorMessage = 'Gagal mengirim ulasan: $e';
      return false;
    } finally { _isSubmitting = false; _notify(); }
  }

  void _notify() { if (!_disposed) notifyListeners(); }
  @override
  void dispose() { _disposed = true; super.dispose(); }
}
