import 'package:flutter/foundation.dart';
import '../../../data/models/creator_model.dart';
import '../../../data/models/product_model.dart';
import '../../../data/models/review_model.dart';
import '../../../data/repositories/catalog_repositories.dart';

class HomeViewModel extends ChangeNotifier {
  HomeViewModel({required ProductRepository products, required ArtisanRepository artisans, required ReviewRepository reviews})
      : _productsRepository = products,
        _artisansRepository = artisans,
        _reviewsRepository = reviews;

  final ProductRepository _productsRepository;
  final ArtisanRepository _artisansRepository;
  final ReviewRepository _reviewsRepository;

  List<ProductModel> _products = [];
  List<CreatorModel> _creators = [];
  CreatorModel? _officialStore;
  bool _isLoading = false;
  bool _disposed = false;
  String? _errorMessage;
  double _storeRating = 0;
  int _storeReviewTotal = 0;
  List<ReviewModel> _storeReviews = [];

  List<ProductModel> get products => _products;
  List<CreatorModel> get creators => _creators;
  CreatorModel? get officialStore => _officialStore;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  double get storeRating => _storeRating;
  int get storeReviewTotal => _storeReviewTotal;
  List<ReviewModel> get storeReviews => _storeReviews;

  List<ProductModel> get recommendedProducts {
    final result = [..._products];
    final maxSold = result.fold<int>(
      0,
      (max, product) => product.soldCount > max ? product.soldCount : max,
    );
    result.sort((a, b) {
      final score = _productScore(b, maxSold).compareTo(_productScore(a, maxSold));
      if (score != 0) return score;
      final rating = b.rating.compareTo(a.rating);
      return rating != 0 ? rating : b.soldCount.compareTo(a.soldCount);
    });
    return result.take(4).toList();
  }

  List<CreatorModel> get featuredCreators {
    final result = [..._creators];
    final maxSold = result.fold<int>(0, (max, creator) => creator.soldCount > max ? creator.soldCount : max);
    result.sort((a, b) {
      final scoreA = _creatorScore(a, maxSold);
      final scoreB = _creatorScore(b, maxSold);
      final score = scoreB.compareTo(scoreA);
      if (score != 0) return score;
      return b.rating.compareTo(a.rating);
    });
    return result.take(3).toList();
  }

  double _creatorScore(CreatorModel creator, int maxSold) {
    final salesScore = maxSold == 0 ? 0.0 : creator.soldCount / maxSold;
    final ratingScore = creator.rating.clamp(0.0, 5.0).toDouble() / 5;
    return salesScore * 0.6 + ratingScore * 0.4;
  }

  double _productScore(ProductModel product, int maxSold) {
    final salesScore = maxSold == 0 ? 0.0 : product.soldCount / maxSold;
    final ratingScore = product.rating.clamp(0.0, 5.0).toDouble() / 5;
    return salesScore * 0.6 + ratingScore * 0.4;
  }

  Future<void> init() async {
    if (_isLoading || _disposed) return;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await Future.wait<void>([
        _productsRepository.getProducts().then((result) {
          _products = result.items;
        }),
        _artisansRepository.getArtisans().then((result) {
          _creators = result.artisans;
          _officialStore = result.officialStore;
        }),
        _reviewsRepository.getStoreReviews().then((result) {
          _storeRating = result.rating;
          _storeReviewTotal = result.total;
          _storeReviews = result.reviews;
        }),
      ]);
    } catch (error) {
      _errorMessage = error.toString();
      // Jangan mempertahankan hasil lama ketika pemuatan ulang gagal.
      // Data stale dapat terlihat seolah-olah masih berasal dari server aktif.
      _products = [];
      _creators = [];
      _officialStore = null;
      _storeRating = 0;
      _storeReviewTotal = 0;
      _storeReviews = [];
    } finally {
      _isLoading = false;
      if (!_disposed) notifyListeners();
    }
  }

  Future<void> refresh() => init();

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
