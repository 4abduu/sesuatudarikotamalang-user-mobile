import 'package:flutter/foundation.dart';
import '../../../core/network/api_exception.dart';
import '../../../data/models/order_model.dart';
import '../../../data/repositories/order_repository.dart';
import '../../../data/repositories/catalog_repositories.dart';

class WriteReviewViewModel extends ChangeNotifier {
  WriteReviewViewModel(this.orderId, {this.itemId, required OrderRepository orders, required ReviewRepository reviews})
      : _orders = orders, _reviews = reviews;
  final String orderId;
  final String? itemId;
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
      final matching = itemId == null || itemId!.isEmpty ? items : items.where((item) => item.id == itemId).toList();
      final target = matching.length == 1 ? matching.first : null;
      if (target == null) {
        _errorMessage = 'Pilih item pesanan yang akan diulas.';
        return false;
      }
      final targetItemId = target.id;
      await _reviews.submit(orderItemId: targetItemId,
          rating: _rating, comment: comment.trim());
      // Catat secara lokal bahwa order ini sudah diulas
      if (orderId.isNotEmpty) {
        OrderRepository.markAsReviewed(orderId);
      }
      return !_disposed;
    } on ApiException catch (e) {
      if (e.message.toLowerCase().contains('sudah') || e.code == 'ALREADY_REVIEWED') {
        if (orderId.isNotEmpty) {
          OrderRepository.markAsReviewed(orderId);
        }
      }
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = 'Gagal mengirim ulasan: $e';
      return false;
    } finally { _isSubmitting = false; _notify(); }
  }

  void _notify() { if (!_disposed) notifyListeners(); }
  @override
  void dispose() { _disposed = true; super.dispose(); }
}
