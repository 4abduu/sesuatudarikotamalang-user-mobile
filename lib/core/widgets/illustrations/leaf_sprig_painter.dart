import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// Line-art leaf sprig — port dari `LeafSprig` di referensi TSX
/// (`_line-art.tsx`, viewBox 120×120). Koordinat & stroke width diskalakan
/// mengikuti ukuran widget, sama seperti perilaku SVG.
///
/// Dipakai sebagai ornamen dekoratif (hero, motif kategori produk).
class LeafSprigPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  const LeafSprigPainter({this.color = AppColors.moss, this.strokeWidth = 2});

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide / 120;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth * s
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    void m(double x, double y) => path.moveTo(x * s, y * s);
    void c(double x1, double y1, double x2, double y2, double x3, double y3) =>
        path.cubicTo(x1 * s, y1 * s, x2 * s, y2 * s, x3 * s, y3 * s);

    // Batang utama.
    m(60, 110);
    c(60, 80, 60, 40, 60, 14);
    // Pasangan daun atas.
    m(60, 30);
    c(48, 28, 38, 22, 32, 12);
    c(44, 10, 54, 16, 60, 28);
    m(60, 30);
    c(72, 28, 82, 22, 88, 12);
    c(76, 10, 66, 16, 60, 28);
    // Pasangan daun tengah.
    m(60, 52);
    c(46, 50, 34, 44, 26, 32);
    c(40, 30, 52, 38, 60, 50);
    m(60, 52);
    c(74, 50, 86, 44, 94, 32);
    c(80, 30, 68, 38, 60, 50);
    // Pasangan daun bawah.
    m(60, 74);
    c(48, 72, 38, 66, 30, 56);
    c(42, 54, 52, 60, 60, 72);
    m(60, 74);
    c(72, 72, 82, 66, 90, 56);
    c(78, 54, 68, 60, 60, 72);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant LeafSprigPainter old) =>
      old.color != color || old.strokeWidth != strokeWidth;
}

/// Convenience widget wrapping [LeafSprigPainter] in a [CustomPaint].
class LeafSprig extends StatelessWidget {
  final double size;
  final Color color;
  final double strokeWidth;
  const LeafSprig({
    super.key,
    this.size = 48,
    this.color = AppColors.moss,
    this.strokeWidth = 2,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: LeafSprigPainter(color: color, strokeWidth: strokeWidth),
        size: Size.square(size),
      ),
    );
  }
}
