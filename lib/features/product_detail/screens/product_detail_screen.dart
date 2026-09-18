import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/badge_chip.dart';
import '../../../core/widgets/rating_stars.dart';
import '../../../data/dummy/dummy_products.dart';
import '../../../data/dummy/dummy_creators.dart';
import '../../../data/models/product_model.dart';
import '../../../shared/app_scaffold.dart';
import '../providers/variant_selection_provider.dart';
import '../widgets/product_gallery.dart';
import '../widgets/variant_picker.dart';
import '../widgets/product_action_buttons.dart';
import '../widgets/behind_the_design_section.dart';
import '../widgets/product_reviews_section.dart';
import '../widgets/related_products_section.dart';

class ProductDetailScreen extends StatelessWidget {
  final String productId;
  const ProductDetailScreen({super.key, required this.productId});

  @override
  Widget build(BuildContext context) {
    final product = dummyProducts.firstWhere((p) => p.id == productId, orElse: () => dummyProducts.first);
    final creator = dummyCreators.firstWhere((c) => c.id == product.creatorId, orElse: () => dummyCreators.first);
    return ChangeNotifierProvider(
      create: (_) => VariantSelectionProvider(product),
      child: AppScaffold(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ProductGallery(seed: product.id),
          const SizedBox(height: 16),
          if (product.badge != BadgeType.none) BadgeChip(badge: product.badge),
          const SizedBox(height: 8),
          Text(product.name, style: AppTextStyles.h1),
          const SizedBox(height: 4),
          Text(product.shortDesc, style: AppTextStyles.bodyMuted),
          const SizedBox(height: 8),
          Text(formatRupiah(product.price), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.primary, fontFamily: 'Baloo 2')),
          const SizedBox(height: 8),
          Row(children: [RatingStars(value: product.rating, size: 14, showValue: true), const SizedBox(width: 8), Text('${product.soldCount} terjual', style: AppTextStyles.caption)]),
          const SizedBox(height: 16),
          _VariantCard(product: product),
          const SizedBox(height: 16),
          ProductActionButtons(productId: product.id, productName: product.name, creatorId: product.creatorId),
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
          const SizedBox(height: 16),
          GestureDetector(onTap: () => context.push('/kreator/${creator.id}'), child: Card(child: Padding(padding: const EdgeInsets.all(12), child: Row(children: [
            Container(width: 40, height: 40, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle), child: const Icon(Icons.person, color: AppColors.onPrimary)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Dibuat oleh', style: AppTextStyles.caption), Text(creator.name, style: AppTextStyles.h3)])),
            const Icon(Icons.chevron_right, color: AppColors.muted),
          ])))),
        ])),
      ),
    );
  }
}

class _VariantCard extends StatelessWidget {
  final ProductModel product;
  const _VariantCard({required this.product});
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<VariantSelectionProvider>();
    final stock = provider.matchedVariant?.stock;
    return Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(product.hasVariants ? 'Pilih Varian' : 'Ketersediaan', style: AppTextStyles.h3),
        if (stock != null) Text(stock < 6 ? 'Stok terbatas · $stock tersedia' : 'Stok: $stock tersedia', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: stock < 6 ? AppColors.mustard : AppColors.muted))
        else Text('Total stok: ${product.totalStock}', style: AppTextStyles.caption),
      ]),
      const SizedBox(height: 12),
      VariantPicker(product: product, provider: provider),
      if (product.hasVariants && provider.matchedVariant != null) ...[const SizedBox(height: 8), Text('Varian terpilih: ${provider.variantLabel}', style: AppTextStyles.caption)],
    ])));
  }
}
