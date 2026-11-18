import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/product_card.dart';
import '../../../../data/models/product_model.dart';
import '../../viewmodel/product_detail_view_model.dart';

class RelatedProductsSection extends StatelessWidget {
  final ProductModel product;
  const RelatedProductsSection({super.key, required this.product});
  @override
  Widget build(BuildContext context) {
    final related = context.watch<ProductDetailViewModel>().relatedProducts;
    if (related.isEmpty) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Produk Serupa', style: AppTextStyles.h2),
      const SizedBox(height: 12),
      GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: 0.6),
        itemCount: related.length,
        itemBuilder: (_, i) => ProductCard(
            product: related[i],
            onTap: () => context.pushNamed('productDetail',
                pathParameters: {'id': related[i].id})),
      ),
    ]);
  }
}
