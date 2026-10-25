import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_text_styles.dart';
import '../providers/reservation_flow_provider.dart';

class PaymentMethodStep extends StatelessWidget {
  final ReservationFlowProvider provider;
  const PaymentMethodStep({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Pilih Pembayaran', style: AppTextStyles.h3),
      const SizedBox(height: 12),
      _PaymentCard(title: 'Bayar Online (Midtrans)', desc: 'Bayar sekarang. Stok dikurangi permanen & pesanan langsung Lunas.', icon: Icons.credit_card_outlined, active: provider.paymentMethod == PaymentMethod.midtrans, onTap: () => provider.setPaymentMethod(PaymentMethod.midtrans)),
      const SizedBox(height: 8),
      _PaymentCard(title: 'Bayar di Toko (Cash/QRIS)', desc: 'Bayar tunai/QRIS saat ambil. Stok di-hold 2 jam.', icon: Icons.storefront_outlined, active: provider.paymentMethod == PaymentMethod.cod, onTap: () => provider.setPaymentMethod(PaymentMethod.cod)),
    ]);
  }
}

class _PaymentCard extends StatelessWidget {
  final String title, desc;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;
  const _PaymentCard({required this.title, required this.desc, required this.icon, required this.active, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: active ? AppColors.primary : AppColors.border, width: active ? 2 : 1),
          boxShadow: AppShadows.soft,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: active ? AppColors.primary.withValues(alpha: 0.1) : AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: active ? AppColors.primary : AppColors.muted),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.foreground)),
                  Text(desc, style: AppTextStyles.caption),
                ],
              ),
            ),
            Icon(active ? Icons.check_circle : Icons.circle_outlined, size: 20, color: active ? AppColors.primary : AppColors.muted),
          ],
        ),
      ),
    );
  }
}
