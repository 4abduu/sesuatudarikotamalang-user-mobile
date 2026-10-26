import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_shadows.dart';
import '../../data/models/product_model.dart';
import '../../features/catalog/providers/products_provider.dart';
import 'art_image.dart';
import 'badge_chip.dart';
import 'rating_stars.dart';
import '../utils/currency_formatter.dart';

class ProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback? onTap;
  const ProductCard({super.key, required this.product, this.onTap});

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<ProductsProvider>().categories;
    final catMatch = categories.where((c) => c.id == product.categoryId).toList();
    final catName = catMatch.isNotEmpty ? catMatch.first.name : '';
    return GestureDetector(
      onTap: onTap,
      // Kartu: radius 20, latar surface, border 1px, bayangan soft (TSX ProductCardMini).
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
          boxShadow: AppShadows.soft,
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: Stack(children: [
              Positioned.fill(
                child: ArtImage(
                  seed: product.id,
                  categoryId: product.categoryId,
                  label: product.name,
                ),
              ),
              if (product.badge != BadgeType.none)
                Positioned(top: 8, left: 8, child: BadgeChip(badge: product.badge, compact: true)),
              if (catName.isNotEmpty)
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.background.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      catName,
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.muted,
                      ),
                    ),
                  ),
                ),
            ]),
          ),
          Padding(padding: const EdgeInsets.all(10), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(product.name, style: GoogleFonts.baloo2(fontSize: 13, fontWeight: FontWeight.w700, height: 1.375, color: AppColors.foreground), maxLines: 2, overflow: TextOverflow.ellipsis),
            if (product.isOfficial) ...[
              const SizedBox(height: 3),
              Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.check_circle, size: 11, color: AppColors.primary),
                const SizedBox(width: 3),
                Text('Official Store', style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.primary)),
              ]),
            ],
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
