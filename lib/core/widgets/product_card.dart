import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../../data/models/product_model.dart';
import '../../data/dummy/dummy_categories.dart';
import 'badge_chip.dart';
import 'rating_stars.dart';
import '../utils/currency_formatter.dart';

class ProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback? onTap;
  const ProductCard({super.key, required this.product, this.onTap});

  @override
  Widget build(BuildContext context) {
    final cat = dummyCategories.firstWhere((c) => c.id == product.categoryId, orElse: () => dummyCategories.first);
    return GestureDetector(
      onTap: onTap,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: Stack(children: [
              Positioned.fill(child: _ArtPlaceholder(seed: product.id)),
              if (product.badge != BadgeType.none) Positioned(top: 8, left: 8, child: BadgeChip(badge: product.badge)),
              Positioned(bottom: 8, right: 8, child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: AppColors.background.withValues(alpha: 0.85), borderRadius: BorderRadius.circular(999)), child: Text(cat.name, style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.muted)))),
            ]),
          ),
          Padding(padding: const EdgeInsets.all(10), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(product.name, style: GoogleFonts.baloo2(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.foreground), maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text(product.shortDesc, style: GoogleFonts.poppins(fontSize: 11, color: AppColors.muted), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 6),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(formatRupiah(product.price), style: GoogleFonts.baloo2(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.primary)),
              RatingStars(value: product.rating, size: 11),
            ]),
            const SizedBox(height: 2),
            Text('${product.soldCount} terjual', style: GoogleFonts.poppins(fontSize: 10, color: AppColors.muted)),
          ])),
        ]),
      ),
    );
  }
}

/// Deterministic gradient + motif placeholder (padanan ArtImage di web).
class _ArtPlaceholder extends StatelessWidget {
  final String seed;
  const _ArtPlaceholder({required this.seed});

  int get _hash {
    int h = 0;
    for (int i = 0; i < seed.length; i++) {
      h = (h << 5) - h + seed.codeUnitAt(i);
    }
    return h.abs();
  }

  @override
  Widget build(BuildContext context) {
    const palettes = [
      [Color(0xFFA8452B), Color(0xFFC45A3A)],
      [Color(0xFF6B7A3D), Color(0xFF8A9D52)],
      [Color(0xFFC99A2E), Color(0xFFE0B85A)],
      [Color(0xFF8A6A3A), Color(0xFFA8855A)],
    ];
    final p = palettes[_hash % palettes.length];
    return Container(
      decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: p)),
      child: Center(child: Icon(Icons.brush_outlined, size: 36, color: AppColors.onPrimary.withValues(alpha: 0.3))),
    );
  }
}
