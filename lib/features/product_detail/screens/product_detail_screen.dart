import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
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
        title: 'Detail Produk',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        body: SingleChildScrollView(
          // px-4 pt-4 pb-6
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ProductGallery(seed: product.id),
              const SizedBox(height: 16),
              if (product.badge != BadgeType.none) ...[
                BadgeChip(badge: product.badge, large: true),
                const SizedBox(height: 8),
              ],
              Text(product.name, style: AppTextStyles.h1.copyWith(height: 1.25)),
              const SizedBox(height: 4),
              Text(product.shortDesc, style: AppTextStyles.bodyMuted),
              const SizedBox(height: 8),
              Text(
                formatRupiah(product.price),
                style: GoogleFonts.baloo2(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  RatingStars(value: product.rating, size: 14, showValue: true),
                  const SizedBox(width: 8),
                  Text('${product.soldCount} terjual', style: AppTextStyles.caption),
                  const SizedBox(width: 8),
                  Text('•', style: AppTextStyles.caption),
                  const SizedBox(width: 8),
                  Text(
                    product.totalStock <= 0
                        ? 'Stok habis'
                        : product.totalStock > 10
                            ? 'Stok 10+'
                            : 'Sisa ${product.totalStock}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: product.totalStock <= 10 ? AppColors.mustard : AppColors.muted,
                    ),
                  ),
                  if (product.isOfficial) ...[
                    const SizedBox(width: 8),
                    Text('•', style: AppTextStyles.caption),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.check_circle, size: 12, color: AppColors.primary),
                        const SizedBox(width: 3),
                        Text('Official Store', style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.primary)),
                      ]),
                    ),
                  ],
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
              Text(product.description, style: AppTextStyles.body.copyWith(height: 1.375)),
              const SizedBox(height: 24),
              ProductReviewsSection(product: product),
              const SizedBox(height: 24),
              RelatedProductsSection(product: product),
              if (creator != null) ...[
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () => context.push('/kreator/${creator.id}'),
                  // Kartu "Dibuat oleh": radius 20, surface, border 1px, soft shadow, p-3.
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border),
                      boxShadow: AppShadows.soft,
                    ),
                    child: Row(
                       children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(creator.isOfficial ? Icons.verified : Icons.person_outline, size: 20, color: AppColors.onPrimary),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(creator.isOfficial ? 'Toko Resmi' : 'Dibuat oleh', style: AppTextStyles.caption),
                              Row(
                                children: [
                                  Flexible(child: Text(creator.name, style: AppTextStyles.h3.copyWith(height: 1.25), overflow: TextOverflow.ellipsis)),
                                  if (creator.isOfficial) ...[
                                    const SizedBox(width: 4),
                                    const Icon(Icons.check_circle, size: 14, color: AppColors.primary),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, size: 16, color: AppColors.muted),
                      ],
                    ),
                  ),
                ),
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
    // Kartu varian: radius 20, surface, border 1px, soft shadow, p-4.
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.soft,
      ),
      child: VariantPicker(product: product, provider: provider),
    );
  }
}
