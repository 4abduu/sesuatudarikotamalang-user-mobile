import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../data/models/creator_model.dart';
import '../../../data/models/product_model.dart';

class SearchProvider extends ChangeNotifier {
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
    _isLoading = true;
    _errorMessage = null;
    _page = 1;
    notifyListeners();

    // Debounce 400 ms
    _debounceTimer = Timer(const Duration(milliseconds: 400), () async {
      final currentRequestId = ++_searchRequestId;

      try {
        final res = await ApiClient.get('/search', queryParameters: {
          'q': q,
          'page': _page,
          'limit': _limit,
        });
        // Abaikan hasil jika ada request pencarian baru yang masuk setelah ini
        if (currentRequestId != _searchRequestId) return;

        if (res != null) {
          final prods = (res['products'] as List<dynamic>?)
                  ?.map((e) => ProductModel.fromJson(e as Map<String, dynamic>))
                  .toList() ??
              [];
          final crts = (res['creators'] as List<dynamic>?)
                  ?.map((e) => CreatorModel.fromJson(e as Map<String, dynamic>))
                  .where((c) => c.status == 'aktif')
                  .toList() ??
              [];

          _products = prods;
          _creators = crts;

          final pagination = res['pagination'] as Map<String, dynamic>?;
          if (pagination != null) {
            _totalProducts = (pagination['total'] as num?)?.toInt() ?? prods.length;
            final totalPages = (pagination['totalPages'] as num?)?.toInt() ?? 1;
            _hasMore = _page < totalPages;
          } else {
            _totalProducts = prods.length;
            _hasMore = false;
          }
        }
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
    if (_isLoadingMore || !_hasMore || _lastQuery.isEmpty) return;
    _isLoadingMore = true;
    notifyListeners();

    try {
      final nextPage = _page + 1;
      final currentRequestId = _searchRequestId;
      final res = await ApiClient.get('/search', queryParameters: {
        'q': _lastQuery,
        'page': nextPage,
        'limit': _limit,
      });

      if (currentRequestId != _searchRequestId) return;

      if (res != null && res['products'] != null) {
        final prods = (res['products'] as List<dynamic>)
            .map((e) => ProductModel.fromJson(e as Map<String, dynamic>))
            .toList();
        _products.addAll(prods);
        _page = nextPage;

        final pagination = res['pagination'] as Map<String, dynamic>?;
        if (pagination != null) {
          _totalProducts = (pagination['total'] as num?)?.toInt() ?? _totalProducts;
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
    _debounceTimer?.cancel();
    super.dispose();
  }
}
