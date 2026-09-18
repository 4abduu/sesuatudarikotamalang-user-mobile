import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class QrTicketCard extends StatelessWidget {
  final String code;
  const QrTicketCard({super.key, required this.code});

  @override
  Widget build(BuildContext context) {
    return Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.qr_code, size: 16, color: AppColors.primary), const SizedBox(width: 4), Text('SCAN DI KASIR', style: AppTextStyles.eyebrow)]),
      const SizedBox(height: 12),
      Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.primary, width: 2)),
        child: QrImageView(data: code, size: 160, backgroundColor: Colors.white)),
      const SizedBox(height: 12),
      Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: AppColors.surfaceAlt, borderRadius: BorderRadius.circular(999)), child: Text(code, style: AppTextStyles.h2.copyWith(letterSpacing: 2))),
    ])));
  }
}
