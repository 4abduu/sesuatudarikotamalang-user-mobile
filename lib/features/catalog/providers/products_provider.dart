import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../data/models/product_model.dart';
import '../../../data/models/category_model.dart';

class ProductsProvider extends ChangeNotifier {
  List<ProductModel> _products = [];
  List<ProductModel> _allProducts = [];
  List<CategoryModel> _categories = [];
  String _whatsappAdminNumber = '6281234567890';
  bool _isLoading = false;
  String? _errorMessage;

  // State khusus Server-side Catalog dengan Paginasi
  List<ProductModel> _catalogProducts = [];
  bool _isCatalogLoading = false;
  bool _isCatalogLoadingMore = false;
  int _catalogPage = 1;
  static const int _catalogLimit = 12;
  int _catalogTotal = 0;
  bool _catalogHasMore = false;
  int _catalogRequestId = 0;
  String? _activeCategory;
  String? _activeSearch;
  String? _activeSort;

  List<ProductModel> get products => _products;
  List<ProductModel> get allProducts => _allProducts.isNotEmpty ? _allProducts : _products;
  List<CategoryModel> get categories => _categories;
  String get whatsappAdminNumber => _whatsappAdminNumber;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<ProductModel> get catalogProducts => _catalogProducts;
  bool get isCatalogLoading => _isCatalogLoading;
  bool get isCatalogLoadingMore => _isCatalogLoadingMore;
  int get catalogTotal => _catalogTotal;
  bool get catalogHasMore => _catalogHasMore;

  /// Inisialisasi awal produk dan kategori
  Future<void> init() async {
    await fetchCategories();
    await fetchProducts();
    await fetchSettings();
  }

  /// Ambil pengaturan publik seperti nomor WA admin (GET /api/settings/public)
  Future<void> fetchSettings() async {
    try {
      final res = await ApiClient.get('/settings/public');
      if (res != null && res['settings'] != null) {
        final wa = res['settings']['whatsappAdminNumber'] as String?;
        if (wa != null && wa.isNotEmpty) {
          _whatsappAdminNumber = wa.replaceAll(RegExp(r'[^0-9]'), '');
          notifyListeners();
        }
      }
    } catch (_) {}
  }

  /// Ambil daftar kategori (GET /api/categories)
  Future<void> fetchCategories() async {
    try {
      final res = await ApiClient.get('/categories');
      if (res != null && res['categories'] != null) {
        final list = (res['categories'] as List<dynamic>)
            .map((e) => CategoryModel.fromJson(e as Map<String, dynamic>))
            .toList();
        _categories = list;
        notifyListeners();
        return;
      }
    } catch (_) {}
  }

  /// Ambil daftar produk umum (beranda/cache lokal) (GET /api/products)
  Future<void> fetchProducts({
    String? categoryId,
    String? search,
    String? sort,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final queryParams = <String, dynamic>{};
      if (categoryId != null && categoryId.isNotEmpty) {
        queryParams['categoryId'] = categoryId;
      }
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      if (sort != null && sort.isNotEmpty) {
        queryParams['sort'] = sort;
      }

      final res = await ApiClient.get('/products', queryParameters: queryParams);
      if (res != null && res['products'] != null) {
        final list = (res['products'] as List<dynamic>)
            .map((e) => ProductModel.fromJson(e as Map<String, dynamic>))
            .toList();
        _products = list;
        if (categoryId == null || categoryId.isEmpty) {
          _allProducts = list;
        }
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch Katalog Produk dari Server (GET /api/products dengan pagination)
  Future<void> fetchCatalog({
    String? categoryId,
    String? search,
    String? sort,
    bool reset = true,
  }) async {
    _activeCategory = categoryId;
    _activeSearch = search;
    _activeSort = sort;

    if (reset) {
      _catalogPage = 1;
      _isCatalogLoading = true;
      notifyListeners();
    }

    final currentReqId = ++_catalogRequestId;

    try {
      final qp = <String, dynamic>{
        'page': _catalogPage,
        'limit': _catalogLimit,
      };
      if (categoryId != null && categoryId.isNotEmpty) {
        qp['categoryId'] = categoryId;
      }
      if (search != null && search.trim().isNotEmpty) {
        qp['search'] = search.trim();
      }
      if (sort != null && sort.isNotEmpty) {
        qp['sort'] = sort;
      }

      final res = await ApiClient.get('/products', queryParameters: qp);
      if (currentReqId != _catalogRequestId) return;

      if (res != null && res['products'] != null) {
        final list = (res['products'] as List<dynamic>)
            .map((e) => ProductModel.fromJson(e as Map<String, dynamic>))
            .toList();
        _catalogProducts = list;

        final pagination = res['pagination'] as Map<String, dynamic>?;
        if (pagination != null) {
          _catalogTotal = (pagination['total'] as num?)?.toInt() ?? list.length;
          final totalPages = (pagination['totalPages'] as num?)?.toInt() ?? 1;
          _catalogHasMore = _catalogPage < totalPages;
        } else {
          _catalogTotal = list.length;
          _catalogHasMore = false;
        }
      }
    } catch (_) {
    } finally {
      if (currentReqId == _catalogRequestId) {
        _isCatalogLoading = false;
        notifyListeners();
      }
    }
  }

  /// Load more catalog produk halaman berikutnya
  Future<void> loadMoreCatalog() async {
    if (_isCatalogLoadingMore || !_catalogHasMore) return;
    _isCatalogLoadingMore = true;
    notifyListeners();

    final currentReqId = _catalogRequestId;
    final nextPage = _catalogPage + 1;

    try {
      final qp = <String, dynamic>{
        'page': nextPage,
        'limit': _catalogLimit,
      };
      if (_activeCategory != null && _activeCategory!.isNotEmpty) {
        qp['categoryId'] = _activeCategory;
      }
      if (_activeSearch != null && _activeSearch!.trim().isNotEmpty) {
        qp['search'] = _activeSearch!.trim();
      }
      if (_activeSort != null && _activeSort!.isNotEmpty) {
        qp['sort'] = _activeSort;
      }

      final res = await ApiClient.get('/products', queryParameters: qp);
      if (currentReqId != _catalogRequestId) return;

      if (res != null && res['products'] != null) {
        final list = (res['products'] as List<dynamic>)
            .map((e) => ProductModel.fromJson(e as Map<String, dynamic>))
            .toList();
        _catalogProducts.addAll(list);
        _catalogPage = nextPage;

        final pagination = res['pagination'] as Map<String, dynamic>?;
        if (pagination != null) {
          _catalogTotal = (pagination['total'] as num?)?.toInt() ?? _catalogTotal;
          final totalPages = (pagination['totalPages'] as num?)?.toInt() ?? 1;
          _catalogHasMore = _catalogPage < totalPages;
        } else {
          _catalogHasMore = false;
        }
      }
    } catch (_) {
    } finally {
      if (currentReqId == _catalogRequestId) {
        _isCatalogLoadingMore = false;
        notifyListeners();
      }
    }
  }

  /// Ambil detail produk lengkap dengan varian dan ulasan (GET /api/products/:id)
  Future<ProductModel?> getProductById(String id) async {
    try {
      final res = await ApiClient.get('/products/$id');
      if (res != null && res['product'] != null) {
        final prod = ProductModel.fromJson(res['product'] as Map<String, dynamic>);
        final idx = _products.indexWhere((p) => p.id == id);
        if (idx != -1) {
          _products[idx] = prod;
          notifyListeners();
        }
        return prod;
      }
    } catch (_) {}
    try {
      return _products.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }
}
