import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/product_card.dart';
import '../../../data/dummy/dummy_products.dart';

class RecommendationSection extends StatelessWidget {
  const RecommendationSection({super.key});
  @override
  Widget build(BuildContext context) {
    final recommended = [...dummyProducts]..sort((a, b) => b.soldCount.compareTo(a.soldCount));
    final top = recommended.take(4).toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('Paling banyak diburu', style: AppTextStyles.h2),
        TextButton(onPressed: () => context.push('/katalog'), child: const Text('Semua')),
      ]),
      GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: 0.72),
        itemCount: top.length,
        itemBuilder: (_, i) => ProductCard(product: top[i], onTap: () => context.push('/produk/${top[i].id}')),
      ),
    ]);
  }
}
