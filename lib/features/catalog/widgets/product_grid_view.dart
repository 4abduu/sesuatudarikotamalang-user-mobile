import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/product_card.dart';
import '../../../data/models/product_model.dart';

class ProductGridView extends StatelessWidget {
  final List<ProductModel> products;
  const ProductGridView({super.key, required this.products});
  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) return const Center(child: Padding(padding: EdgeInsets.all(32), child: Text('Tidak ada produk yang cocok.')));
    return GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: 0.72),
      itemCount: products.length,
      itemBuilder: (_, i) => ProductCard(product: products[i], onTap: () => context.push('/produk/${products[i].id}')),
    );
  }
}
