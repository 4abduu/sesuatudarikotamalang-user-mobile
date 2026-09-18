import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/dummy/dummy_categories.dart';

class CategoryFilterChips extends StatelessWidget {
  final String? selected;
  final ValueChanged<String?> onSelected;
  const CategoryFilterChips({super.key, this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return SizedBox(height: 40, child: ListView(scrollDirection: Axis.horizontal, children: [
      _chip('Semua', selected == null || selected!.isEmpty, () => onSelected(null)),
      ...dummyCategories.map((c) => _chip(c.name, selected == c.id, () => onSelected(c.id))),
    ]));
  }

  Widget _chip(String label, bool active, VoidCallback onTap) {
    return Padding(padding: const EdgeInsets.only(right: 8), child: GestureDetector(onTap: onTap,
      child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(color: active ? AppColors.primary : AppColors.surface, borderRadius: BorderRadius.circular(999), border: Border.all(color: active ? AppColors.primary : AppColors.border)),
        child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: active ? AppColors.onPrimary : AppColors.foreground)))));
  }
}
