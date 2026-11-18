import 'package:flutter/foundation.dart';
import '../../../core/viewmodel/paged_state.dart';
import '../../../data/models/review_model.dart';
import '../../../data/repositories/catalog_repositories.dart';

class ProductReviewsViewModel extends ChangeNotifier {
  ProductReviewsViewModel({required this.productId, required ReviewRepository repository})
      : _repository = repository;

  final String productId;
  final ReviewRepository _repository;
  final PagedState<ReviewModel> _page = PagedState<ReviewModel>(limit: 10);
  ProductReviewsSummary? _summary;
  int? _rating;

  List<ReviewModel> get reviews => _page.items;
  ProductReviewsSummary? get summary => _summary;
  bool get isLoading => _page.isLoading;
  bool get isLoadingMore => _page.isLoadingMore;
  bool get hasMore => _page.hasMore;
  String? get errorMessage => _page.error;
  int? get selectedRating => _rating;

  Future<ProductReviewsResult> fetchPage({int? rating, required int page, int? limit}) =>
      _repository.getProductReviewsPaginated(productId, rating: rating, page: page, limit: limit ?? _page.limit);

  Future<void> load({int? rating}) async {
    _rating = rating;
    final requestId = _page.beginFirstPage();
    notifyListeners();
    try {
      final result = await _repository.getProductReviewsPaginated(productId, rating: rating, page: 1, limit: _page.limit);
      if (_page.isStale(requestId)) return;
      _page.applyFirstPage(PageResult(items: result.reviews, total: result.total, totalPages: result.totalPages));
      _summary = result.summary;
    } catch (error) {
      if (!_page.isStale(requestId)) _page.error = error.toString();
    } finally {
      if (!_page.isStale(requestId)) {
        _page.isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> loadMore() async {
    if (_page.isLoadingMore || !_page.hasMore) return;
    final requestId = _page.beginNextPage();
    notifyListeners();
    try {
      final next = _page.page + 1;
      final result = await _repository.getProductReviewsPaginated(productId, rating: _rating, page: next, limit: _page.limit);
      if (_page.isStale(requestId)) return;
      _page.applyNextPage(PageResult(items: result.reviews, total: result.total, totalPages: result.totalPages));
      _summary = result.summary;
    } catch (error) {
      if (!_page.isStale(requestId)) _page.error = error.toString();
    } finally {
      if (!_page.isStale(requestId)) {
        _page.isLoadingMore = false;
        notifyListeners();
      }
    }
  }
}
