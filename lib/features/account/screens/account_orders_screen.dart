import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/order_status_helper.dart';
import '../../../data/models/order_model.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/account/providers/orders_provider.dart';
import '../../../shared/app_scaffold.dart';

class AccountOrdersScreen extends StatelessWidget {
  const AccountOrdersScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final orders = context.watch<OrdersProvider>();
    if (!auth.isAuthenticated) {
      return AppScaffold(title: 'Akun', body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.person_outline, size: 48, color: AppColors.muted),
        const SizedBox(height: 12),
        Text('Masuk untuk lihat akunmu', style: AppTextStyles.h3),
        const SizedBox(height: 16),
        ElevatedButton(onPressed: () => context.push('/login'), child: const Text('Masuk')),
      ])));
    }
    final mine = orders.ordersForUser(auth.user!.id);
    return AppScaffold(
      title: 'Riwayat Pesanan',
      body: mine.isEmpty
        ? const EmptyState(icon: Icons.receipt_long, title: 'Belum ada pesanan', description: 'Yuk jelajahi katalog dan mulai belanja.')
        : ListView.builder(padding: const EdgeInsets.all(16), itemCount: mine.length, itemBuilder: (_, i) {
            final o = mine[i];
            final status = effectiveStatus(o);
            return GestureDetector(onTap: () => context.push('/akun/pesanan/${o.id}'), child: Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(o.orderNumber, style: AppTextStyles.h3),
                _StatusBadge(status: status),
              ]),
              const SizedBox(height: 4),
              Text(o.productName, style: AppTextStyles.body),
              Text(o.variantLabel, style: GoogleFonts.poppins(fontSize: 12, color: AppColors.muted)),
              const SizedBox(height: 4),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('${formatDateShort(o.pickupDate)} · ${o.pickupSlot}', style: AppTextStyles.caption),
                Text(formatRupiah(o.total), style: AppTextStyles.price),
              ]),
            ]))));
          }),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final OrderStatus status;
  const _StatusBadge({required this.status});
  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (status) {
      OrderStatus.menungguBayar => (AppColors.mustard.withValues(alpha: 0.15), const Color(0xFF8A6A1A)),
      OrderStatus.lunas => (AppColors.moss.withValues(alpha: 0.15), AppColors.moss),
      OrderStatus.selesai => (AppColors.primary.withValues(alpha: 0.15), AppColors.primary),
      OrderStatus.dibatalkan => (AppColors.muted.withValues(alpha: 0.15), AppColors.muted),
      OrderStatus.kedaluwarsa => (AppColors.destructive.withValues(alpha: 0.15), AppColors.destructive),
      OrderStatus.lewatBatas => (AppColors.destructive.withValues(alpha: 0.15), AppColors.destructive),
    };
    return Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)), child: Text(status.label, style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: fg)));
  }
}
