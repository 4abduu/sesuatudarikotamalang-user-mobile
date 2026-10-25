import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import 'leaf_sprig_painter.dart';
import 'swirl_ornament_painter.dart';

/// Motif line-art per kategori produk — padanan `CategoryMotif` di referensi
/// TSX (`_line-art.tsx`). Dipakai sebagai hiasan samar di atas placeholder
/// gambar produk.
///
/// Pemetaan (sama dengan `motifByCategory` di TSX):
///   postcard, zine            → jendela heritage
///   pin-enamel, keramik       → matahari
///   apparel, tote-bag         → swirl
///   stiker, kriya-kayu, lain  → leaf sprig
class CategoryMotif extends StatelessWidget {
  final String? categoryId;
  final double size;
  final Color color;
  final double strokeWidth;
  const CategoryMotif({
    super.key,
    required this.categoryId,
    this.size = 48,
    this.color = AppColors.onPrimary,
    this.strokeWidth = 2,
  });

  @override
  Widget build(BuildContext context) {
    switch (categoryId) {
      case 'postcard':
      case 'zine':
        return _paint(_HeritageWindowPainter(color, strokeWidth));
      case 'pin-enamel':
      case 'keramik':
        return _paint(_SunMotifPainter(color, strokeWidth));
      case 'apparel':
      case 'tote-bag':
        return SwirlOrnament(size: size, color: color, strokeWidth: strokeWidth);
      default:
        return LeafSprig(size: size, color: color, strokeWidth: strokeWidth);
    }
  }

  Widget _paint(CustomPainter painter) => SizedBox(
        width: size,
        height: size,
        child: CustomPaint(painter: painter, size: Size.square(size)),
      );
}

Paint _stroke(Color color, double width, double s) => Paint()
  ..color = color
  ..style = PaintingStyle.stroke
  ..strokeWidth = width * s
  ..strokeCap = StrokeCap.round
  ..strokeJoin = StrokeJoin.round;

class _HeritageWindowPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  const _HeritageWindowPainter(this.color, this.strokeWidth);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide / 120;
    final paint = _stroke(color, strokeWidth, s);
    final path = Path();
    void m(double x, double y) => path.moveTo(x * s, y * s);
    void l(double x, double y) => path.lineTo(x * s, y * s);
    void c(double x1, double y1, double x2, double y2, double x3, double y3) =>
        path.cubicTo(x1 * s, y1 * s, x2 * s, y2 * s, x3 * s, y3 * s);

    m(30, 100);
    l(30, 48);
    c(30, 40, 38, 30, 60, 28);
    c(82, 30, 90, 40, 90, 48);
    l(90, 100);
    m(30, 100);
    l(90, 100);
    m(60, 28);
    l(60, 100);
    m(30, 58);
    l(90, 58);
    m(42, 70);
    l(54, 70);
    l(54, 100);
    l(42, 100);
    path.close();
    m(66, 70);
    l(78, 70);
    l(78, 100);
    l(66, 100);
    path.close();
    m(44, 44);
    c(50, 38, 70, 38, 76, 44);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _HeritageWindowPainter old) =>
      old.color != color || old.strokeWidth != strokeWidth;
}

class _SunMotifPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  const _SunMotifPainter(this.color, this.strokeWidth);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide / 120;
    final paint = _stroke(color, strokeWidth, s);
    final center = Offset(60 * s, 60 * s);
    canvas.drawCircle(center, 20 * s, paint);
    for (var i = 0; i < 12; i++) {
      final a = i * 30 * math.pi / 180;
      canvas.drawLine(
        Offset((60 + math.cos(a) * 26) * s, (60 + math.sin(a) * 26) * s),
        Offset((60 + math.cos(a) * 40) * s, (60 + math.sin(a) * 40) * s),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SunMotifPainter old) =>
      old.color != color || old.strokeWidth != strokeWidth;
}
