import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/product_card.dart';
import '../../../data/dummy/dummy_products.dart';
import '../../../data/models/product_model.dart';

class RelatedProductsSection extends StatelessWidget {
  final ProductModel product;
  const RelatedProductsSection({super.key, required this.product});
  @override
  Widget build(BuildContext context) {
    final related = dummyProducts.where((p) => p.categoryId == product.categoryId && p.id != product.id).take(4).toList();
    if (related.isEmpty) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Produk Serupa', style: AppTextStyles.h2),
      const SizedBox(height: 12),
      GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: 0.72),
        itemCount: related.length,
        itemBuilder: (_, i) => ProductCard(product: related[i], onTap: () => context.push('/produk/${related[i].id}')),
      ),
    ]);
  }
}
