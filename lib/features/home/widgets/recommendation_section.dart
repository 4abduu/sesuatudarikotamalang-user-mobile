import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/product_card.dart';
import '../../catalog/providers/products_provider.dart';

class RecommendationSection extends StatelessWidget {
  const RecommendationSection({super.key});

  @override
  Widget build(BuildContext context) {
    final products = context.watch<ProductsProvider>().allProducts;
    final recommended = [...products]..sort((a, b) => b.soldCount.compareTo(a.soldCount));
    final top = recommended.take(4).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Paling banyak diburu', style: AppTextStyles.h2),
            TextButton(
              onPressed: () => context.push('/katalog'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                textStyle: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              child: const Text('Semua'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (top.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: Text('Belum ada produk rekomendasi')),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 0.6, // gambar ±persegi (aspect-square) + blok info
            ),
            itemCount: top.length,
            itemBuilder: (_, i) => ProductCard(
              product: top[i],
              onTap: () => context.push('/produk/${top[i].id}'),
            ),
          ),
      ],
    );
  }
}
