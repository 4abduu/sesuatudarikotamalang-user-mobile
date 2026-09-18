import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/order_status_helper.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../features/account/providers/orders_provider.dart';
import '../../../data/models/order_model.dart';
import '../../../features/reservation/widgets/qr_ticket_card.dart';
import '../../../shared/app_scaffold.dart';

class OrderDetailScreen extends StatelessWidget {
  final String orderId;
  const OrderDetailScreen({super.key, required this.orderId});
  @override
  Widget build(BuildContext context) {
    final orders = context.watch<OrdersProvider>();
    final o = orders.orders.firstWhere((o) => o.id == orderId, orElse: () => orders.orders.first);
    final status = effectiveStatus(o);
    final isCompleted = status == OrderStatus.selesai;
    return AppScaffold(
      title: o.orderNumber,
      leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
      body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(children: [
        QrTicketCard(code: o.orderNumber),
        const SizedBox(height: 16),
        Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Detail Pesanan', style: AppTextStyles.h3),
          const SizedBox(height: 12),
          _Row(label: 'Produk', value: o.productName),
          _Row(label: 'Varian', value: o.variantLabel),
          _Row(label: 'Tanggal Ambil', value: formatDateID(o.pickupDate)),
          _Row(label: 'Waktu', value: o.pickupSlot),
          _Row(label: 'Pembayaran', value: '${o.paymentMethod} (${status.label})'),
          _Row(label: 'Total', value: formatRupiah(o.total)),
          if (status == OrderStatus.lewatBatas) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF9B3320).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Toko tidak lagi menjamin penyimpanan barang ini. Hubungi toko untuk konfirmasi.',
                style: TextStyle(fontSize: 12, color: Color(0xFF9B3320)),
              ),
            ),
          ],
        ]))),
        const SizedBox(height: 16),
        if (isCompleted && !o.reviewed) ...[
          PrimaryButton(label: 'Beri Ulasan', icon: const Icon(Icons.star, size: 16), onPressed: () => context.push('/akun/ulasan/write?order=$orderId')),
        ] else if (isCompleted && o.reviewed) ...[
          const Text('Sudah diulas', style: TextStyle(fontSize: 13, color: Color(0xFF6B7A3D))),
        ],
      ])),
    );
  }
}

class _Row extends StatelessWidget {
  final String label, value;
  const _Row({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.only(bottom: 6), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [SizedBox(width: 100, child: Text(label, style: AppTextStyles.caption)), Expanded(child: Text(value, style: AppTextStyles.body))]));
  }
}
