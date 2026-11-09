import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_formatter.dart';

/// Banner untuk detail pesanan yang jadwal pickup-nya jatuh di hari toko libur.
/// Tampilkan hanya bila `order.affectedByHoliday == true`.
class HolidayAffectedBanner extends StatelessWidget {
  /// Alasan libur dari `order.holidayInfo.reason` (boleh kosong).
  final String? reason;

  /// Tanggal pickup pesanan (`order.pickupDate`, string ISO).
  final String pickupDate;

  const HolidayAffectedBanner({super.key, required this.reason, required this.pickupDate});

  @override
  Widget build(BuildContext context) {
    final cleanReason = (reason ?? '').trim();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.destructive.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.destructive.withValues(alpha: 0.3)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(Icons.event_busy, color: AppColors.destructive, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Toko libur di tanggal pickup-mu', style: AppTextStyles.title),
            const SizedBox(height: 4),
            Text(
              'Toko libur pada ${formatDateID(pickupDate)}'
              '${cleanReason.isEmpty ? '' : ' ($cleanReason)'}. '
              'Pesananmu tetap aman dan bisa diambil kapan saja saat toko buka. '
              'Admin akan menghubungimu lewat WhatsApp. Kalau ingin membatalkan, hubungi admin toko.',
              style: AppTextStyles.caption.copyWith(color: AppColors.foreground),
            ),
          ]),
        ),
      ]),
    );
  }
}

