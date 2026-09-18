import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/badge_chip.dart';
import '../../../data/models/product_model.dart';

class BecomeCreatorCtaBanner extends StatelessWidget {
  const BecomeCreatorCtaBanner({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(24)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const BadgeChip(badge: BadgeType.limited),
        const SizedBox(height: 12),
        Text('Punya karya sendiri? Gabung jadi kreator kami.', style: GoogleFonts.baloo2(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.onPrimary, height: 1.2)),
        const SizedBox(height: 8),
        Text('Konsinyasikan karyamu di toko fisik Kayutangan. Kami bantu kurasi, pajang, dan jualkan — kamu tinggal fokus berkarya.', style: GoogleFonts.poppins(fontSize: 13, color: AppColors.onPrimary.withValues(alpha: 0.8))),
        const SizedBox(height: 16),
        SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => context.push('/daftar-kreator'), style: ElevatedButton.styleFrom(backgroundColor: AppColors.onPrimary, foregroundColor: AppColors.primary), child: const Text('Daftar jadi kreator'))),
      ]));
  }
}
