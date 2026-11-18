import 'package:flutter/foundation.dart';
import '../../../data/repositories/catalog_repositories.dart';
import '../../../data/models/product_model.dart';
import '../../../data/models/creator_model.dart';

/// Satu instance per layar; form tidak lagi berbagi state daftar ini.
class CreatorDashboardViewModel extends ChangeNotifier {
  CreatorDashboardViewModel({required ProductRepository products, required ArtisanRepository artisans})
      : _products = products, _artisans = artisans;
  final ProductRepository _products;
  final ArtisanRepository _artisans;
  CreatorModel? _artisanProfile;
  List<ProductModel> _myProducts = [];
  bool _isLoading = false;
  bool _disposed = false;
  int _requestId = 0;
  String? _errorMessage;

  CreatorModel? get artisanProfile => _artisanProfile;
  List<ProductModel> get myProducts => List.unmodifiable(_myProducts);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> init() => fetchDashboardData();

  Future<void> fetchDashboardData() async {
    final request = ++_requestId;
    _isLoading = true;
    _errorMessage = null;
    _notify();
    try {
      // Kegagalan profil tidak menghalangi pemuatan produk.
      try {
        final profile = await _artisans.getMineProfile();
        if (_disposed || request != _requestId) return;
        _artisanProfile = profile;
      } catch (e) {
        if (_disposed || request != _requestId) return;
        _errorMessage = e.toString();
      }
      final products = await _products.getMine();
      if (_disposed || request != _requestId) return;
      _myProducts = products;
    } catch (e) {
      if (_disposed || request != _requestId) return;
      _errorMessage = e.toString();
    } finally {
      if (!_disposed && request == _requestId) {
        _isLoading = false;
        _notify();
      }
    }
  }

  Future<void> createProduct({required String name, required String categoryId,
    required int price, required String description, required String shortDescription,
    required List<String> images, List<Map<String, dynamic>>? imageVariants,
    required bool isLimited, int? stock, List<Map<String, dynamic>>? variantOptions,
    List<Map<String, dynamic>>? variantStocks, String? replacesProductId,
    Map<String, dynamic>? olshop}) async {
    await _products.create({
      'name': name, 'categoryId': categoryId, 'price': price,
      'description': description, 'shortDescription': shortDescription,
      'images': images, if (imageVariants != null) 'imageVariants': imageVariants,
      'isLimited': isLimited, if (stock != null) 'stock': stock,
      if (variantOptions != null) 'variantOptions': variantOptions,
      if (variantStocks != null) 'variantStocks': variantStocks,
      if (replacesProductId != null) 'replacesProductId': replacesProductId,
      if (olshop != null) 'olshop': olshop,
    });
    await fetchDashboardData();
  }

  Future<void> updateProduct({required String id, required String name,
    String? categoryId, required String description, required String shortDescription,
    required int price, List<String>? images, dynamic imageVariants,
    required bool isLimited, Map<String, dynamic>? olshop,
    List<Map<String, dynamic>>? variantStocks}) async {
    await _products.update(id, {
      'name': name, if (categoryId != null) 'categoryId': categoryId,
      'description': description, 'shortDescription': shortDescription,
      'price': price, if (images != null) 'images': images,
      if (imageVariants != null) 'imageVariants': imageVariants,
      'isLimited': isLimited, if (olshop != null) 'olshop': olshop,
      if (variantStocks != null) 'variantStocks': variantStocks,
    });
    await fetchDashboardData();
  }

  void _notify() { if (!_disposed) notifyListeners(); }

  @override
  void dispose() {
    _disposed = true;
    _requestId++;
    super.dispose();
  }
}
