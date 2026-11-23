import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Dua status tiket pickup:
/// [scan]     -> tiket belum di-scan kasir (menyuruh user tunjukkan QR untuk di-scan).
/// [accepted] -> kasir sudah scan, reservasi diterima.
enum TicketStatus { scan, accepted }

class TicketStatusBanner extends StatelessWidget {
  final TicketStatus status;
  const TicketStatusBanner({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final accepted = status == TicketStatus.accepted;
    final color = accepted ? AppColors.moss : AppColors.mustard;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 3),
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: Icon(
                accepted ? Icons.check : Icons.qr_code_scanner,
                key: ValueKey<bool>(accepted),
                size: accepted ? 36 : 30,
                color: color,
              ),
            ),
          ),
          const SizedBox(height: 12),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: Text(
              accepted ? 'PICKUP DIKONFIRMASI' : 'SCAN TIKET DI KASIR',
              key: ValueKey<String>(accepted ? 'accepted_title' : 'scan_title'),
              style: AppTextStyles.eyebrow.copyWith(
                color: AppColors.primary,
                letterSpacing: 1.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: Text(
              accepted
                  ? 'Tunjukkan kode ini ke kasir saat pengambilan.'
                  : 'Tunjukkan QR di bawah ini ke kasir agar tiketmu di-scan.',
              key: ValueKey<String>(accepted ? 'accepted_body' : 'scan_body'),
              style: AppTextStyles.bodyMuted,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
