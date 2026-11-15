import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/rating_stars.dart';
import '../../account/providers/reviews_provider.dart';

class ReviewSummarySection extends StatefulWidget {
  const ReviewSummarySection({super.key});

  @override
  State<ReviewSummarySection> createState() => _ReviewSummarySectionState();
}

class _ReviewSummarySectionState extends State<ReviewSummarySection> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final prov = context.read<ReviewsProvider>();
      if (prov.storeReviews.isEmpty) {
        prov.fetchStoreReviews();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ReviewsProvider>(
      builder: (context, prov, _) {
        final recent = prov.storeReviews.take(3).toList();
        final rating = prov.storeRating > 0 ? prov.storeRating : 4.4;
        final total = prov.storeReviewTotal > 0 ? prov.storeReviewTotal : 191;

        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Cerita dari pembeli', style: AppTextStyles.h2),
          const SizedBox(height: 12),
          // Kartu ulasan: radius 20, surface, border 1px, bayangan soft, p-3, jarak 8.
          if (recent.isNotEmpty)
            ...recent.map((r) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                  boxShadow: AppShadows.soft,
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Icon(Icons.format_quote, size: 20, color: AppColors.border),
                  const SizedBox(height: 4),
                  Text(r.comment, style: AppTextStyles.body.copyWith(height: 1.375)),
                  const SizedBox(height: 8),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r.author, style: AppTextStyles.label),
                        Text('${r.city} · ${r.date}', style: AppTextStyles.caption),
                      ],
                    ),
                    RatingStars(value: r.rating.toDouble(), size: 12),
                  ]),
                ]),
              ),
            )),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.star, color: AppColors.mustard, size: 20),
              const SizedBox(width: 8),
              Text('Rating toko', style: AppTextStyles.bodyMuted),
              const SizedBox(width: 8),
              Text(rating.toStringAsFixed(1), style: AppTextStyles.h2),
              const SizedBox(width: 4),
              RatingStars(value: rating, size: 12),
              const SizedBox(width: 8),
              Text('dari $total ulasan', style: AppTextStyles.caption),
            ]),
          ),
        ]);
      },
    );
  }
}
