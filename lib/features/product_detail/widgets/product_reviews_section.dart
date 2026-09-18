import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/rating_stars.dart';
import '../../../data/dummy/dummy_reviews.dart';
import '../../../data/models/product_model.dart';

class ProductReviewsSection extends StatelessWidget {
  final ProductModel product;
  const ProductReviewsSection({super.key, required this.product});
  @override
  Widget build(BuildContext context) {
    final reviews = dummyReviews.where((r) => r.productId == product.id).toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Text(product.rating.toStringAsFixed(1), style: AppTextStyles.h1), const SizedBox(width: 8), RatingStars(value: product.rating, size: 16), const SizedBox(width: 8), Text('${product.reviewCount} ulasan', style: AppTextStyles.caption)]),
      const SizedBox(height: 12),
      if (reviews.isEmpty) Text('Belum ada ulasan untuk produk ini.', style: AppTextStyles.bodyMuted)
      else ...reviews.map((r) => Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(Icons.format_quote, size: 16, color: AppColors.border),
        Text(r.comment, style: AppTextStyles.body),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(r.author, style: AppTextStyles.label), Text('${r.city} · ${r.date}', style: AppTextStyles.caption)]),
          RatingStars(value: r.rating.toDouble(), size: 12),
        ]),
      ])))),
    ]);
  }
}
