import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../catalog/providers/products_provider.dart';

class CategoryGrid extends StatelessWidget {
  const CategoryGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<ProductsProvider>().categories;

    if (categories.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Pilih sesuai katamu', style: AppTextStyles.h2),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            // Tinggi tile mengikuti TSX: py-2 + ikon 36 + gap 6 + 1 baris label.
            mainAxisExtent: 80,
          ),
          itemCount: categories.length,
          itemBuilder: (_, i) {
            final c = categories[i];
            return GestureDetector(
              onTap: () => context.push('/katalog?kategori=${c.id}'),

              // ===============================================================
              // OPTION 1 (UTAMA): Kodingan Awal (Menggunakan Icon & Text)
              // ===============================================================
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                  boxShadow: AppShadows.soft,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceAlt,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        _catIcon(c.iconName),
                        size: 18,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          c.name,
                          style: AppTextStyles.label,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ===============================================================
              // OPTION 2: Kodingan Gambar Figma (Menggunakan Asset Image)
              // Hilangkan komentar di bawah jika ingin menggunakan versi gambar.
              // ===============================================================
              // child: ClipRRect(
              //   borderRadius: BorderRadius.circular(16),
              //   child: Container(
              //     decoration: BoxDecoration(
              //       color: AppColors.surface,
              //       borderRadius: BorderRadius.circular(16),
              //       border: Border.all(color: AppColors.border, width: 0.5),
              //     ),
              //     child: Stack(
              //       children: [
              //         Positioned.fill(
              //           child: c.imagePath.isNotEmpty
              //               ? Image.asset(
              //                   c.imagePath,
              //                   fit: BoxFit.cover,
              //                   errorBuilder: (_, __, ___) => Center(
              //                     child: Text(
              //                       c.name,
              //                       style: AppTextStyles.label,
              //                       textAlign: TextAlign.center,
              //                     ),
              //                   ),
              //                 )
              //               : Container(color: AppColors.surfaceAlt),
              //         ),
              //       ],
              //     ),
              //   ),
              // ),
            );
          },
        ),
      ],
    );
  }

  // Helper method untuk icon pada kodingan awal
  IconData _catIcon(String name) {
    switch (name) {
      case 'mail':
        return Icons.mail_outline;
      case 'circle-dot':
        return Icons.circle_outlined;
      case 'shirt':
        return Icons.checkroom;
      case 'sticker':
        return Icons.label_outline;
      case 'tree-pine':
        return Icons.park;
      case 'shopping-bag':
        return Icons.shopping_bag_outlined;
      case 'coffee':
        return Icons.coffee_outlined;
      case 'book-open':
        return Icons.book_outlined;
      default:
        return Icons.category;
    }
  }
}
