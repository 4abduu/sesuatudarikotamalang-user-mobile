import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../viewmodel/app_config_view_model.dart';

class CategoryFilterChips extends StatefulWidget {
  final String? selected;
  final ValueChanged<String?> onSelected;
  const CategoryFilterChips({super.key, this.selected, required this.onSelected});

  @override
  State<CategoryFilterChips> createState() => _CategoryFilterChipsState();
}

class _CategoryFilterChipsState extends State<CategoryFilterChips> {
  final ScrollController _scrollController = ScrollController();
  final List<GlobalKey> _chipKeys = [];
  int? _lastScrolledIndex;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToSelected(int index) {
    if (index < 0 || index >= _chipKeys.length) return;
    final keyContext = _chipKeys[index].currentContext;
    if (keyContext != null) {
      Scrollable.ensureVisible(
        keyContext,
        alignment: 0.5,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else if (_scrollController.hasClients) {
      // Fallback perkiraan offset: 1 chip ~ 95px
      final estimatedOffset = (index * 95.0) - 100.0;
      final target = estimatedOffset.clamp(0.0, _scrollController.position.maxScrollExtent);
      _scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _triggerAutoScroll(int index) {
    _lastScrolledIndex = index;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _scrollToSelected(index);
      // Coba sekali lagi dengan jeda untuk memastikan context sudah terpasang
      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted) _scrollToSelected(index);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<AppConfigViewModel>().categories;

    // +1 for "Semua" chip
    while (_chipKeys.length < categories.length + 1) {
      _chipKeys.add(GlobalKey());
    }

    // Find the active index to auto-scroll after build
    int activeIndex = 0; // "Semua" by default
    if (widget.selected != null && widget.selected!.isNotEmpty) {
      for (int i = 0; i < categories.length; i++) {
        if (widget.selected == categories[i].id ||
            (categories[i].slug.isNotEmpty && widget.selected == categories[i].slug)) {
          activeIndex = i + 1;
          break;
        }
      }
    }

    if (activeIndex != _lastScrolledIndex) {
      _triggerAutoScroll(activeIndex);
    }

    return SizedBox(
      height: 48,
      child: Scrollbar(
        controller: _scrollController,
        thumbVisibility: true,
        thickness: 3,
        radius: const Radius.circular(999),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: SingleChildScrollView(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            child: Row(
              children: [
                _chip(
                  'Semua',
                  widget.selected == null || widget.selected!.isEmpty,
                  () => widget.onSelected(null),
                  _chipKeys[0],
                ),
                ...categories.asMap().entries.map(
                  (entry) => _chip(
                    entry.value.name,
                    widget.selected == entry.value.id || (entry.value.slug.isNotEmpty && widget.selected == entry.value.slug),
                    () => widget.onSelected(entry.value.id),
                    _chipKeys[entry.key + 1],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _chip(String label, bool active, VoidCallback onTap, GlobalKey key) {
    return Padding(
      key: key,
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
