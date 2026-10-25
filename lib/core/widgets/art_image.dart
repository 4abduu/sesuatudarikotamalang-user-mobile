import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import 'illustrations/category_motif.dart';

/// Placeholder gambar deterministik (padanan `ArtImage` di referensi TSX):
/// gradien 140° dari 6 pasang warna brand, motif line-art besar samar di
/// pojok kanan atas, motif tengah, dan nama produk di bagian bawah.
///
/// Dipakai oleh kartu produk dan galeri detail produk. [colors] opsional
/// untuk memaksa pasangan warna tertentu (mis. thumbnail galeri).
class ArtImage extends StatelessWidget {
  /// Pasangan warna gradien (urutan sama dengan `ArtImage` di TSX).
  static const List<List<Color>> palettes = [
    [Color(0xFFA8452B), Color(0xFFC45A3A)],
    [Color(0xFF6B7A3D), Color(0xFF8A9D52)],
    [Color(0xFFC99A2E), Color(0xFFE0B85A)],
    [Color(0xFF8A6A3A), Color(0xFFA8855A)],
    [Color(0xFF8B3823), Color(0xFFA8452B)],
    [Color(0xFF7A6A3D), Color(0xFFA89058)],
  ];

  /// CSS `linear-gradient(140deg, ...)`.
  static LinearGradient gradient(List<Color> colors) => LinearGradient(
        begin: const Alignment(-0.643, -0.766),
        end: const Alignment(0.643, 0.766),
        colors: colors,
      );

  final String seed;
  final String? categoryId;
  final String label;
  final List<Color>? colors;
  const ArtImage({
    super.key,
    required this.seed,
    required this.categoryId,
    required this.label,
    this.colors,
  });

  int get _hash {
    int h = 0;
    for (int i = 0; i < seed.length; i++) {
      h = (h << 5) - h + seed.codeUnitAt(i);
    }
    return h.abs();
  }

  @override
  Widget build(BuildContext context) {
    final p = colors ?? palettes[_hash % palettes.length];
    return Container(
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(gradient: gradient(p)),
      child: Stack(
        children: [
          Positioned(
            right: -24,
            top: -24,
            child: CategoryMotif(
              categoryId: categoryId,
              size: 160,
              color: AppColors.onPrimary.withValues(alpha: 0.15),
            ),
          ),
          Center(
            child: CategoryMotif(
              categoryId: categoryId,
              size: 112,
              color: AppColors.onPrimary.withValues(alpha: 0.4),
              strokeWidth: 2.5,
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.baloo2(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  height: 1.25,
                  color: AppColors.onPrimary.withValues(alpha: 0.9),
                  shadows: [
                    Shadow(
                      color: AppColors.foreground.withValues(alpha: 0.25),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
