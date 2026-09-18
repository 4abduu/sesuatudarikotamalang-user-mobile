import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// Paints a simple leaf-sprig ornament — two leaves on a curved stem.
///
/// Used as a decorative flourish on hero sections, section headers,
/// and craft cards. Designed to be lightweight (single Path) so it
/// can be embedded in many places without perf impact.
class LeafSprigPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  const LeafSprigPainter({this.color = AppColors.moss, this.strokeWidth = 2});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Stem — gentle curve from bottom-left to upper-right.
    final stem = Path();
    stem.moveTo(0, size.height);
    stem.cubicTo(
      size.width * 0.35, size.height * 0.55,
      size.width * 0.65, size.height * 0.45,
      size.width, 0,
    );
    canvas.drawPath(stem, paint);

    // Leaf 1 (lower-left).
    final leaf1 = Path();
    final l1Base = Offset(size.width * 0.25, size.height * 0.75);
    leaf1.moveTo(l1Base.dx, l1Base.dy);
    leaf1.cubicTo(
      l1Base.dx - size.width * 0.25, l1Base.dy - size.height * 0.05,
      l1Base.dx - size.width * 0.30, l1Base.dy - size.height * 0.30,
      l1Base.dx - size.width * 0.05, l1Base.dy - size.height * 0.45,
    );
    leaf1.cubicTo(
      l1Base.dx - size.width * 0.05, l1Base.dy - size.height * 0.25,
      l1Base.dx + size.width * 0.05, l1Base.dy - size.height * 0.15,
      l1Base.dx, l1Base.dy,
    );
    canvas.drawPath(leaf1, fillPaint);

    // Leaf 2 (upper-right).
    final leaf2 = Path();
    final l2Base = Offset(size.width * 0.70, size.height * 0.30);
    leaf2.moveTo(l2Base.dx, l2Base.dy);
    leaf2.cubicTo(
      l2Base.dx + size.width * 0.20, l2Base.dy + size.height * 0.10,
      l2Base.dx + size.width * 0.30, l2Base.dy - size.height * 0.10,
      l2Base.dx + size.width * 0.10, l2Base.dy - size.height * 0.35,
    );
    leaf2.cubicTo(
      l2Base.dx + size.width * 0.05, l2Base.dy - size.height * 0.15,
      l2Base.dx - size.width * 0.05, l2Base.dy - size.height * 0.05,
      l2Base.dx, l2Base.dy,
    );
    canvas.drawPath(leaf2, fillPaint);
  }

  @override
  bool shouldRepaint(covariant LeafSprigPainter old) =>
    old.color != color || old.strokeWidth != strokeWidth;
}

/// Convenience widget wrapping [LeafSprigPainter] in a [CustomPaint].
class LeafSprig extends StatelessWidget {
  final double size;
  final Color color;
  const LeafSprig({super.key, this.size = 48, this.color = AppColors.moss});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: LeafSprigPainter(color: color), size: Size.square(size)),
    );
  }
}
