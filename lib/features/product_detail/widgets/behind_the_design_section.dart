import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
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
    return Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const BadgeChip(badge: BadgeType.story),
      const SizedBox(height: 12),
      Text(s.title, style: AppTextStyles.h2),
      const SizedBox(height: 8),
      Text(s.body, style: AppTextStyles.body),
      const SizedBox(height: 12),
      Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('PROSES PEMBUATAN', style: AppTextStyles.eyebrow),
          const SizedBox(height: 4),
          Text(s.process, style: AppTextStyles.body),
        ])),
    ])));
  }
}
