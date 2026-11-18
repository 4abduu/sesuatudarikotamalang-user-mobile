import 'package:flutter/foundation.dart';
import '../../../data/models/creator_model.dart';
import '../../../data/models/product_model.dart';
import '../../../data/repositories/catalog_repositories.dart';

class ProductDetailViewModel extends ChangeNotifier {
  ProductDetailViewModel({required ProductRepository products, required ArtisanRepository artisans})
      : _productsRepository = products,
        _artisansRepository = artisans;

  final ProductRepository _productsRepository;
  final ArtisanRepository _artisansRepository;
  ProductModel? _product;
  CreatorModel? _creator;
  List<ProductModel> _relatedProducts = [];
  bool _isLoading = false;
  String? _errorMessage;

  ProductModel? get product => _product;
  CreatorModel? get creator => _creator;
  List<ProductModel> get relatedProducts => _relatedProducts;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> load(String productId, {bool includeRelated = true}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _product = await _productsRepository.getProduct(productId);
      final product = _product!;
      if (!includeRelated) return;
      final results = await Future.wait<Object>([
        _artisansRepository.getArtisans(),
        _productsRepository.getProducts(categoryId: product.categoryId),
      ]);
      final artisans = results[0] as ({List<CreatorModel> artisans, CreatorModel? officialStore});
      final related = results[1] as dynamic;
      _creator = artisans.artisans.where((item) => item.id == product.creatorId).firstOrNull;
      _relatedProducts = (related.items as List<ProductModel>)
          .where((item) => item.id != product.id)
          .take(4)
          .toList();
    } catch (error) {
      _errorMessage = error.toString();
      _product = null;
      _creator = null;
      _relatedProducts = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
