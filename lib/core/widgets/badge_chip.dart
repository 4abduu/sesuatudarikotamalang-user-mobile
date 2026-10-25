import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../theme/app_shadows.dart';
import '../../data/models/product_model.dart';

/// Badge sticker (padanan `StickerBadge` di referensi TSX): ikon 12px + label.
///
/// [compact] = varian `size="sm"` (py 2, bayangan sticker) yang dipakai di
/// atas gambar kartu produk. [large] = varian `size="md"` di detail produk
/// (px 12, py 4, teks 12, ikon 14). Default = varian hero/CTA (py 4).
class BadgeChip extends StatelessWidget {
  final BadgeType badge;
  final bool compact;
  final bool large;
  const BadgeChip({super.key, required this.badge, this.compact = false, this.large = false});

  @override
  Widget build(BuildContext context) {
    final (label, icon, bg, fg) = switch (badge) {
      BadgeType.limited => ('Limited Edition', Icons.local_fire_department_outlined, AppColors.moss, AppColors.onMoss),
      BadgeType.story => ('Ada Cerita di Baliknya', Icons.menu_book_outlined, AppColors.primary, AppColors.onPrimary),
      BadgeType.bestseller => ('Best Seller', Icons.auto_awesome, AppColors.mustard, AppColors.foreground),
      BadgeType.none => ('', Icons.circle, AppColors.surface, AppColors.foreground),
    };
    if (badge == BadgeType.none) return const SizedBox.shrink();
    return Container(
      padding: EdgeInsets.symmetric(horizontal: large ? 12 : 10, vertical: compact ? 2 : 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        boxShadow: (compact || large)
            ? AppShadows.sticker
            : [BoxShadow(color: bg.withValues(alpha: 0.3), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: large ? 14 : 12, color: fg),
          const SizedBox(width: 4),
          Text(label, style: GoogleFonts.poppins(fontSize: large ? 12 : 11, fontWeight: FontWeight.w600, color: fg)),
        ],
      ),
    );
  }
}
