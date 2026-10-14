import 'variant_option_model.dart';
import 'variant_model.dart';
import 'product_story_model.dart';

enum BadgeType { limited, story, bestseller, none }

class ProductModel {
  final String id;
  final String name;
  final String categoryId;
  final int price;
  final String creatorId; // artisanId
  final String shortDesc;
  final String description;
  final List<String> images;
  final List<VariantOptionModel> variantOptions;
  final List<VariantModel> variants;
  final BadgeType badge;
  final ProductStoryModel? story;
  final double rating;
  final int reviewCount;
  final int soldCount;
  final String createdAt;
  final String shopeeUrl;
  final bool isLimited;
  final bool isActive;

  const ProductModel({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.price,
    required this.creatorId,
    required this.shortDesc,
    required this.description,
    this.images = const [],
    required this.variantOptions,
    required this.variants,
    required this.badge,
    this.story,
    required this.rating,
    required this.reviewCount,
    required this.soldCount,
    required this.createdAt,
    required this.shopeeUrl,
    this.isLimited = false,
    this.isActive = true,
  });

  /// Menggunakan effectiveStock dari backend (stok mentah dikurangi order aktif)
  int get totalStock => variants.fold(0, (s, v) => s + (v.effectiveStock > 0 ? v.effectiveStock : v.stock));
  bool get hasVariants => variantOptions.isNotEmpty;
  bool get hasStory => story != null;

  factory ProductModel.fromJson(Map<String, dynamic> j) {
    // Parse options
    final vOptions = (j['variantOptions'] as List<dynamic>?)
            ?.map((e) => VariantOptionModel.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    // Parse variants
    final vVariants = (j['variants'] as List<dynamic>?)
            ?.map((e) => VariantModel.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    // Parse story
    ProductStoryModel? pStory;
    if (j['story'] != null && j['story'] is Map<String, dynamic>) {
      pStory = ProductStoryModel.fromJson(j['story'] as Map<String, dynamic>);
    }

    // Parse badge
    final isLimited = j['isLimited'] == true;
    final sold = (j['soldCount'] as num?)?.toInt() ?? 0;
    BadgeType b = BadgeType.none;
    if (isLimited) {
      b = BadgeType.limited;
    } else if (pStory != null) {
      b = BadgeType.story;
    } else if (sold >= 10) {
      b = BadgeType.bestseller;
    }

    final imgs = (j['images'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];

    return ProductModel(
      id: j['id'] ?? '',
      name: j['name'] ?? '',
      categoryId: j['categoryId'] ?? (j['category']?['id'] ?? ''),
      price: (j['price'] as num?)?.toInt() ?? 0,
      creatorId: j['artisanId'] ?? (j['artisan']?['id'] ?? (j['creatorId'] ?? '')),
      shortDesc: j['shortDescription'] ?? (j['shortDesc'] ?? ''),
      description: j['description'] ?? '',
      images: imgs,
      variantOptions: vOptions,
      variants: vVariants,
      badge: b,
      story: pStory,
      rating: (j['rating'] as num?)?.toDouble() ?? ((j['avgRating'] as num?)?.toDouble() ?? 5.0),
      reviewCount: (j['reviewCount'] as num?)?.toInt() ?? 0,
      soldCount: sold,
      createdAt: j['createdAt'] ?? '',
      shopeeUrl: j['shopeeUrl'] ?? '',
      isLimited: isLimited,
      isActive: j['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'categoryId': categoryId,
    'price': price,
    'artisanId': creatorId,
    'shortDescription': shortDesc,
    'description': description,
    'images': images,
    'variantOptions': variantOptions.map((e) => e.toJson()).toList(),
    'variants': variants.map((e) => e.toJson()).toList(),
    if (story != null) 'story': story!.toJson(),
    'rating': rating,
    'reviewCount': reviewCount,
    'soldCount': soldCount,
    'createdAt': createdAt,
    'shopeeUrl': shopeeUrl,
    'isLimited': isLimited,
    'isActive': isActive,
  };
}
