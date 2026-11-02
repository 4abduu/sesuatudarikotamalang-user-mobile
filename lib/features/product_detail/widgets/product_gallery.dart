import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../data/models/image_variant_link.dart';
import '../utils/gallery_target.dart';

/// Galeri produk dengan foto asli dari server.
///
/// - Foto tanpa tautan varian tampil lebih dulu, foto bertautan di akhir.
/// - Saat pembeli mengubah pilihan varian ([selected]), galeri berpindah ke foto
///   pertama yang tertaut ke nilai itu; bila tak ada foto tertaut, tidak pindah.
/// - Tanpa foto, tampil satu placeholder gradien seperti sebelumnya.
class ProductGallery extends StatefulWidget {
  final String seed;
  final List<String> images;
  final List<ImageVariantLink> links;
  final List<String> optionNames;
  final List<String?> selected;

  const ProductGallery({
    super.key,
    required this.seed,
    this.images = const [],
    this.links = const [],
    this.optionNames = const [],
    this.selected = const [],
  });

  @override
  State<ProductGallery> createState() => _ProductGalleryState();
}

class _ProductGalleryState extends State<ProductGallery> {
  late List<String> _ordered;
  final PageController _controller = PageController();
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _ordered = galleryOrder(widget.images, widget.links);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ProductGallery oldWidget) {
    super.didUpdateWidget(oldWidget);
    final listChanged = !listEquals(oldWidget.images, widget.images) ||
        oldWidget.links.length != widget.links.length;
    if (listChanged) {
      _ordered = galleryOrder(widget.images, widget.links);
      if (_index >= _ordered.length) _index = 0;
      if (_controller.hasClients) _controller.jumpToPage(_index);
    }
    final axis = changedAxisBetween(oldWidget.selected, widget.selected);
    final target = galleryTargetIndex(
      images: _ordered,
      links: widget.links,
      optionNames: widget.optionNames,
      selected: widget.selected,
      changedAxis: axis,
    );
    if (target != null && target != _index) {
      // Tidak memanggil setState di sini (build menyusul otomatis); animasi
      // dijalankan setelah frame agar PageView sudah terpasang.
      _index = target;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _controller.hasClients) _animateTo(target);
      });
    }
  }

  void _animateTo(int i) {
    _controller.animateToPage(i, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
  }

  void _goTo(int i) {
    if (i < 0 || i >= _ordered.length) return;
    setState(() => _index = i);
    if (_controller.hasClients) _animateTo(i);
  }

  Widget _network(String url, {BoxFit fit = BoxFit.cover}) {
    return Image.network(
      url,
      fit: fit,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (_, __, ___) => Container(
        color: AppColors.surfaceAlt,
        alignment: Alignment.center,
        child: Icon(Icons.broken_image_outlined, size: 40, color: AppColors.muted.withValues(alpha: 0.6)),
      ),
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Container(
          color: AppColors.surfaceAlt,
          alignment: Alignment.center,
          child: const CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_ordered.isEmpty) {
      return AspectRatio(
        aspectRatio: 1,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: _palette(widget.seed.hashCode.abs())),
            borderRadius: BorderRadius.circular(20),
            boxShadow: AppShadows.soft,
          ),
          child: Center(child: Icon(Icons.brush_outlined, size: 48, color: AppColors.onPrimary.withValues(alpha: 0.3))),
        ),
      );
    }

    return Column(
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: AppShadows.soft,
            ),
            clipBehavior: Clip.antiAlias,
            child: PageView.builder(
              controller: _controller,
              itemCount: _ordered.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (_, i) => _network(_ordered[i]),
            ),
          ),
        ),
        if (_ordered.length > 1) ...[
          const SizedBox(height: 8),
          SizedBox(
            height: 64,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _ordered.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final selected = i == _index;
                return GestureDetector(
                  onTap: () => _goTo(i),
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: selected ? AppColors.primary : Colors.transparent, width: 2),
                      boxShadow: selected ? AppShadows.sticker : null,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: _network(_ordered[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
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
