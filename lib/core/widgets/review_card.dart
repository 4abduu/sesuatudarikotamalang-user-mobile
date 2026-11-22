import 'package:flutter/material.dart';
import '../../data/models/review_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_shadows.dart';
import '../theme/app_text_styles.dart';
import 'rating_stars.dart';

class ReviewCard extends StatelessWidget {
  final ReviewModel review;

  const ReviewCard({super.key, required this.review});

  @override
  Widget build(BuildContext context) {
    final dateStr = review.date.length >= 10 ? review.date.substring(0, 10) : review.date;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.format_quote, size: 16, color: AppColors.border),
          const SizedBox(height: 4),
          Text(review.comment, style: AppTextStyles.body.copyWith(height: 1.375)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(review.author, style: AppTextStyles.label),
                  Text(
                    '${review.city} · $dateStr',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
              RatingStars(value: review.rating.toDouble(), size: 12, showValue: true),
            ],
          ),
        ],
      ),
    );
  }
}

