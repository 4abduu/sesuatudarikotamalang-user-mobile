import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/badge_chip.dart';
import '../../../data/models/product_model.dart';

class BehindTheDesignSection extends StatelessWidget {
  final ProductModel product;
  const BehindTheDesignSection({super.key, required this.product});
  @override
  Widget build(BuildContext context) {
    if (product.story == null) return const SizedBox.shrink();
    final s = product.story!;
    // Kartu: radius 20, surface, border 1px, soft shadow, p-4.
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.soft,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const BadgeChip(badge: BadgeType.story, large: true),
        const SizedBox(height: 12),
        Text(s.title, style: AppTextStyles.h2.copyWith(height: 1.25)),
        const SizedBox(height: 8),
        Text(s.body, style: AppTextStyles.body.copyWith(height: 1.375)),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('PROSES PEMBUATAN', style: AppTextStyles.eyebrow),
            const SizedBox(height: 4),
            Text(s.process ?? '', style: AppTextStyles.body.copyWith(height: 1.375)),
          ]),
        ),
      ]),
    );
  }
}
