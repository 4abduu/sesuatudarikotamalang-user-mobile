import 'package:flutter/material.dart';

enum SortOption { terbaru, termurah, termahal, terlaris }

class SortDropdown extends StatelessWidget {
  final SortOption value;
  final ValueChanged<SortOption?> onChanged;
  const SortDropdown({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return DropdownButton<SortOption>(value: value, onChanged: onChanged, underline: const SizedBox(), isDense: true,
      items: const [
        DropdownMenuItem(value: SortOption.terbaru, child: Text('Terbaru', style: TextStyle(fontSize: 13))),
        DropdownMenuItem(value: SortOption.termurah, child: Text('Termurah', style: TextStyle(fontSize: 13))),
        DropdownMenuItem(value: SortOption.termahal, child: Text('Termahal', style: TextStyle(fontSize: 13))),
        DropdownMenuItem(value: SortOption.terlaris, child: Text('Terlaris', style: TextStyle(fontSize: 13))),
      ]);
  }
}
