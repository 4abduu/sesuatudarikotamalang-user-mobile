import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/order_status_helper.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/auth/widgets/auth_gate_bottom_sheet.dart';
import '../../../features/account/providers/orders_provider.dart';
import '../../../data/models/order_model.dart';
import '../../../shared/app_scaffold.dart';
import '../providers/reservation_flow_provider.dart';
import '../widgets/step_indicator.dart';
import '../widgets/date_time_picker_step.dart';
import '../widgets/payment_method_step.dart';
import '../widgets/midtrans_mock_sheet.dart';
import '../widgets/hold_countdown_widget.dart';

class ReservationFlowScreen extends StatelessWidget {
  final String productId;
  const ReservationFlowScreen({super.key, required this.productId});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showAuthGateSheet(context, next: '/reservasi/$productId', contextLabel: 'reservasi pickup');
        context.pop();
      });
      return const Scaffold(body: LoadingIndicator(label: 'Memeriksa sesi...'));
    }
    return ChangeNotifierProvider(
      create: (_) => ReservationFlowProvider(productId),
      child: const _ReservationBody(),
    );
  }
}

class _ReservationBody extends StatelessWidget {
  const _ReservationBody();
  @override
  Widget build(BuildContext context) {
    final p = context.watch<ReservationFlowProvider>();
    final auth = context.read<AuthProvider>();
    final orders = context.read<OrdersProvider>();
    return AppScaffold(
      title: 'Reservasi Pickup',
      leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
      body: Column(children: [
        Padding(padding: const EdgeInsets.all(16), child: StepIndicator(current: p.step)),
        Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Product summary
          Card(child: Padding(padding: const EdgeInsets.all(12), child: Row(children: [
            Container(width: 56, height: 56, decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryLight]), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.brush, color: AppColors.onPrimary)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p.product.name, style: AppTextStyles.h3),
              Text(p.variantProvider.variantLabel, style: AppTextStyles.caption),
              const SizedBox(height: 4),
              Text(formatRupiah(p.product.price), style: AppTextStyles.price),
            ])),
          ]))),
          const SizedBox(height: 16),
          if (p.step == ReservationStep.schedule) ...[
            DateTimePickerStep(provider: p),
            const SizedBox(height: 24),
            PrimaryButton(label: 'Lanjut ke Pembayaran', icon: const Icon(Icons.arrow_forward, size: 16), onPressed: p.canContinue ? () => p.nextStep() : null),
          ] else if (p.step == ReservationStep.payment) ...[
            PaymentMethodStep(provider: p),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(child: OutlinedButton(onPressed: () => p.prevStep(), child: const Text('Kembali'))),
              const SizedBox(width: 8),
              Expanded(child: ElevatedButton(
                onPressed: p.paymentMethod == null ? null : () {
                  // Check-at-submit — pass user's orders so effective stock
                  // (original minus reserved) is validated, not just raw.
                  final err = p.checkAtSubmit(orders: orders.orders);
                  if (err != null) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
                    if (err.contains('habis')) p.restart();
                    return;
                  }
                  p.nextStep();
                  if (p.paymentMethod == PaymentMethod.midtrans) {
                    showModalBottomSheet(context: context, isScrollControlled: true, builder: (_) => MidtransMockSheet(amount: p.product.price, onPaid: () {
                      Navigator.pop(context);
                      p.setPaid();
                      _createOrder(context, p, auth, orders, PaymentMethod.midtrans);
                    }));
                  } else {
                    // COD: create order with hold
                    _createOrder(context, p, auth, orders, PaymentMethod.cod);
                  }
                },
                child: const Text('Pesan Sekarang'),
              )),
            ]),
          ] else ...[
            _ResultSection(provider: p),
          ],
        ]))),
      ]),
    );
  }

  void _createOrder(BuildContext context, ReservationFlowProvider p, AuthProvider auth, OrdersProvider orders, PaymentMethod method) {
    final order = OrderModel(
      id: 'uo-${DateTime.now().millisecondsSinceEpoch}',
      orderNumber: orders.makeOrderNumber(),
      userId: auth.user!.id,
      productId: p.product.id,
      productName: p.product.name,
      variantLabel: p.variantProvider.variantLabel,
      pickupDate: p.selectedDate!.toIso8601String().substring(0, 10),
      pickupSlot: p.selectedSlot!,
      paymentMethod: method == PaymentMethod.midtrans ? 'Midtrans' : 'Cash/QRIS',
      status: method == PaymentMethod.midtrans ? OrderStatus.lunas : OrderStatus.menungguBayar,
      total: p.product.price,
      createdAt: DateTime.now().toIso8601String().substring(0, 10),
      pickupDeadline: method == PaymentMethod.midtrans ? computePickupDeadline(p.selectedDate!.toIso8601String(), defaultPickupDeadlineDays) : null,
      holdExpiresAt: method == PaymentMethod.cod ? DateTime.now().add(const Duration(hours: 2)).toIso8601String() : null,
      holdExtendedMinutes: 0,
    );
    orders.addOrder(order);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reservasi berhasil dibuat!')));
  }
}

class _ResultSection extends StatelessWidget {
  final ReservationFlowProvider provider;
  const _ResultSection({required this.provider});
  @override
  Widget build(BuildContext context) {
    if (provider.paymentMethod == PaymentMethod.midtrans) {
      if (!provider.paid) return const LoadingIndicator(label: 'Menunggu pembayaran...');
      return Column(children: [
        const Icon(Icons.check_circle, size: 64, color: AppColors.moss),
        const SizedBox(height: 12),
        Text('Pembayaran Berhasil', style: AppTextStyles.h1),
        const SizedBox(height: 8),
        Text('Stok kombinasi sudah di-hold & dikurangi permanen.', style: AppTextStyles.bodyMuted, textAlign: TextAlign.center),
        const SizedBox(height: 24),
        PrimaryButton(label: 'Lihat Tiket Reservasi', icon: const Icon(Icons.qr_code, size: 16), onPressed: () => context.go('/reservasi/konfirmasi')),
      ]);
    } else {
      // COD countdown
      final holdExpiry = DateTime.now().add(const Duration(hours: 2));
      return Column(children: [
        const Icon(Icons.hourglass_top, size: 48, color: AppColors.mustard),
        const SizedBox(height: 12),
        Text('Stok di-hold selama 2 jam', style: AppTextStyles.h1),
        const SizedBox(height: 8),
        Text('Harap datang sebelum waktu tersebut untuk mengambil barang.', style: AppTextStyles.bodyMuted, textAlign: TextAlign.center),
        const SizedBox(height: 16),
        HoldCountdownWidget(expiresAt: holdExpiry),
        const SizedBox(height: 24),
        PrimaryButton(label: 'Lihat Tiket Reservasi', icon: const Icon(Icons.qr_code, size: 16), onPressed: () => context.go('/reservasi/konfirmasi')),
      ]);
    }
  }
}
