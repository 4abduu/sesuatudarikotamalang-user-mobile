import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/rating_stars.dart';
import '../../viewmodel/home_view_model.dart';

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
      final prov = context.read<HomeViewModel>();
      if (prov.storeReviews.isEmpty) {
        prov.init();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeViewModel>(
      builder: (context, prov, _) {
        final recent = prov.storeReviews.take(3).toList();
        final rating = prov.storeRating;
        final total = prov.storeReviewTotal;

        // Jika belum ada ulasan sama sekali dari backend dan rating 0, jangan tampilkan data palsu
        if (recent.isEmpty && total == 0) {
          return const SizedBox.shrink();
        }

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
                        Text(
                          r.city.isNotEmpty ? '${r.city} · ${formatDateShort(r.date)}' : formatDateShort(r.date),
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                    RatingStars(value: r.rating.toDouble(), size: 12, showValue: true),
                  ]),
                ]),
              ),
            )),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.center,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.star_rounded, color: AppColors.mustard, size: 22),
                  const SizedBox(width: 6),
                  Text('Rating toko', style: AppTextStyles.bodyMuted),
                  const SizedBox(width: 6),
                  Text(
                    rating > 0 ? rating.toStringAsFixed(1) : '0.0',
                    style: AppTextStyles.h2.copyWith(fontSize: 18),
                  ),
                  const SizedBox(width: 6),
                  RatingStars(value: rating, size: 12, showValue: false),
                  const SizedBox(width: 6),
                  Text(
                    '($total ulasan)',
                    style: AppTextStyles.caption.copyWith(fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ]);
      },
    );
  }
}

