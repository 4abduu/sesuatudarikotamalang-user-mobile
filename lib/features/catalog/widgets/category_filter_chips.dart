import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/products_provider.dart';

class CategoryFilterChips extends StatelessWidget {
  final String? selected;
  final ValueChanged<String?> onSelected;
  const CategoryFilterChips({super.key, this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<ProductsProvider>().categories;
    // Tinggi 42 = chip (±38) + pb-1 (4) di TSX.
    return SizedBox(
      height: 42,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _chip('Semua', selected == null || selected!.isEmpty, () => onSelected(null)),
          ...categories.map(
            (c) => _chip(
              c.name,
              selected == c.id || (c.slug.isNotEmpty && selected == c.slug),
              () => onSelected(c.id),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, bool active, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      // Align: chip setinggi isinya (tidak melar mengikuti tinggi ListView).
      child: Align(
        alignment: Alignment.topLeft,
        widthFactor: 1,
        child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: active ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: active ? AppColors.primary : AppColors.border),
          ),
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: active ? AppColors.onPrimary : AppColors.foreground,
            ),
          ),
        ),
        ),
      ),
    );
  }
}
