import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// Paints a simple swirl ornament — a graceful S-curve spiral used as
/// a decorative divider or corner flourish. Drawn as a single Path
/// so it can be reused in many places without perf concerns.
class SwirlOrnamentPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  const SwirlOrnamentPainter({this.color = AppColors.primary, this.strokeWidth = 2});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Spiral: two revolutions tightening inward.
    final path = Path();
    final cx = size.width * 0.5;
    final cy = size.height * 0.5;
    final maxR = size.shortestSide * 0.45;
    const twoPi = 2 * math.pi;
    path.moveTo(cx + maxR, cy);
    for (var t = 0.0; t <= 2 * twoPi; t += 0.1) {
      final r = maxR * (1.0 - (t / (2 * twoPi)) * 0.7);
      final x = cx + r * math.cos(t);
      final y = cy + r * math.sin(t);
      path.lineTo(x, y);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant SwirlOrnamentPainter old) =>
    old.color != color || old.strokeWidth != strokeWidth;
}

/// Convenience widget wrapping [SwirlOrnamentPainter] in a [CustomPaint].
class SwirlOrnament extends StatelessWidget {
  final double size;
  final Color color;
  const SwirlOrnament({super.key, this.size = 32, this.color = AppColors.primary});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: SwirlOrnamentPainter(color: color), size: Size.square(size)),
    );
  }
}
