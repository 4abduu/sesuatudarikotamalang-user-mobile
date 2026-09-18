import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../../data/models/product_model.dart';

class BadgeChip extends StatelessWidget {
  final BadgeType badge;
  const BadgeChip({super.key, required this.badge});

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg) = switch (badge) {
      BadgeType.limited => ('Limited Edition', AppColors.moss, AppColors.onMoss),
      BadgeType.story => ('Ada Cerita di Baliknya', AppColors.primary, AppColors.onPrimary),
      BadgeType.bestseller => ('Best Seller', AppColors.mustard, AppColors.foreground),
      BadgeType.none => ('', AppColors.surface, AppColors.foreground),
    };
    if (badge == BadgeType.none) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999), boxShadow: [BoxShadow(color: bg.withValues(alpha: 0.3), blurRadius: 4, offset: const Offset(0, 2))]),
      child: Text(label, style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: fg)),
    );
  }
}
