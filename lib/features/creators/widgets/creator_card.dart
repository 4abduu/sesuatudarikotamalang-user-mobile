import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/rating_stars.dart';
import '../../../data/models/creator_model.dart';
import '../../../core/widgets/creator_avatar.dart';

class CreatorCard extends StatelessWidget {
  final CreatorModel creator;
  final VoidCallback? onTap;
  const CreatorCard({super.key, required this.creator, this.onTap});

  @override
  Widget build(BuildContext context) {
    final caption11 = AppTextStyles.caption.copyWith(fontSize: 11);
    return GestureDetector(
      onTap: onTap,
      // Kartu: radius 20, latar surface, border 1px, bayangan soft, padding 12.
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
          boxShadow: AppShadows.soft,
        ),
        child: Row(children: [
          CreatorAvatar(
            avatarUrl: creator.avatarUrl,
            name: creator.name,
            size: 48,
            isOfficial: creator.isOfficial,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(
                children: [
                  Flexible(child: Text(creator.name, style: AppTextStyles.h3.copyWith(fontSize: 16, height: 1.25), overflow: TextOverflow.ellipsis)),
                  if (creator.isOfficial) ...[
                    const SizedBox(width: 4),
                    const Icon(Icons.check_circle, size: 14, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text('Official', style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.w600, color: AppColors.primary)),
                    ),
                  ],
                ],
              ),
              Text(creator.isOfficial ? 'Official Store' : '@${creator.handle}', style: caption11),
              const SizedBox(height: 2),
              Text(creator.bio, style: caption11, maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Row(children: [
                Text('${creator.productCount} produk', style: caption11),
                const SizedBox(width: 8),
                RatingStars(value: creator.rating, size: 10),
              ]),
            ]),
          ),
          const Icon(Icons.chevron_right, size: 16, color: AppColors.muted),
        ]),
      ),
    );
  }
}
