import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/widgets/badge_chip.dart';
import '../../../core/widgets/illustrations/leaf_sprig_painter.dart';
import '../../../core/widgets/illustrations/swirl_ornament_painter.dart';
import '../../../data/models/product_model.dart';
import '../../../data/dummy/dummy_reviews.dart';
import '../../../core/widgets/rating_stars.dart';

class HeroSection extends StatelessWidget {
  const HeroSection({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.primaryLight, AppColors.background])),
      child: Stack(children: [
        // Ornamen swirl besar samar di kanan atas (-right-4 top-8, 112px, 20%).
        Positioned(
          right: -16,
          top: 32,
          child: SwirlOrnament(
              size: 112, color: AppColors.onPrimary.withValues(alpha: 0.2)),
        ),
        SafeArea(
            child: Padding(
                // px-5 pt-10 pb-5
                padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        const BadgeChip(badge: BadgeType.story),
                        const Spacer(),
                        // Decorative ornament — leaf sprig on the right of the badge row.
                        LeafSprig(
                            size: 36,
                            color: AppColors.onPrimary.withValues(alpha: 0.6)),
                      ]),
                      const SizedBox(height: 12),
                      Text('Sesuatu dari\nKota Malang',
                          style: GoogleFonts.baloo2(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              color: AppColors.onPrimary,
                              height: 1.1)),
                      const SizedBox(height: 12),
                      Text(
                          'Oleh-oleh artisan & creative market dari kawasan Kayutangan Heritage. Setiap karya dibuat tangan, punya cerita.',
                          style: GoogleFonts.poppins(
                              fontSize: 13,
                              height: 1.375,
                              color:
                                  AppColors.onPrimary.withValues(alpha: 0.85))),
                      const SizedBox(height: 16),
                      // CTA card-like row with sticker shadow.
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.onPrimary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: AppShadows.sticker,
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Row(children: [
                          Expanded(
                              child: ElevatedButton(
                                  onPressed: () => context.push('/katalog'),
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.onPrimary,
                                      foregroundColor: AppColors.primary,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 12),
                                      textStyle: GoogleFonts.baloo2(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700)),
                                  child: const Text('Lihat Katalog'),
                              ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                              child: OutlinedButton(
                                  onPressed: () => context.push('/kreator'),
                                  style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.onPrimary,
                                      side: const BorderSide(
                                          color: AppColors.onPrimary, width: 1),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 12),
                                      textStyle: GoogleFonts.baloo2(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700)),
                                  child: const Text('Artisans'),
                              ),
                          ),
                        ]),
                      ),
                      const SizedBox(height: 12),
                      Row(children: [
                        RatingStars(value: storeRating, size: 12),
                        const SizedBox(width: 6),
                        Text(storeRating.toStringAsFixed(1),
                            style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.onPrimary)),
                        const SizedBox(width: 6),
                        Text('($storeReviewTotal ulasan)',
                            style: GoogleFonts.poppins(
                                fontSize: 11,
                                color:
                                    AppColors.onPrimary.withValues(alpha: 0.8))),
                        const Spacer(),
                        SwirlOrnament(
                            size: 18,
                            color: AppColors.onPrimary.withValues(alpha: 0.6)),
                        const SizedBox(width: 6),
                        const Icon(Icons.location_on_outlined,
                            size: 12, color: AppColors.onPrimary),
                        const SizedBox(width: 6),
                        Text('Kayutangan',
                            style: GoogleFonts.poppins(
                                fontSize: 11,
                                color:
                                    AppColors.onPrimary.withValues(alpha: 0.8))),
                      ]),
                    ]))),
      ]),
    );
  }
}
