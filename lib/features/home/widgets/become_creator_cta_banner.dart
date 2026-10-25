import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/widgets/badge_chip.dart';
import '../../../core/widgets/illustrations/swirl_ornament_painter.dart';
import '../../../data/models/product_model.dart';

class BecomeCreatorCtaBanner extends StatelessWidget {
  const BecomeCreatorCtaBanner({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(24), boxShadow: AppShadows.sticker),
      child: Stack(clipBehavior: Clip.none, children: [
        // Ornamen swirl 80px, 20%, sedikit keluar dari sudut kanan atas (-mr-2 -mt-2).
        Positioned(
          top: -8,
          right: -8,
          child: SwirlOrnament(size: 80, color: AppColors.onPrimary.withValues(alpha: 0.2)),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Align(alignment: Alignment.centerLeft, child: BadgeChip(badge: BadgeType.limited)),
          const SizedBox(height: 12),
          Text('Punya karya sendiri? Gabung jadi kreator kami.', style: GoogleFonts.baloo2(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.onPrimary, height: 1.2)),
          const SizedBox(height: 8),
          Text('Konsinyasikan karyamu di toko fisik Kayutangan. Kami bantu kurasi, pajang, dan jualkan — kamu tinggal fokus berkarya.', style: GoogleFonts.poppins(fontSize: 13, height: 1.375, color: AppColors.onPrimary.withValues(alpha: 0.8))),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => context.push('/daftar-kreator'), style: ElevatedButton.styleFrom(backgroundColor: AppColors.onPrimary, foregroundColor: AppColors.primary, elevation: 0, padding: const EdgeInsets.symmetric(vertical: 14), textStyle: GoogleFonts.baloo2(fontSize: 14, fontWeight: FontWeight.w700)), child: const Text('Daftar jadi kreator'))),
        ]),
      ]));
  }
}
