import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/secondary_button.dart';
import '../../../shared/app_scaffold.dart';
import '../widgets/qr_ticket_card.dart';

class ReservationConfirmationScreen extends StatelessWidget {
  const ReservationConfirmationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final code = 'SDK-${DateTime.now().millisecondsSinceEpoch % 10000 + 1000}';
    return AppScaffold(
      title: 'Tiket Reservasi',
      body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(children: [
        Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: AppColors.moss.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
          child: Column(children: [
            const Icon(Icons.check_circle, size: 56, color: AppColors.moss),
            const SizedBox(height: 12),
            Text('Reservasi Diterima', style: AppTextStyles.eyebrow),
            Text('Tunjukkan kode ini ke kasir saat pengambilan.', style: AppTextStyles.bodyMuted, textAlign: TextAlign.center),
          ])),
        const SizedBox(height: 16),
        QrTicketCard(code: code),
        const SizedBox(height: 16),
        Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Lokasi Pengambilan', style: AppTextStyles.h3),
          const SizedBox(height: 8),
          const Row(children: [Icon(Icons.location_on, size: 16, color: AppColors.primary), SizedBox(width: 8), Expanded(child: Text('Jl. Jenderal Basuki Rahmat No. 45, Kawasan Kayutangan Heritage, Kota Malang'))]),
          const SizedBox(height: 8),
          const Row(children: [Icon(Icons.access_time, size: 16, color: AppColors.primary), SizedBox(width: 8), Text('Buka Senin–Sabtu, 10.00–21.00 WIB')]),
        ]))),
        const SizedBox(height: 24),
        PrimaryButton(label: 'Selesai', icon: const Icon(Icons.home, size: 16), onPressed: () => context.go('/')),
        const SizedBox(height: 8),
        SecondaryButton(label: 'Lihat Katalog Lain', icon: const Icon(Icons.shopping_bag, size: 16), onPressed: () => context.go('/katalog')),
      ])),
    );
  }
}
