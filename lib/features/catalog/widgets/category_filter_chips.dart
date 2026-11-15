import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/products_provider.dart';

class CategoryFilterChips extends StatefulWidget {
  final String? selected;
  final ValueChanged<String?> onSelected;
  const CategoryFilterChips({super.key, this.selected, required this.onSelected});

  @override
  State<CategoryFilterChips> createState() => _CategoryFilterChipsState();
}

class _CategoryFilterChipsState extends State<CategoryFilterChips> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<ProductsProvider>().categories;

    return SizedBox(
      height: 48,
      child: Scrollbar(
        controller: _scrollController,
        thumbVisibility: true,
        thickness: 3,
        radius: const Radius.circular(999),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: ListView(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            children: [
              _chip(
                'Semua',
                widget.selected == null || widget.selected!.isEmpty,
                () => widget.onSelected(null),
              ),
              ...categories.map(
                (c) => _chip(
                  c.name,
                  widget.selected == c.id || (c.slug.isNotEmpty && widget.selected == c.slug),
                  () => widget.onSelected(c.id),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(String label, bool active, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Align(
        alignment: Alignment.topLeft,
        widthFactor: 1,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
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
