import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// Line-art swirl ornament — port dari `Swirl` di referensi TSX
/// (`_line-art.tsx`, viewBox 120×120). Koordinat & stroke width diskalakan
/// mengikuti ukuran widget, sama seperti perilaku SVG.
class SwirlOrnamentPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  const SwirlOrnamentPainter({this.color = AppColors.primary, this.strokeWidth = 2});

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

    // Spiral utama.
    m(60, 18);
    c(30, 18, 18, 42, 30, 66);
    c(40, 86, 64, 84, 70, 64);
    c(74, 50, 60, 42, 50, 50);
    c(44, 55, 46, 66, 56, 66);
    // Lengkung pendamping.
    m(84, 40);
    c(96, 52, 96, 74, 80, 86);

    canvas.drawPath(path, paint);
    canvas.drawCircle(Offset(60 * s, 60 * s), 3 * s, paint);
  }

  @override
  bool shouldRepaint(covariant SwirlOrnamentPainter old) =>
      old.color != color || old.strokeWidth != strokeWidth;
}

/// Convenience widget wrapping [SwirlOrnamentPainter] in a [CustomPaint].
class SwirlOrnament extends StatelessWidget {
  final double size;
  final Color color;
  final double strokeWidth;
  const SwirlOrnament({
    super.key,
    this.size = 32,
    this.color = AppColors.primary,
    this.strokeWidth = 2,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: SwirlOrnamentPainter(color: color, strokeWidth: strokeWidth),
        size: Size.square(size),
      ),
    );
  }
}
