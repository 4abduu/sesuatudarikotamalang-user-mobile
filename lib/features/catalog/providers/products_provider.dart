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

  List<ProductModel> get products => _products;
  List<ProductModel> get allProducts => _allProducts.isNotEmpty ? _allProducts : _products;
  List<CategoryModel> get categories => _categories;
  String get whatsappAdminNumber => _whatsappAdminNumber;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

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
      return null;
    }
  }
}
