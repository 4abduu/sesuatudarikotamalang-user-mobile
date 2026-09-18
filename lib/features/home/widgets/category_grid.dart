import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/dummy/dummy_categories.dart';

class CategoryGrid extends StatelessWidget {
  const CategoryGrid({super.key});
  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Pilih sesuai katamu', style: AppTextStyles.h2),
      const SizedBox(height: 12),
      GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: 0.85),
        itemCount: dummyCategories.length,
        itemBuilder: (_, i) {
          final c = dummyCategories[i];
          return GestureDetector(onTap: () => context.push('/katalog?kategori=${c.id}'), child: Container(decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border, width: 0.5)),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(width: 36, height: 36, decoration: BoxDecoration(color: AppColors.surfaceAlt, borderRadius: BorderRadius.circular(10)), child: Icon(_catIcon(c.iconName), size: 18, color: AppColors.primary)),
              const SizedBox(height: 6),
              Text(c.name, style: AppTextStyles.label, textAlign: TextAlign.center),
            ])));
        },
      ),
    ]);
  }
  IconData _catIcon(String name) {
    switch (name) {
      case 'mail': return Icons.mail_outline;
      case 'circle-dot': return Icons.circle_outlined;
      case 'shirt': return Icons.checkroom;
      case 'sticker': return Icons.label_outline;
      case 'tree-pine': return Icons.park;
      case 'shopping-bag': return Icons.shopping_bag_outlined;
      case 'coffee': return Icons.coffee_outlined;
      case 'book-open': return Icons.book_outlined;
      default: return Icons.category;
    }
  }
}
