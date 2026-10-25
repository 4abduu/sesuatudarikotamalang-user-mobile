import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';

enum SortOption { terbaru, termurah, termahal, terlaris }

class SortDropdown extends StatelessWidget {
  final SortOption value;
  final ValueChanged<SortOption?> onChanged;
  const SortDropdown({super.key, required this.value, required this.onChanged});

  // Teks pilihan: 12px semibold foreground (sesuai baris "Urut:" di TSX).
  static TextStyle get _itemStyle => GoogleFonts.poppins(
      fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.foreground);

  @override
  Widget build(BuildContext context) {
    return DropdownButton<SortOption>(
      value: value,
      onChanged: onChanged,
      underline: const SizedBox(),
      isDense: true,
      dropdownColor: AppColors.surface,
      // Chevron kecil 14px muted, rapat dengan teks.
      icon: const Padding(
        padding: EdgeInsets.only(left: 4),
        child: Icon(Icons.keyboard_arrow_down, size: 14, color: AppColors.muted),
      ),
      items: [
        DropdownMenuItem(value: SortOption.terbaru, child: Text('Terbaru', style: _itemStyle)),
        DropdownMenuItem(value: SortOption.termurah, child: Text('Termurah', style: _itemStyle)),
        DropdownMenuItem(value: SortOption.termahal, child: Text('Termahal', style: _itemStyle)),
        DropdownMenuItem(value: SortOption.terlaris, child: Text('Terlaris', style: _itemStyle)),
      ]);
  }
}
