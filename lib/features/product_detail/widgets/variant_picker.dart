import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/product_model.dart';
import '../providers/variant_selection_provider.dart';

class VariantPicker extends StatelessWidget {
  final ProductModel product;
  final VariantSelectionProvider provider;
  const VariantPicker({super.key, required this.product, required this.provider});

  @override
  Widget build(BuildContext context) {
    if (!product.hasVariants) {
      return Text('Stok tersedia: ${product.totalStock}', style: AppTextStyles.bodyMuted);
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: product.variantOptions.asMap().entries.map((entry) {
      final i = entry.key;
      final opt = entry.value;
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(opt.name, style: AppTextStyles.label),
          Text(provider.selected[i] ?? 'Pilih dulu', style: AppTextStyles.caption),
        ]),
        const SizedBox(height: 6),
        Wrap(spacing: 8, runSpacing: 8, children: opt.values.map((v) {
          final active = provider.selected[i] == v;
          final available = provider.isValueAvailable(i, v);
          return GestureDetector(onTap: available ? () => provider.selectOption(i, v) : null,
            child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: active ? AppColors.primary : (available ? AppColors.surface : AppColors.surfaceAlt),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: active ? AppColors.primary : (available ? AppColors.border : AppColors.border)),
              ),
              child: Text(v, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: active ? AppColors.onPrimary : (available ? AppColors.foreground : AppColors.muted), decoration: available ? TextDecoration.none : TextDecoration.lineThrough))));
        }).toList()),
        const SizedBox(height: 12),
      ]);
    }).toList());
  }
}
