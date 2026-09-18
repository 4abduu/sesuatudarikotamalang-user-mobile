import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';

class ProductGallery extends StatefulWidget {
  final String seed;
  const ProductGallery({super.key, required this.seed});
  @override
  State<ProductGallery> createState() => _ProductGalleryState();
}

class _ProductGalleryState extends State<ProductGallery> {
  int _index = 0;
  final _seeds = <String>[];

  @override
  void initState() {
    super.initState();
    _seeds.addAll([widget.seed, '${widget.seed}-2', '${widget.seed}-3', '${widget.seed}-4']);
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      AspectRatio(
        aspectRatio: 1,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: _palette(_index)),
            borderRadius: BorderRadius.circular(20),
            boxShadow: AppShadows.soft,
          ),
          child: Center(child: Icon(Icons.brush_outlined, size: 48, color: AppColors.onPrimary.withValues(alpha: 0.3))),
        ),
      ),
      const SizedBox(height: 8),
      Row(children: _seeds.asMap().entries.map((e) {
        final i = e.key;
        return Expanded(child: GestureDetector(
          onTap: () => setState(() => _index = i),
          child: AspectRatio(
            aspectRatio: 1,
            child: Container(
              margin: EdgeInsets.only(right: i < 3 ? 8 : 0),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: _palette(i)),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: i == _index ? AppColors.primary : Colors.transparent, width: 2),
                boxShadow: i == _index ? AppShadows.sticker : null,
              ),
            ),
          ),
        ));
      }).toList()),
    ]);
  }

  List<Color> _palette(int i) {
    const palettes = [
      [Color(0xFFA8452B), Color(0xFFC45A3A)],
      [Color(0xFF6B7A3D), Color(0xFF8A9D52)],
      [Color(0xFFC99A2E), Color(0xFFE0B85A)],
      [Color(0xFF8A6A3A), Color(0xFFA8855A)],
    ];
    return palettes[i % palettes.length];
  }
}
