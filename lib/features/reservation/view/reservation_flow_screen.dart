import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/routing/back_navigation.dart';
import 'package:provider/provider.dart';
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

class _ReservationFlowScreenState extends State<ReservationFlowScreen> {
  // Produk & provider alur dibuat SEKALI lalu dipegang. Dengan begitu, perubahan stok / daftar
  // produk setelah pembayaran tidak membuat layar mencari ulang produk (dan jatuh ke
  // "Produk tidak ditemukan") ataupun membuang state alur.
  ReservationFlowViewModel? _flow;
  bool _loading = true;
  bool _gateShown = false;

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
      showAuthGateSheet(context, next: '/reservasi/${widget.productId}', contextLabel: 'reservasi pickup');
      context.popOrParent();
      return;
    }
    final flow = context.read<ReservationFlowViewModel>();
    await flow.load();
    if (!mounted) return;
    setState(() {
      _flow = flow.hasProduct ? flow : null;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: LoadingIndicator(label: 'Memuat data produk...'));
    }
    final flow = _flow;
    if (flow == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Reservasi')),
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
      title: 'Reservasi Pickup',
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
                const SizedBox(height: 4),
                Text(formatRupiah(p.product.price), style: AppTextStyles.price),
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
          label: 'Lihat Tiket Reservasi',
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
          label: 'Lihat Tiket Reservasi',
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
