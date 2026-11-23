import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/routing/back_navigation.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../data/models/pickup_slot.dart';
import '../../../data/repositories/order_repository.dart';
import '../../../data/repositories/slot_repository.dart';
import '../../../features/cart/viewmodel/cart_view_model.dart';
import 'widgets/pickup_calendar.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../auth/viewmodel/auth_view_model.dart';
import '../../auth/view/widgets/auth_gate_bottom_sheet.dart';
import '../../../shared/app_scaffold.dart';
import '../viewmodel/reservation_flow_view_model.dart';
import '../viewmodel/pickup_calendar_view_model.dart';
import 'widgets/step_indicator.dart';
import 'widgets/date_time_picker_step.dart';
import 'widgets/payment_method_step.dart';
import 'widgets/hold_countdown_widget.dart';
import 'midtrans_webview_screen.dart';


class ReservationFlowScreen extends StatefulWidget {
  final String productId;
  const ReservationFlowScreen({super.key, required this.productId});

  @override
  State<ReservationFlowScreen> createState() => _ReservationFlowScreenState();
}

/// Mode checkout yang sama dengan flow pickup langsung, tetapi sumber itemnya
/// dapat berasal dari beberapa baris keranjang.
class CartCheckoutScreen extends StatefulWidget {
  const CartCheckoutScreen({super.key, required this.orders, required this.slots});
  final OrderRepository orders;
  final SlotRepository slots;

  @override
  State<CartCheckoutScreen> createState() => _CartCheckoutScreenState();
}

class _CartCheckoutScreenState extends State<CartCheckoutScreen> {
  int step = 0;
  late final PickupCalendarViewModel calendarViewModel;
  DateTime date = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
  String? slot;
  String? payment;
  bool loading = false;
  String? error;
  List<PickupSlot> pickupSlots = const [];
  int leadMinutes = 30;

  DateTime get firstDate => DateTime.now();
  DateTime get lastDate => DateTime.now().add(const Duration(days: 14));

  @override
  void initState() {
    super.initState();
    calendarViewModel = PickupCalendarViewModel(widget.slots);
    Future.microtask(loadSlots);
  }

  @override
  void dispose() {
    calendarViewModel.dispose();
    super.dispose();
  }

  Future<void> loadSlots() async {
    try {
      final result = await widget.slots.getSlots(date);
      if (!mounted) return;
      setState(() {
        pickupSlots = result.slots;
        leadMinutes = result.leadMinutes;
        slot = null;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => error = e.message);
    }
  }

  Future<void> submit() async {
    final cart = context.read<CartViewModel>();
    final ids = GoRouterState.of(context).uri.queryParametersAll['item'] ?? [];
    final selected = cart.items.where((item) => ids.contains(item.id)).toList();
    if (slot == null || payment == null || selected.isEmpty || selected.any((item) => item.status != 'ok')) return;
    setState(() { loading = true; error = null; });
    try {
      final order = await widget.orders.createMany(
        items: selected.map((item) => {'productId': item.productId, 'variantId': item.variantId, 'quantity': item.quantity}).toList(),
        pickupDate: date,
        pickupSlot: slot!,
        paymentMethod: payment!,
        source: 'cart',
      );
      final redirectUrl = order.snap?['redirect_url'] as String?;
      if (payment == 'midtrans' && redirectUrl != null && redirectUrl.isNotEmpty && mounted) {
        await Navigator.of(context).push(MaterialPageRoute(builder: (_) => MidtransWebViewScreen(url: redirectUrl, orderId: order.id)));
      }
      await cart.refresh();
      if (mounted) context.go('/reservasi/konfirmasi?orderNumber=${Uri.encodeComponent(order.orderNumber)}');
    } on ApiException catch (e) {
      if (mounted) setState(() => error = e.message);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartViewModel>();
    final ids = GoRouterState.of(context).uri.queryParametersAll['item'] ?? [];
    final selected = cart.items.where((item) => ids.contains(item.id)).toList();
    final canContinue = !loading && slot != null && selected.isNotEmpty && selected.every((item) => item.status == 'ok');
    final canSubmit = !loading && payment != null && canContinue;
    return AppScaffold(
      title: 'Pembelian Pickup',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          Padding(padding: const EdgeInsets.symmetric(vertical: 16), child: StepIndicator(current: step == 0 ? ReservationStep.schedule : ReservationStep.payment)),
          Text('${selected.length} item pesanan', style: AppTextStyles.h3),
          const SizedBox(height: 12),
          ...selected.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Card(child: Padding(padding: const EdgeInsets.all(12), child: Row(children: [
              ClipRRect(borderRadius: BorderRadius.circular(12), child: SizedBox(width: 56, height: 56, child: item.image == null ? const Icon(Icons.image_outlined, color: AppColors.muted) : Image.network(item.image!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_outlined, color: AppColors.muted)))),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(item.productName, style: AppTextStyles.h3),
                Text(item.variantLabel, style: AppTextStyles.caption),
                Text('Jumlah: ${item.quantity} unit', style: AppTextStyles.caption),
                const SizedBox(height: 4),
                Text(formatRupiah(item.unitPrice * item.quantity), style: AppTextStyles.price),
              ])),
            ]))),
          )),
          if (step == 0) ...[
            const SizedBox(height: 8),
            Text('Pilih Tanggal Ambil', style: AppTextStyles.h3),
            const SizedBox(height: 4),
            Text('Pilih tanggal pickup yang tersedia sampai 14 hari ke depan. Hari libur toko ditandai merah dan tidak dapat dipilih.', style: AppTextStyles.caption),
            const SizedBox(height: 8),
            PickupCalendar(viewModel: calendarViewModel, initialDate: date, firstDate: firstDate, lastDate: lastDate, onDateChanged: (value) async { setState(() => date = value); await loadSlots(); }),
            const SizedBox(height: 16),
            Text('Pilih Waktu Ambil', style: AppTextStyles.h3),
            const SizedBox(height: 8),
            _CartSlotChoices(slots: pickupSlots, selected: slot, onSelected: (value) => setState(() => slot = value)),
            if (leadMinutes > 0) ...[const SizedBox(height: 8), Text('Pemesanan slot ditutup $leadMinutes menit sebelum jam pickup.', style: AppTextStyles.caption)],
            if (error != null) ...[const SizedBox(height: 8), Text(error!, style: const TextStyle(color: AppColors.destructive))],
            const SizedBox(height: 20),
            ElevatedButton(onPressed: canContinue ? () => setState(() { step = 1; error = null; }) : null, child: const Text('Lanjut ke Pembayaran')),
          ] else ...[
            Row(children: [IconButton(onPressed: loading ? null : () => setState(() => step = 0), icon: const Icon(Icons.arrow_back)), Text('Pilih Pembayaran', style: AppTextStyles.h3)]),
            const SizedBox(height: 8),
            Text('Pickup: ${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} · ${slot ?? '-'}', style: AppTextStyles.caption),
            const SizedBox(height: 12),
            _CartPaymentOption(value: 'cod', title: 'Bayar di Toko (Cash/QRIS)', description: 'Bayar tunai/QRIS saat ambil. Stok di-hold 2 jam.', icon: Icons.storefront_outlined, selected: payment, onTap: () => setState(() => payment = 'cod')),
            const SizedBox(height: 8),
            _CartPaymentOption(value: 'midtrans', title: 'Bayar Online (Midtrans)', description: 'Bayar sekarang. Stok dikurangi permanen & pesanan langsung lunas.', icon: Icons.credit_card_outlined, selected: payment, onTap: () => setState(() => payment = 'midtrans')),
            if (error != null) ...[const SizedBox(height: 8), Text(error!, style: const TextStyle(color: AppColors.destructive))],
            const SizedBox(height: 20),
            ElevatedButton(onPressed: canSubmit ? submit : null, child: Text(loading ? 'Memproses...' : 'Pesan Sekarang')),
          ],
        ],
      ),
    );
  }
}

class _CartPaymentOption extends StatelessWidget {
  const _CartPaymentOption({required this.value, required this.title, required this.description, required this.icon, required this.selected, required this.onTap});
  final String value, title, description;
  final IconData icon;
  final String? selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final active = value == selected;
    return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(16), child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: active ? AppColors.primary : AppColors.border, width: active ? 2 : 1), boxShadow: AppShadows.soft), child: Row(children: [Container(width: 40, height: 40, decoration: BoxDecoration(color: active ? AppColors.primary.withValues(alpha: 0.1) : AppColors.surfaceAlt, borderRadius: BorderRadius.circular(10)), child: Icon(icon, size: 20, color: active ? AppColors.primary : AppColors.muted)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: AppTextStyles.label), Text(description, style: AppTextStyles.caption)])), Icon(active ? Icons.check_circle : Icons.circle_outlined, color: active ? AppColors.primary : AppColors.muted)])));
  }
}

class _CartSlotChoices extends StatelessWidget {
  const _CartSlotChoices({required this.slots, required this.selected, required this.onSelected});
  final List<PickupSlot> slots;
  final String? selected;
  final ValueChanged<String> onSelected;
  @override
  Widget build(BuildContext context) {
    if (slots.isEmpty) return Text('Tidak ada slot pickup yang tersedia untuk tanggal ini.', style: AppTextStyles.caption);
    return LayoutBuilder(builder: (context, constraints) {
      final itemWidth = (constraints.maxWidth - 8) / 2;
      return Wrap(spacing: 8, runSpacing: 8, children: slots.map((item) {
        final active = selected == item.time;
        final enabled = item.bookable;
        return GestureDetector(
          onTap: enabled ? () => onSelected(item.time) : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: itemWidth,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: active ? AppColors.primary : AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: active ? AppColors.primary : AppColors.border),
            ),
            child: Text(
              item.time,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: active ? AppColors.onPrimary : (enabled ? AppColors.foreground : AppColors.muted),
              ),
            ),
          ),
        );
      }).toList());
    });
  }
}

class _ReservationFlowScreenState extends State<ReservationFlowScreen> {
  // Produk & provider alur dibuat SEKALI lalu dipegang. Dengan begitu, perubahan stok / daftar
  // produk setelah pembayaran tidak membuat layar mencari ulang produk (dan jatuh ke
  // "Produk tidak ditemukan") ataupun membuang state alur.
  ReservationFlowViewModel? _flow;
  bool _loading = true;
  bool _gateShown = false;
  bool _ownProduct = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  Future<void> _init() async {
    if (!mounted) return;
    final auth = context.read<AuthViewModel>();
    if (!auth.isAuthenticated) {
      if (_gateShown) return;
      _gateShown = true;
      showAuthGateSheet(context, next: '/reservasi/${widget.productId}', contextLabel: 'pembelian pickup');
      context.popOrParent();
      return;
    }
    final flow = context.read<ReservationFlowViewModel>();
    await flow.load();
    if (!mounted) return;
    setState(() {
      _ownProduct = flow.isOwnProduct;
      _flow = flow.hasProduct && !flow.isOwnProduct ? flow : null;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: LoadingIndicator(label: 'Memuat data produk...'));
    }
    final flow = _flow;
    if (_ownProduct) {
      return Scaffold(
        appBar: AppBar(title: const Text('Pembelian Pickup')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.storefront_outlined, size: 48),
                const SizedBox(height: 16),
                Text('Produk milikmu tidak dapat dipesan', style: AppTextStyles.h3, textAlign: TextAlign.center),
                const SizedBox(height: 8),
                const Text('Gunakan akun pembeli lain untuk menguji pemesanan produk ini.', textAlign: TextAlign.center),
                const SizedBox(height: 20),
                PrimaryButton(label: 'Kembali', onPressed: () => context.popOrParent()),
              ],
            ),
          ),
        ),
      );
    }
    if (flow == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Pembelian')),
        body: const Center(child: Text('Produk tidak ditemukan')),
      );
    }
    return ChangeNotifierProvider<ReservationFlowViewModel>.value(
      value: flow,
      child: const _ReservationBody(),
    );
  }
}

class _ReservationBody extends StatelessWidget {
  const _ReservationBody();
  @override
  Widget build(BuildContext context) {
    final p = context.watch<ReservationFlowViewModel>();
    return AppScaffold(
      title: 'Pembelian Pickup',
      leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.popOrParent()),
      body: Column(children: [
        Padding(padding: const EdgeInsets.all(16), child: StepIndicator(current: p.step)),
        Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Product summary (hanya tampil di langkah jadwal dan pembayaran, tidak di langkah hasil)
          if (p.step != ReservationStep.result) ...[
            Card(child: Padding(padding: const EdgeInsets.all(12), child: Row(children: [
              Container(
                width: 56,
                height: 56,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryLight]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: p.product.images.isNotEmpty
                    ? Image.network(
                        p.product.images.first,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.brush, color: AppColors.onPrimary),
                      )
                    : const Icon(Icons.brush, color: AppColors.onPrimary),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(p.product.name, style: AppTextStyles.h3),
                Text(p.variantProvider.variantLabel, style: AppTextStyles.caption),
                Text('Jumlah: ${p.initialQuantity} unit', style: AppTextStyles.caption),
                const SizedBox(height: 4),
                Text(formatRupiah(p.product.price * p.initialQuantity), style: AppTextStyles.price),
              ])),
            ]))),
            const SizedBox(height: 16),
          ],
          if (p.step == ReservationStep.schedule) ...[
            DateTimePickerStep(provider: p),
            const SizedBox(height: 24),
            PrimaryButton(
              label: p.needsVariantSelection
                  ? 'Pilih varian dulu'
                  : (p.selectedVariantOutOfStock ? 'Stok varian ini kosong' : 'Lanjut ke Pembayaran'),
              icon: const Icon(Icons.arrow_forward, size: 16),
              onPressed: p.canContinue ? () => p.nextStep() : null,
            ),
          ] else if (p.step == ReservationStep.payment) ...[
            PaymentMethodStep(provider: p),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(child: OutlinedButton(onPressed: p.processing ? null : () => p.prevStep(), child: const Text('Kembali'))),
              const SizedBox(width: 8),
              Expanded(child: ElevatedButton(
                onPressed: (p.paymentMethod == null || p.processing) ? null : () async {
                  final result = await p.submit();
                  if (!context.mounted) return;
                  if (result == ReservationSubmitResult.failed || result == ReservationSubmitResult.slotRejected) {
                    if (p.actionError != null) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(p.actionError!)));
                    }
                    return;
                  }
                  final created = p.createdOrder!;
                  final redirectUrl = created.snap?['redirect_url'] as String?;
                  if (result == ReservationSubmitResult.midtrans && redirectUrl != null && redirectUrl.isNotEmpty) {
                    await Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => MidtransWebViewScreen(url: redirectUrl, orderId: created.id),
                    ));
                    // Cek status pembayaran terbaru setelah keluar dari WebView Midtrans
                    final updated = await p.checkOrderPaid(created.id);
                    if (updated && context.mounted) {
                      p.setPaid();
                    }
                  }
                  // Pindah ke langkah hasil konfirmasi (ResultSection)
                  p.nextStep();
                },
                child: p.processing
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Pesan Sekarang'),
              )),
            ]),
          ] else ...[
            _ResultSection(provider: p),
          ],
        ]))),
      ]),
    );
  }
}

class _ResultSection extends StatelessWidget {
  final ReservationFlowViewModel provider;
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
        PrimaryButton(
              label: 'Lihat Tiket Pickup',
          icon: const Icon(Icons.qr_code, size: 16),
          onPressed: () {
            if (provider.createdOrder != null) {
              context.push('/akun/pesanan/${provider.createdOrder!.id}');
            } else {
              context.go('/reservasi/konfirmasi');
            }
          },
        ),
      ]);
    } else {
      // COD: batas hold berasal dari backend (holdExpiresAt), bukan angka tetap di aplikasi.
      final holdRaw = provider.createdOrder?.holdExpiresAt;
      final holdExpiry = holdRaw != null ? DateTime.tryParse(holdRaw)?.toLocal() : null;
      return Column(children: [
        const Icon(Icons.hourglass_top, size: 48, color: AppColors.mustard),
        const SizedBox(height: 12),
        Text('Stok ditahan untukmu', style: AppTextStyles.h1),
        const SizedBox(height: 8),
        Text(
          holdExpiry != null
              ? 'Datang ke toko dan selesaikan pembayaran sebelum ${formatDateTimeWib(holdRaw ?? '')}.'
              : 'Datang ke toko dan selesaikan pembayaran sebelum batas waktu penahanan stok. Lihat batasnya di detail pesanan.',
          style: AppTextStyles.bodyMuted,
          textAlign: TextAlign.center,
        ),
        if (holdExpiry != null) ...[
          const SizedBox(height: 16),
          HoldCountdownWidget(expiresAt: holdExpiry),
        ],
        const SizedBox(height: 24),
        PrimaryButton(
              label: 'Lihat Tiket Pickup',
          icon: const Icon(Icons.qr_code, size: 16),
          onPressed: () {
            if (provider.createdOrder != null) {
              context.push('/akun/pesanan/${provider.createdOrder!.id}');
            } else {
              context.go('/reservasi/konfirmasi');
            }
          },
        ),
      ]);
    }
  }
}
