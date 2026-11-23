import '../../core/network/api_exception.dart';
import '../../core/network/api_service.dart';
import '../../core/viewmodel/paged_state.dart';
import '../models/category_model.dart';
import '../models/creator_model.dart';
import '../models/product_model.dart';
import '../models/review_model.dart';

class CategoryRepository {
  CategoryRepository(this._api);
  final ApiService _api;
  Future<List<CategoryModel>> getCategories() async {
    final res = await _api.get('/categories');
    return ((res?['categories'] as List?) ?? const [])
        .map((e) => CategoryModel.fromJson(e as Map<String, dynamic>)).toList();
  }
}

class SettingsRepository {
  SettingsRepository(this._api);
  final ApiService _api;
  Future<Map<String, dynamic>> getPublicSettings() async =>
      ((await _api.get('/settings/public'))?['settings'] as Map<String, dynamic>?) ?? {};
}

class ProductRepository {
  ProductRepository(this._api);
  final ApiService _api;

  Future<PageResult<ProductModel>> getProducts({String? categoryId, String? search, String? sort, int? page, int? limit}) async {
    final query = <String, dynamic>{
      if (categoryId != null && categoryId.isNotEmpty) 'categoryId': categoryId,
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      if (sort != null && sort.isNotEmpty) 'sort': sort,
      if (page != null) 'page': page,
      if (limit != null) 'limit': limit,
    };
    final res = await _api.get('/products', query: query);
    final items = ((res?['products'] as List?) ?? const [])
        .map((e) => ProductModel.fromJson(e as Map<String, dynamic>)).toList();
    final pagination = res?['pagination'] as Map<String, dynamic>?;
    return PageResult(
      items: items,
      total: (pagination?['total'] as num?)?.toInt() ?? items.length,
      totalPages: (pagination?['totalPages'] as num?)?.toInt() ?? 1,
    );
  }

  Future<ProductModel> getProduct(String id) async {
    final res = await _api.get('/products/$id');
    return ProductModel.fromJson(res['product'] as Map<String, dynamic>);
  }
  Future<List<ProductModel>> getMine() async {
    final res = await _api.get('/products/mine');
    return ((res?['products'] as List?) ?? const [])
        .map((e) => ProductModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<ProductModel> create(Map<String, dynamic> body) async {
    final res = await _api.post('/products', body: body);
    final product = res?['product'];
    if (product is! Map<String, dynamic>) {
      throw ApiException(500, 'Gagal menambahkan produk');
    }
    return ProductModel.fromJson(product);
  }

  Future<ProductModel> update(String id, Map<String, dynamic> body) async {
    final res = await _api.put('/products/$id', body: body);
    final product = res?['product'];
    if (product is! Map<String, dynamic>) {
      throw ApiException(500, 'Gagal memperbarui produk');
    }
    return ProductModel.fromJson(product);
  }
}

class ArtisanRepository {
  ArtisanRepository(this._api);
  final ApiService _api;

  Future<({String id, String name, String bio, String? avatarUrl, String? ownAvatarUrl})?> getMine() async {
    final res = await _api.get('/artisans/mine');
    final a = res is Map<String, dynamic> ? res['artisan'] : null;
    if (a is! Map<String, dynamic>) return null;
    return (
      id: (a['id'] ?? '').toString(),
      name: (a['brandName'] ?? '').toString(),
      bio: (a['bio'] ?? '').toString(),
      avatarUrl: a['avatarUrl'] as String?,
      ownAvatarUrl: a['ownAvatarUrl'] as String?,
    );
  }

  Future<CreatorModel?> getMineProfile() async {
    final result = await getMine();
    if (result == null) return null;
    return CreatorModel(id: 'mine', name: result.name, bio: result.bio, avatarUrl: result.avatarUrl);
  }

  Future<void> updateMine(Map<String, dynamic> changes) async {
    await _api.put('/artisans/mine', body: changes);
  }

  Future<({List<CreatorModel> artisans, CreatorModel? officialStore})> getArtisans() async {
    final res = await _api.get('/artisans');
    final artisans = ((res?['artisans'] as List?) ?? const [])
        .map((e) => CreatorModel.fromJson(e as Map<String, dynamic>))
        .where((e) => e.status == 'aktif').toList();
    final raw = res?['officialStore'];
    return (artisans: artisans, officialStore: raw is Map<String, dynamic> ? CreatorModel.fromJson(raw) : null);
  }

  Future<({CreatorModel artisan, List<ProductModel> products})> getArtisan(String id) async {
    final res = await _api.get('/artisans/$id');
    final raw = res['artisan'] as Map<String, dynamic>;
    final products = ((raw['products'] as List?) ?? (res['products'] as List?) ?? const [])
        .map((e) => ProductModel.fromJson(e as Map<String, dynamic>)).toList();
    return (artisan: CreatorModel.fromJson(raw), products: products);
  }
}

class SearchRepository {
  SearchRepository(this._api);
  final ApiService _api;
  Future<({List<ProductModel> products, List<CreatorModel> creators, PageResult<ProductModel> page})> search(String query, {required int page, required int limit}) async {
    final res = await _api.get('/search', query: {'q': query, 'page': page, 'limit': limit});
    final products = ((res?['products'] as List?) ?? const [])
        .map((e) => ProductModel.fromJson(e as Map<String, dynamic>)).toList();
    final creators = ((res?['creators'] as List?) ?? const [])
        .map((e) => CreatorModel.fromJson(e as Map<String, dynamic>)).where((e) => e.status == 'aktif').toList();
    final pagination = res?['pagination'] as Map<String, dynamic>?;
    return (
      products: products,
      creators: creators,
      page: PageResult(items: products, total: (pagination?['total'] as num?)?.toInt() ?? products.length, totalPages: (pagination?['totalPages'] as num?)?.toInt() ?? 1),
    );
  }
}

class ReviewRepository {
  ReviewRepository(this._api);
  final ApiService _api;

  Future<({double rating, int total, List<ReviewModel> reviews})> getStoreReviews() async {
    final res = await _api.get('/reviews');
    final all = ((res?['reviews'] as List?) ?? const [])
        .map((e) => ReviewModel.fromJson(e as Map<String, dynamic>)).toList();
    final curated = all.where((review) => review.productId == null || review.productId!.isEmpty).toList();
    return (
      rating: (res?['avgRating'] as num?)?.toDouble() ?? 0,
      total: (res?['totalReviews'] as num?)?.toInt() ?? all.length,
      reviews: curated.isNotEmpty ? curated : all,
    );
  }

  Future<PageResult<ReviewModel>> getMyReviews({int page = 1, int limit = 10}) async {
    final res = await _api.get('/reviews/mine', query: {'page': page, 'limit': limit});
    final reviews = ((res?['reviews'] as List?) ?? const [])
        .map((e) => ReviewModel.fromJson(e as Map<String, dynamic>)).toList();
    final pagination = res?['pagination'] as Map<String, dynamic>?;
    return PageResult(
      items: reviews,
      total: (pagination?['total'] as num?)?.toInt() ?? reviews.length,
      totalPages: (pagination?['totalPages'] as num?)?.toInt() ?? 1,
    );
  }

  Future<List<ReviewModel>> getProductReviews(String productId, {int page = 1, int limit = 3}) async {
    try {
      final res = await _api.get('/products/$productId/reviews', query: {'page': page, 'limit': limit});
      return ((res?['reviews'] as List?) ?? const [])
          .map((e) => ReviewModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return getLegacyProductReviews(productId, limit: limit);
    }
  }

  Future<List<ReviewModel>> getLegacyProductReviews(String productId, {int limit = 3}) async {
    final res = await _api.get('/reviews', query: {'productId': productId});
    return ((res?['reviews'] as List?) ?? const [])
        .map((e) => ReviewModel.fromJson(e as Map<String, dynamic>)).take(limit).toList();
  }

  Future<ProductReviewsResult> getProductReviewsPaginated(String productId, {int? rating, int page = 1, int limit = 10}) async {
    try {
      final res = await _api.get('/products/$productId/reviews', query: {
        'page': page,
        'limit': limit,
        if (rating != null && rating >= 1 && rating <= 5) 'rating': rating,
      });
      return ProductReviewsResult.fromJson(res);
    } catch (_) {
      final legacy = await getLegacyProductReviews(productId, limit: limit);
      return ProductReviewsResult(
        reviews: rating == null ? legacy : legacy.where((review) => review.rating == rating).toList(),
        page: 1,
        limit: limit,
        total: legacy.length,
        totalPages: 1,
        summary: ProductReviewsSummary(
          avgRating: legacy.isEmpty ? 0 : legacy.map((review) => review.rating).reduce((a, b) => a + b) / legacy.length,
          reviewCount: legacy.length,
          breakdown: {for (var star = 1; star <= 5; star++) star: legacy.where((review) => review.rating == star).length},
        ),
      );
    }
  }

  Future<ReviewModel> submit({String? orderItemId, required int rating, required String comment}) async {
    final res = await _api.post('/reviews', body: {
      if (orderItemId != null && orderItemId.isNotEmpty) 'orderItemId': orderItemId,
      'rating': rating,
      'comment': comment,
    });
    return ReviewModel.fromJson(res['review'] as Map<String, dynamic>);
  }
}
