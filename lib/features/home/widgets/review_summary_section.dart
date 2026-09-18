import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/rating_stars.dart';
import '../../../data/dummy/dummy_reviews.dart';

class ReviewSummarySection extends StatelessWidget {
  const ReviewSummarySection({super.key});
  @override
  Widget build(BuildContext context) {
    final recent = dummyReviews.where((r) => r.productId == null).take(3).toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Cerita dari pembeli', style: AppTextStyles.h2),
      const SizedBox(height: 12),
      ...recent.map((r) => Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(Icons.format_quote, size: 20, color: AppColors.border),
        Text(r.comment, style: AppTextStyles.body),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(r.author, style: AppTextStyles.label), Text('${r.city} · ${r.date}', style: AppTextStyles.caption)]),
          RatingStars(value: r.rating.toDouble(), size: 12),
        ]),
      ])))),
      const SizedBox(height: 12),
      Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(16)),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.star, color: AppColors.mustard, size: 20),
          const SizedBox(width: 8),
          Text('Rating toko', style: AppTextStyles.bodyMuted),
          const SizedBox(width: 8),
          Text(storeRating.toString(), style: AppTextStyles.h2),
          const SizedBox(width: 4),
          RatingStars(value: storeRating, size: 16),
          const SizedBox(width: 8),
          Text('dari $storeReviewTotal ulasan', style: AppTextStyles.caption),
        ])),
    ]);
  }
}
