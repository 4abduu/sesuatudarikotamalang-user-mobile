import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/reservation_flow_provider.dart';

class StepIndicator extends StatelessWidget {
  final ReservationStep current;
  const StepIndicator({super.key, required this.current});

  @override
  Widget build(BuildContext context) {
    final steps = ['Jadwal', 'Pembayaran', 'Selesai'];
    final currentIdx = current == ReservationStep.schedule ? 0 : current == ReservationStep.payment ? 1 : 2;
    return Row(children: steps.asMap().entries.map((e) {
      final i = e.key;
      final active = i == currentIdx;
      final done = i < currentIdx;
      // Lingkaran 24px (TSX): aktif = terracotta penuh; selesai = tint 10% + centang
      // terracotta; berikutnya = surfaceAlt + border + nomor muted.
      final Color fill = active
          ? AppColors.primary
          : (done ? AppColors.primary.withValues(alpha: 0.1) : AppColors.surfaceAlt);
      return Expanded(child: Row(children: [
        if (i > 0) Expanded(child: Container(height: 2, color: done ? AppColors.primary : AppColors.border)),
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: fill,
            shape: BoxShape.circle,
            border: Border.all(color: active || done ? AppColors.primary : AppColors.border),
          ),
          child: Center(
            child: done
                ? const Icon(Icons.check, size: 12, color: AppColors.primary)
                : Text(
                    '${i + 1}',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: active ? AppColors.onPrimary : AppColors.muted,
                    ),
                  ),
          ),
        ),
        if (i < 2) Expanded(child: Container(height: 2, color: i < currentIdx ? AppColors.primary : AppColors.border)),
      ]));
    }).toList());
  }
}
