import 'package:flutter/foundation.dart';
import '../../../core/viewmodel/paged_state.dart';
import '../../../data/models/review_model.dart';
import '../../../data/repositories/catalog_repositories.dart';

class MyReviewsViewModel extends ChangeNotifier {
  MyReviewsViewModel({required ReviewRepository repository}) : _repository = repository;
  final ReviewRepository _repository;
  final PagedState<ReviewModel> _page = PagedState<ReviewModel>(limit: 10);

  List<ReviewModel> get reviews => _page.items;
  bool get isLoading => _page.isLoading;
  bool get isLoadingMore => _page.isLoadingMore;
  bool get hasMore => _page.hasMore;
  String? get errorMessage => _page.error;

  Future<void> load() async {
    final requestId = _page.beginFirstPage();
    notifyListeners();
    try {
      final result = await _repository.getMyReviews(page: 1, limit: _page.limit);
      if (_page.isStale(requestId)) return;
      _page.applyFirstPage(result);
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
      final result = await _repository.getMyReviews(page: _page.page + 1, limit: _page.limit);
      if (_page.isStale(requestId)) return;
      _page.applyNextPage(result);
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
