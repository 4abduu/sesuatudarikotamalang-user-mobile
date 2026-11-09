import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/pickup_holidays_model.dart';

/// Pop-up (bottom sheet) berisi alasan toko libur, muncul saat tanggal merah diketuk.
Future<void> showHolidayReasonSheet(
  BuildContext context, {
  required DateTime date,
  required HolidayInfo info,
}) {
  final dateText = DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(date);
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.destructive.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.event_busy, color: AppColors.destructive, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text('Toko libur', style: AppTextStyles.h3)),
            ]),
            const SizedBox(height: 16),
            Text(dateText, style: AppTextStyles.label),
            const SizedBox(height: 6),
            Text(info.reason, style: AppTextStyles.body),
            const SizedBox(height: 12),
            Text(
              'Pengambilan tidak bisa dijadwalkan di tanggal ini. Silakan pilih tanggal lain.',
              style: AppTextStyles.caption,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Mengerti'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

