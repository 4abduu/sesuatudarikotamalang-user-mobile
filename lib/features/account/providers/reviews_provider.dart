import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../data/models/review_model.dart';
import '../../../data/dummy/dummy_reviews.dart';

class ReviewsProvider extends ChangeNotifier {
  List<ReviewModel> _reviews = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<ReviewModel> get reviews => List.unmodifiable(_reviews);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> init() async {
    await fetchMyReviews();
  }

  /// Ambil ulasan milik pengguna yang login (GET /api/reviews/mine)
  Future<void> fetchMyReviews() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await ApiClient.get('/reviews/mine');
      if (res != null && res['reviews'] != null) {
        final list = (res['reviews'] as List<dynamic>)
            .map((e) => ReviewModel.fromJson(e as Map<String, dynamic>))
            .toList();
        _reviews = list;
      }
    } catch (e) {
      _errorMessage = e.toString();
      if (_reviews.isEmpty) {
        _reviews = List.from(dummyReviews);
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Ambil ulasan produk tertentu (GET /api/reviews?productId=...)
  Future<List<ReviewModel>> fetchProductReviews(String productId) async {
    try {
      final res = await ApiClient.get('/reviews', queryParameters: {'productId': productId});
      if (res != null && res['reviews'] != null) {
        return (res['reviews'] as List<dynamic>)
            .map((e) => ReviewModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
    return _reviews.where((r) => r.productId == productId).toList();
  }

  /// Kirim ulasan baru (POST /api/reviews)
  Future<ReviewModel> submitReview({
    String? orderItemId,
    required int rating,
    required String comment,
  }) async {
    final body = <String, dynamic>{
      if (orderItemId != null && orderItemId.isNotEmpty) 'orderItemId': orderItemId,
      'rating': rating,
      'comment': comment,
    };

    final res = await ApiClient.post('/reviews', body: body);
    if (res != null && res['review'] != null) {
      final newRev = ReviewModel.fromJson(res['review'] as Map<String, dynamic>);
      _reviews.insert(0, newRev);
      notifyListeners();
      return newRev;
    }
    throw ApiException(500, 'Gagal mengirim ulasan.');
  }

  List<ReviewModel> reviewsForProduct(String productId) =>
      _reviews.where((r) => r.productId == productId).toList();

  List<ReviewModel> reviewsByUser(String userName) =>
      _reviews.where((r) => r.author == userName).toList();
}
