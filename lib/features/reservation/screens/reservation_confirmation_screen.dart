import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/utils/order_status_helper.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/secondary_button.dart';
import '../../../data/models/order_model.dart';
import '../../../features/account/providers/orders_provider.dart';
import '../../../shared/app_scaffold.dart';
import '../widgets/pickup_location_card.dart';
import '../widgets/qr_ticket_card.dart';
import '../widgets/ticket_status_banner.dart';

/// Halaman "Tiket Pembelian" (sesuai Figma) dengan dua status:
/// 1. [TicketStatus.scan]     : order belum diambil -> suruh scan QR di kasir.
/// 2. [TicketStatus.accepted] : kasir sudah scan (order selesai) -> "Reservasi Diterima".
class ReservationConfirmationScreen extends StatefulWidget {
  final String? orderNumber;

  const ReservationConfirmationScreen({super.key, this.orderNumber});

  @override
  State<ReservationConfirmationScreen> createState() => _ReservationConfirmationScreenState();
}

class _ReservationConfirmationScreenState extends State<ReservationConfirmationScreen> {
  Timer? _timer;

  OrderModel? _findOrder(OrdersProvider orders) {
    for (final o in orders.orders) {
      if (o.orderNumber == widget.orderNumber) return o;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
    // Cek status tiap 3 detik sampai kasir selesai scan.
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _refresh());
  }

  Future<void> _refresh() async {
    if (!mounted) return;
    final orders = context.read<OrdersProvider>();
    var o = _findOrder(orders);
    if (o == null) {
      await orders.fetchOrders();
      if (!mounted) return;
      o = _findOrder(orders);
    } else if (o.status != OrderStatus.selesai) {
      await orders.getOrderDetail(o.id);
    }
    if (!mounted) return;
    final latest = _findOrder(orders);
    if (latest != null && latest.status == OrderStatus.selesai) _timer?.cancel();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final code = widget.orderNumber;
    if (code == null || code.isEmpty) {
      return const AppScaffold(
        title: 'Tiket Pembelian',
        showBottomNav: false,
        body: Center(child: Text('Tiket tidak ditemukan.')),
      );
    }

    final orders = context.watch<OrdersProvider>();
    final order = _findOrder(orders);
    final accepted = order != null && effectiveStatus(order) == OrderStatus.selesai;

    return AppScaffold(
      title: 'Tiket Pembelian',
      showBottomNav: false,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          children: [
            TicketStatusBanner(status: accepted ? TicketStatus.accepted : TicketStatus.scan),
            const SizedBox(height: 16),
            QrTicketCard(code: code),
            const SizedBox(height: 16),
            const PickupLocationCard(),
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'Selesai',
              icon: const Icon(Icons.home_outlined, size: 16),
              onPressed: () => context.go('/'),
            ),
            const SizedBox(height: 8),
            SecondaryButton(
              label: 'Lihat Katalog Lain',
              icon: const Icon(Icons.shopping_bag_outlined, size: 16),
              onPressed: () => context.go('/katalog'),
            ),
          ],
        ),
      ),
    );
  }
}
