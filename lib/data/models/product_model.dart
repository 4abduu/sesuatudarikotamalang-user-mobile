import 'variant_option_model.dart';
import 'variant_model.dart';
import 'product_story_model.dart';

enum BadgeType { limited, story, bestseller, none }

class ProductModel {
  final String id;
  final String name;
  final String categoryId;
  final int price;
  final String creatorId;
  final String shortDesc;
  final String description;
  final List<VariantOptionModel> variantOptions;
  final List<VariantModel> variants;
  final BadgeType badge;
  final ProductStoryModel? story;
  final double rating;
  final int reviewCount;
  final int soldCount;
  final String createdAt;
  final String shopeeUrl;

  const ProductModel({
    required this.id, required this.name, required this.categoryId, required this.price,
    required this.creatorId, required this.shortDesc, required this.description,
    required this.variantOptions, required this.variants, required this.badge,
    this.story, required this.rating, required this.reviewCount, required this.soldCount,
    required this.createdAt, required this.shopeeUrl,
  });

  int get totalStock => variants.fold(0, (s, v) => s + v.stock);
  bool get hasVariants => variantOptions.isNotEmpty;
  bool get hasStory => story != null;
}
