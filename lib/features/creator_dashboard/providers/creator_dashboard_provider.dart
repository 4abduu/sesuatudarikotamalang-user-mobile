import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../data/models/product_model.dart';
import '../../../data/models/creator_model.dart';

class CreatorDashboardProvider extends ChangeNotifier {
  CreatorModel? _artisanProfile;
  List<ProductModel> _myProducts = [];
  bool _isLoading = false;
  String? _errorMessage;

  CreatorModel? get artisanProfile => _artisanProfile;
  List<ProductModel> get myProducts => List.unmodifiable(_myProducts);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> init() async {
    await fetchDashboardData();
  }

  /// Ambil data profil kreator sendiri dan produk miliknya
  Future<void> fetchDashboardData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Ambil profil kreator (GET /api/artisans/mine)
      try {
        final artisanRes = await ApiClient.get('/artisans/mine');
        if (artisanRes != null && artisanRes['artisan'] != null) {
          _artisanProfile = CreatorModel.fromJson(artisanRes['artisan'] as Map<String, dynamic>);
        }
      } catch (_) {}

      // 2. Ambil list produk milik kreator (GET /api/products/mine)
      final prodRes = await ApiClient.get('/products/mine');
      if (prodRes != null && prodRes['products'] != null) {
        final list = (prodRes['products'] as List<dynamic>)
            .map((e) => ProductModel.fromJson(e as Map<String, dynamic>))
            .toList();
        _myProducts = list;
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Tambah produk baru (POST /api/products)
  Future<ProductModel> createProduct({
    required String name,
    required String categoryId,
    required int price,
    required String description,
    String? shortDescription,
    List<String> images = const [],
    bool isLimited = false,
    String? shopeeUrl,
    int? stock,
    List<Map<String, dynamic>>? variantOptions,
    List<Map<String, dynamic>>? variantStocks,
  }) async {
    final body = <String, dynamic>{
      'name': name,
      'categoryId': categoryId,
      'price': price,
      'description': description,
      if (shortDescription != null) 'shortDescription': shortDescription,
      'images': images,
      'isLimited': isLimited,
      if (shopeeUrl != null) 'shopeeUrl': shopeeUrl,
      if (stock != null) 'stock': stock,
      if (variantOptions != null && variantOptions.isNotEmpty) 'variantOptions': variantOptions,
      if (variantStocks != null && variantStocks.isNotEmpty) 'variantStocks': variantStocks,
    };

    final res = await ApiClient.post('/products', body: body);
    if (res != null && res['product'] != null) {
      final newProd = ProductModel.fromJson(res['product'] as Map<String, dynamic>);
      _myProducts.insert(0, newProd);
      notifyListeners();
      return newProd;
    }
    throw ApiException(500, 'Gagal menambahkan produk');
  }

  /// Update produk (PUT /api/products/:id)
  Future<ProductModel> updateProduct({
    required String id,
    String? name,
    String? categoryId,
    String? shortDescription,
    String? description,
    int? price,
    List<String>? images,
    bool? isLimited,
    String? shopeeUrl,
    List<Map<String, dynamic>>? variantStocks,
  }) async {
    final body = <String, dynamic>{
      if (name != null) 'name': name,
      if (categoryId != null) 'categoryId': categoryId,
      if (shortDescription != null) 'shortDescription': shortDescription,
      if (description != null) 'description': description,
      if (price != null) 'price': price,
      if (images != null) 'images': images,
      if (isLimited != null) 'isLimited': isLimited,
      if (shopeeUrl != null) 'shopeeUrl': shopeeUrl,
      if (variantStocks != null) 'variantStocks': variantStocks,
    };

    final res = await ApiClient.put('/products/$id', body: body);
    if (res != null && res['product'] != null) {
      final updated = ProductModel.fromJson(res['product'] as Map<String, dynamic>);
      final idx = _myProducts.indexWhere((p) => p.id == id);
      if (idx != -1) {
        _myProducts[idx] = updated;
      }
      notifyListeners();
      return updated;
    }
    throw ApiException(500, 'Gagal memperbarui produk');
  }

  /// Simpan atau update cerita karya (POST /api/products/:id/story)
  Future<void> saveStory({
    required String productId,
    required String title,
    required String content,
    String? process,
    String? coverImageUrl,
    List<String> processImages = const [],
  }) async {
    final body = <String, dynamic>{
      'title': title,
      'content': content,
      if (process != null && process.trim().isNotEmpty) 'process': process.trim(),
      if (coverImageUrl != null) 'coverImageUrl': coverImageUrl,
      'processImages': processImages,
    };

    final res = await ApiClient.post('/products/$productId/story', body: body);
    if (res != null && res['story'] != null) {
      await fetchDashboardData();
      return;
    }
    throw ApiException(500, 'Gagal menyimpan cerita produk');
  }
}
