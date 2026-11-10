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
            if (s.processImages.isNotEmpty) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 80,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: s.processImages.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (ctx, i) {
                    final imgUrl = s.processImages[i];
                    return GestureDetector(
                      onTap: () {
                        showDialog(
                          context: ctx,
                          builder: (dialogCtx) => Dialog(
                            backgroundColor: Colors.transparent,
                            insetPadding: const EdgeInsets.all(16),
                            child: Stack(
                              alignment: Alignment.topRight,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.network(imgUrl, fit: BoxFit.contain),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, color: Colors.white, size: 28),
                                  onPressed: () => Navigator.pop(dialogCtx),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          imgUrl,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 80,
                            height: 80,
                            color: AppColors.surfaceAlt,
                            child: const Icon(Icons.broken_image_outlined, size: 24, color: AppColors.muted),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ]),
        ),
      ]),
    );
  }
}
