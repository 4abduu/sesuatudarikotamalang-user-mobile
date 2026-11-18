import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../data/models/creator_model.dart';
import '../../../data/models/product_model.dart';
import '../../../data/repositories/catalog_repositories.dart';

class SearchViewModel extends ChangeNotifier {
  SearchViewModel({required SearchRepository repository}) : _repository = repository;
  final SearchRepository _repository;
  List<ProductModel> _products = [];
  List<CreatorModel> _creators = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _errorMessage;
  Timer? _debounceTimer;
  int _searchRequestId = 0;

  String _lastQuery = '';
  int _page = 1;
  static const int _limit = 12;
  int _totalProducts = 0;
  bool _hasMore = false;

  List<ProductModel> get products => _products;
  List<CreatorModel> get creators => _creators;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get errorMessage => _errorMessage;
  int get totalProducts => _totalProducts;
  bool get hasMore => _hasMore;

  /// Global Search (GET /api/search?q=) dengan debounce 400ms dan paginasi produk
  void search(String query) {
    _debounceTimer?.cancel();

    final q = query.trim();
    if (q.isEmpty) {
      clear();
      return;
    }

    _lastQuery = q;
    final currentRequestId = ++_searchRequestId;
    _isLoading = true;
    _isLoadingMore = false;
    _errorMessage = null;
    _page = 1;
    notifyListeners();

    // Debounce 400 ms
    _debounceTimer = Timer(const Duration(milliseconds: 400), () async {

      try {
        final result = await _repository.search(q, page: _page, limit: _limit);
        // Abaikan hasil jika ada request pencarian baru yang masuk setelah ini
        if (currentRequestId != _searchRequestId) return;

        _products = result.products;
        _creators = result.creators;
        _totalProducts = result.page.total;
        _hasMore = _page < result.page.totalPages;
      } catch (e) {
        if (currentRequestId == _searchRequestId) {
          _errorMessage = e.toString();
        }
      } finally {
        if (currentRequestId == _searchRequestId) {
          _isLoading = false;
          notifyListeners();
        }
      }
    });
  }

  /// Muat halaman produk berikutnya untuk pencarian yang sedang aktif
  Future<void> loadMore() async {
    if (_isLoading || _isLoadingMore || !_hasMore || _lastQuery.isEmpty) return;
    _isLoadingMore = true;
    notifyListeners();

    final currentRequestId = _searchRequestId;
    try {
      final nextPage = _page + 1;
      final result = await _repository.search(_lastQuery, page: nextPage, limit: _limit);

      if (currentRequestId != _searchRequestId) return;

      {
        final prods = result.products;
        _products.addAll(prods);
        _page = nextPage;
        _totalProducts = result.page.total;
        _hasMore = _page < result.page.totalPages;
      }
    } catch (error) {
      if (currentRequestId == _searchRequestId) _errorMessage = error.toString();
    } finally {
      if (currentRequestId == _searchRequestId) {
        _isLoadingMore = false;
        notifyListeners();
      }
    }
  }

  void clear() {
    _debounceTimer?.cancel();
    _searchRequestId++;
    _lastQuery = '';
    _products = [];
    _creators = [];
    _isLoading = false;
    _isLoadingMore = false;
    _errorMessage = null;
    _totalProducts = 0;
    _hasMore = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _searchRequestId++;
    _debounceTimer?.cancel();
    super.dispose();
  }
}
