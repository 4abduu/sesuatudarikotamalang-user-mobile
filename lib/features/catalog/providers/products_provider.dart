import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../data/dummy/dummy_products.dart';
import '../../../data/dummy/dummy_categories.dart';
import '../../../data/models/product_model.dart';
import '../../../data/models/category_model.dart';

class ProductsProvider extends ChangeNotifier {
  List<ProductModel> _products = [];
  List<CategoryModel> _categories = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<ProductModel> get products => _products;
  List<CategoryModel> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Inisialisasi awal produk dan kategori
  Future<void> init() async {
    await fetchCategories();
    await fetchProducts();
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
    } catch (_) {
      // Fallback ke dummyCategories jika offline/backend belum ada data
      if (_categories.isEmpty) {
        _categories = dummyCategories;
        notifyListeners();
      }
    }
  }

  /// Ambil daftar produk (GET /api/products)
  Future<void> fetchProducts({
    String? categoryId,
    String? search,
    String? sort, // termurah, termahal, terlaris, terpopuler
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
      }
    } catch (e) {
      // Fallback ke dummyProducts bila backend offline atau gagal
      if (_products.isEmpty) {
        _products = dummyProducts;
      }
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Ambil detail produk lengkap dengan varian dan ulasan (GET /api/products/:id)
  Future<ProductModel?> getProductById(String id) async {
    try {
      final res = await ApiClient.get('/products/$id');
      if (res != null && res['product'] != null) {
        final prod = ProductModel.fromJson(res['product'] as Map<String, dynamic>);
        // Update di cache list lokal jika ada
        final idx = _products.indexWhere((p) => p.id == id);
        if (idx != -1) {
          _products[idx] = prod;
          notifyListeners();
        }
        return prod;
      }
    } catch (_) {
      // Fallback cari di lokal / dummy
    }
    try {
      return _products.firstWhere((p) => p.id == id);
    } catch (_) {
      return dummyProducts.firstWhere((p) => p.id == id, orElse: () => dummyProducts.first);
    }
  }
}
