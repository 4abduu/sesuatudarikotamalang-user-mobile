import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../data/models/review_model.dart';

class ReviewsProvider extends ChangeNotifier {
  List<ReviewModel> _reviews = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _errorMessage;

  int _page = 1;
  static const int _limit = 10;
  int _total = 0;
  bool _hasMore = false;

  // Data ringkasan ulasan toko & ulasan kurasi toko (landing page)
  double _storeRating = 0.0;
  int _storeReviewTotal = 0;
  List<ReviewModel> _storeReviews = [];
  bool _isLoadingStoreReviews = false;

  List<ReviewModel> get reviews => List.unmodifiable(_reviews);
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get errorMessage => _errorMessage;
  int get total => _total;
  bool get hasMore => _hasMore;

  double get storeRating => _storeRating;
  int get storeReviewTotal => _storeReviewTotal;
  List<ReviewModel> get storeReviews => List.unmodifiable(_storeReviews);
  bool get isLoadingStoreReviews => _isLoadingStoreReviews;

  Future<void> init() async {
    await fetchStoreReviews();
    await fetchMyReviews();
  }

  /// Ambil ulasan toko & rating toko publik (GET /api/reviews)
  Future<void> fetchStoreReviews() async {
    _isLoadingStoreReviews = true;
    notifyListeners();

    try {
      final res = await ApiClient.get('/reviews');
      if (res != null) {
        if (res['avgRating'] != null) {
          _storeRating = (res['avgRating'] as num).toDouble();
        }
        if (res['totalReviews'] != null) {
          _storeReviewTotal = (res['totalReviews'] as num).toInt();
        }
        if (res['reviews'] != null) {
          final all = (res['reviews'] as List<dynamic>)
              .map((e) => ReviewModel.fromJson(e as Map<String, dynamic>))
              .toList();
          // Filter ulasan umum toko (tanpa productId spesifik)
          final curated = all.where((r) => r.productId == null || r.productId!.isEmpty).toList();
          _storeReviews = curated.isNotEmpty ? curated : all;
        }
      }
    } catch (_) {
      // Biarkan fallback default jika offline/gagal
    } finally {
      _isLoadingStoreReviews = false;
      notifyListeners();
    }
  }

  /// Ambil ulasan milik pengguna yang login (GET /api/reviews/mine?page=1&limit=10)
  Future<void> fetchMyReviews() async {
    _isLoading = true;
    _errorMessage = null;
    _page = 1;
    notifyListeners();

    try {
      final res = await ApiClient.get('/reviews/mine', queryParameters: {
        'page': _page,
        'limit': _limit,
      });
      if (res != null && res['reviews'] != null) {
        final list = (res['reviews'] as List<dynamic>)
            .map((e) => ReviewModel.fromJson(e as Map<String, dynamic>))
            .toList();
        _reviews = list;

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

  /// Muat halaman ulasan berikutnya
  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    _isLoadingMore = true;
    notifyListeners();

    try {
      final nextPage = _page + 1;
      final res = await ApiClient.get('/reviews/mine', queryParameters: {
        'page': nextPage,
        'limit': _limit,
      });
      if (res != null && res['reviews'] != null) {
        final list = (res['reviews'] as List<dynamic>)
            .map((e) => ReviewModel.fromJson(e as Map<String, dynamic>))
            .toList();
        _reviews.addAll(list);
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

  /// Ambil ulasan produk tertentu (default 3 ulasan terbaru untuk preview)
  Future<List<ReviewModel>> fetchProductReviews(String productId, {int limit = 3}) async {
    try {
      final res = await ApiClient.get('/products/$productId/reviews', queryParameters: {
        'page': 1,
        'limit': limit,
      });
      if (res != null && res['reviews'] != null) {
        return (res['reviews'] as List<dynamic>)
            .map((e) => ReviewModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {
      try {
        final legacyRes = await ApiClient.get('/reviews', queryParameters: {'productId': productId});
        if (legacyRes != null && legacyRes['reviews'] != null) {
          return (legacyRes['reviews'] as List<dynamic>)
              .map((e) => ReviewModel.fromJson(e as Map<String, dynamic>))
              .take(limit)
              .toList();
        }
      } catch (_) {}
    }
    return _reviews.where((r) => r.productId == productId).take(limit).toList();
  }

  /// Ambil ulasan produk lengkap dengan paginasi dan filter rating
  Future<ProductReviewsResult> getProductReviewsPaginated(
    String productId, {
    int? rating,
    int page = 1,
    int limit = 10,
  }) async {
    final query = <String, dynamic>{
      'page': page,
      'limit': limit,
      if (rating != null && rating >= 1 && rating <= 5) 'rating': rating,
    };
    final res = await ApiClient.get('/products/$productId/reviews', queryParameters: query);
    if (res != null) {
      return ProductReviewsResult.fromJson(res);
    }
    throw ApiException(500, 'Gagal memuat ulasan produk.');
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
