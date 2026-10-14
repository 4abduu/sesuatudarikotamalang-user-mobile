import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/badge_chip.dart';
import '../../../core/widgets/rating_stars.dart';
import '../../../data/models/product_model.dart';
import '../../../shared/app_scaffold.dart';
import '../../catalog/providers/products_provider.dart';
import '../../creators/providers/artisans_provider.dart';
import '../providers/variant_selection_provider.dart';
import '../widgets/product_gallery.dart';
import '../widgets/variant_picker.dart';
import '../widgets/product_action_buttons.dart';
import '../widgets/behind_the_design_section.dart';
import '../widgets/product_reviews_section.dart';
import '../widgets/related_products_section.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;
  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  ProductModel? _product;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProduct();
  }

  Future<void> _loadProduct() async {
    final provider = context.read<ProductsProvider>();
    final p = await provider.getProductById(widget.productId);
    if (mounted) {
      setState(() {
        _product = p;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return AppScaffold(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final product = _product;
    if (product == null) {
      return AppScaffold(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        body: const Center(child: Text('Produk tidak ditemukan')),
      );
    }

    final artisans = context.watch<ArtisansProvider>().artisans;
    final creatorMatches = artisans.where((c) => c.id == product.creatorId).toList();
    final creator = creatorMatches.isNotEmpty ? creatorMatches.first : null;

    return ChangeNotifierProvider(
      key: ValueKey(product.id),
      create: (_) => VariantSelectionProvider(product),
      child: AppScaffold(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ProductGallery(seed: product.id),
              const SizedBox(height: 16),
              if (product.badge != BadgeType.none) BadgeChip(badge: product.badge),
              const SizedBox(height: 8),
              Text(product.name, style: AppTextStyles.h1),
              const SizedBox(height: 4),
              Text(product.shortDesc, style: AppTextStyles.bodyMuted),
              const SizedBox(height: 8),
              Text(
                formatRupiah(product.price),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                  fontFamily: 'Baloo 2',
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  RatingStars(value: product.rating, size: 14, showValue: true),
                  const SizedBox(width: 8),
                  Text('${product.soldCount} terjual', style: AppTextStyles.caption),
                ],
              ),
              const SizedBox(height: 16),
              _VariantCard(product: product),
              const SizedBox(height: 16),
              ProductActionButtons(
                productId: product.id,
                productName: product.name,
                creatorId: product.creatorId,
              ),
              const SizedBox(height: 24),
              BehindTheDesignSection(product: product),
              const SizedBox(height: 24),
              Text('Tentang Karya Ini', style: AppTextStyles.h2),
              const SizedBox(height: 8),
              Text(product.description, style: AppTextStyles.body),
              const SizedBox(height: 24),
              ProductReviewsSection(product: product),
              const SizedBox(height: 24),
              RelatedProductsSection(product: product),
              if (creator != null) ...[
                GestureDetector(
                  onTap: () => context.push('/kreator/${creator.id}'),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: AppColors.primary,
                            child: Text(
                              creator.name.isNotEmpty ? creator.name.substring(0, 1) : 'K',
                              style: const TextStyle(color: AppColors.onPrimary),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(creator.name, style: AppTextStyles.title),
                                Text(creator.specialty, style: AppTextStyles.caption),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _VariantCard extends StatelessWidget {
  final ProductModel product;
  const _VariantCard({required this.product});

  @override
  Widget build(BuildContext context) {
    if (!product.hasVariants) return const SizedBox.shrink();
    final provider = context.watch<VariantSelectionProvider>();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: VariantPicker(product: product, provider: provider),
      ),
    );
  }
}
