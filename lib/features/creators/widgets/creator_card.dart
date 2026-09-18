import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/rating_stars.dart';
import '../../../data/models/creator_model.dart';

class CreatorCard extends StatelessWidget {
  final CreatorModel creator;
  final VoidCallback? onTap;
  const CreatorCard({super.key, required this.creator, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(onTap: onTap, child: Card(child: Padding(padding: const EdgeInsets.all(12), child: Row(children: [
      Container(width: 48, height: 48, decoration: const BoxDecoration(gradient: LinearGradient(colors: [AppColors.primary, AppColors.primaryLight]), shape: BoxShape.circle), child: Center(child: Text(creator.name.split(' ').map((w) => w[0]).take(2).join(), style: GoogleFonts.baloo2(fontWeight: FontWeight.w700, color: AppColors.onPrimary)))),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(creator.name, style: AppTextStyles.h3),
        Text('@${creator.handle}', style: AppTextStyles.caption),
        const SizedBox(height: 2),
        Text(creator.bio, style: GoogleFonts.poppins(fontSize: 12, color: AppColors.muted), maxLines: 1, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 4),
        Row(children: [
          Text('${creator.productCount} produk', style: AppTextStyles.caption),
          const SizedBox(width: 8),
          RatingStars(value: creator.rating, size: 10),
        ]),
      ])),
      const Icon(Icons.chevron_right, color: AppColors.muted),
    ]))));
  }
}
