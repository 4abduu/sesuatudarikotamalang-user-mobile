import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';

/// Tombol "Masuk dengan Google" — putih, full-width, rounded, dengan logo
/// Google multi-warna (CustomPaint, tanpa package tambahan).
///
/// Di versi final, `onTap` akan memanggil Google Sign-In SDK (lihat
/// dokumen master bagian 4.6 — Google Sign-In Mobile). Untuk prototype ini,
/// tombol hanya memanggil callback yang sama dengan tombol demo (login
/// sebagai buyer demo) supaya alur bisa didemokan tanpa OAuth sungguhan.
class GoogleSignInButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  const GoogleSignInButton(
      {super.key, this.label = 'Masuk dengan Google', this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: AppColors.foreground.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: Image.asset(
                  'assets/images/logos/google.png',
                  errorBuilder: (_, __, ___) => const _GoogleLogo(),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.foreground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/* ------------------------------------------------------------------ */
/* Google "G" logo — 4 colored arcs + horizontal bar                  */
/*                                                                    */
/* CustomPaint implementation (no flutter_svg package needed).         */
/* Color positions mirror Google's official "G" logo:                 */
/*   - Red    (top-right, ~12 o'clock to ~3 o'clock)                  */
/*   - Yellow (bottom-right, ~3 o'clock to ~6 o'clock)                */
/*   - Green  (bottom-left, ~6 o'clock to ~9 o'clock)                 */
/*   - Blue   (top-left, ~9 o'clock to ~12 o'clock)                   */
/* Plus a blue horizontal bar from center to right edge (G's bar).    */
/* ------------------------------------------------------------------ */

class _GoogleLogo extends StatelessWidget {
  const _GoogleLogo();
  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _GoogleLogoPainter());
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final stroke = size.width * 0.24;
    final r = (size.width - stroke) / 2;
    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: r);

    // Small gap between arcs (in degrees) untuk tampilan segmented.
    const gap = 4.0;
    // Flutter canvas: 0°=east, 90°=south, 180°=west, 270°=north (clockwise).
    // Arcs sweep clockwise.
    // Red: north → east (top-right)
    _drawArc(
        canvas, rect, const Color(0xFFEA4335), 270 + gap, 90 - 2 * gap, stroke);
    // Yellow: east → south (bottom-right)
    _drawArc(
        canvas, rect, const Color(0xFFFBBC05), 0 + gap, 90 - 2 * gap, stroke);
    // Green: south → west (bottom-left)
    _drawArc(
        canvas, rect, const Color(0xFF34A853), 90 + gap, 90 - 2 * gap, stroke);
    // Blue: west → north (top-left)
    _drawArc(
        canvas, rect, const Color(0xFF4285F4), 180 + gap, 90 - 2 * gap, stroke);

    // Horizontal bar (blue) from center to right — the "G" crossbar.
    final barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(cx - r * 0.45, cy),
      Offset(cx + r, cy),
      barPaint,
    );
  }

  void _drawArc(Canvas canvas, Rect rect, Color color, double startDeg,
      double sweepDeg, double strokeWidth) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      rect,
      startDeg * 3.141592653589793 / 180.0,
      sweepDeg * 3.141592653589793 / 180.0,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
