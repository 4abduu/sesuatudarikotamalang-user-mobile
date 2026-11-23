import 'widgets/holiday_affected_banner.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/routing/back_navigation.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/order_status_helper.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/secondary_button.dart';
import '../viewmodel/order_detail_view_model.dart';
import '../../../data/models/order_model.dart';
import '../../reservation/view/widgets/qr_ticket_card.dart';
import '../../../shared/app_scaffold.dart';

import 'package:url_launcher/url_launcher.dart';
import '../../catalog/viewmodel/app_config_view_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../reservation/view/midtrans_webview_screen.dart';
import '../../reservation/view/widgets/hold_countdown_widget.dart';

class OrderDetailScreen extends StatefulWidget {
  final String orderId;
  const OrderDetailScreen({super.key, required this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  OrderDetailViewModel? _vm;
  bool _hasRedirectedOnComplete = false;

  @override
  void initState() {
    super.initState();
    _vm = context.read<OrderDetailViewModel>();
    _vm!.addListener(_onOrderChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _vm!.init();
    });
  }

  void _onOrderChanged() {
    final number = _vm?.completedOrderNumber;
    if (!mounted || number == null || _hasRedirectedOnComplete) return;
    _hasRedirectedOnComplete = true;
    context.go('/reservasi/konfirmasi?orderNumber=${Uri.encodeComponent(number)}');
  }

  @override
  void dispose() { _vm?.removeListener(_onOrderChanged); super.dispose(); }

  Future<void> _loadOrder() => context.read<OrderDetailViewModel>().load();

  Future<void> _handleCancel(OrderModel order) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Batalkan Pembelian Pickup'),
        content: const Text('Apakah Anda yakin ingin membatalkan pembelian pickup ini?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Tidak')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.destructive),
            child: const Text('Ya, Batalkan'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    final vm = context.read<OrderDetailViewModel>();
    final ok = await vm.cancel();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? 'Pesanan berhasil dibatalkan.' : vm.actionError ?? 'Gagal membatalkan')));
  }

  Future<void> _handlePayAgain(OrderModel order) async {
    final vm = context.read<OrderDetailViewModel>();
    final url = await vm.payAgain();
    if (!mounted) return;
    if (url == null) {
      if (vm.actionError != null) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(vm.actionError!)));
      return;
    }
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => MidtransWebViewScreen(url: url, orderId: order.id),
    ));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Memeriksa status pembayaran...')));
    final confirmed = await vm.checkPayment();
    if (mounted && confirmed) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pembayaran berhasil dikonfirmasi!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<OrderDetailViewModel>();
    final o = vm.order;
    if (o == null) {
      return AppScaffold(title: 'Detail Pesanan', showSearchAction: false, body: Center(
        child: vm.isLoading ? const CircularProgressIndicator() : const Text('Pesanan tidak ditemukan'),
      ));
    }
    final status = effectiveStatus(o);
    final isCompleted = status == OrderStatus.selesai;
    final isWaitingPayment = status == OrderStatus.menungguBayar;
    final isPaid = status == OrderStatus.lunas;

    // Sesuai Bagian 4 API_CONTRACT:
    // Tampilkan QR untuk order yang bisa diambil: lunas dan cod berstatus menunggu_bayar.
    final bool isCod = o.paymentMethod.toLowerCase().contains('cod') || o.paymentMethod.toLowerCase().contains('cash');
    final bool shouldShowQr = isPaid || (isWaitingPayment && isCod);

    return AppScaffold(
      title: o.orderNumber,
      showSearchAction: false,
      leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.popOrParent()),
      body: vm.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadOrder,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Column(
                  children: [
                    if (shouldShowQr) ...[
                      // Untuk pesanan yang bisa diambil (Lunas atau COD menunggu_bayar):
                      // Tampilkan countdown hold jika ada (misal COD hold 2 jam)
                      if (isWaitingPayment && o.holdExpiresAt != null) ...[
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: HoldCountdownWidget(
                            expiresAt: DateTime.tryParse(o.holdExpiresAt!)?.toLocal() ?? DateTime.now().add(const Duration(hours: 1)),
                          ),
                        ),
                      ],
                      QrTicketCard(code: o.orderNumber),
                      const SizedBox(height: 16),
                    ] else if (isWaitingPayment && o.paymentMethod.toLowerCase() == 'midtrans') ...[
                      // Untuk Midtrans menunggu bayar: cukup modal/card Menunggu Pembayaran ini saja
                      Card(
                        color: AppColors.mustard.withValues(alpha: 0.1),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              const Icon(Icons.payment, size: 48, color: AppColors.mustard),
                              const SizedBox(height: 8),
                              Text('Menunggu Pembayaran Online', style: AppTextStyles.h3),
                              const SizedBox(height: 4),
                              Text('Selesaikan pembayaran sebelum batas waktu berakhir.', style: AppTextStyles.caption, textAlign: TextAlign.center),
                              if (o.holdExpiresAt != null) ...[
                                const SizedBox(height: 12),
                                HoldCountdownWidget(
                                  expiresAt: DateTime.tryParse(o.holdExpiresAt!) ?? DateTime.now().add(const Duration(hours: 1)),
                                ),
                              ],
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.credit_card, size: 16),
                                  label: const Text('Bayar Sekarang'),
                                  onPressed: vm.isProcessingAction ? null : () => _handlePayAgain(o),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    if (o.affectedByHoliday) ...[
                      HolidayAffectedBanner(reason: o.holidayReason, pickupDate: o.pickupDate),
                      const SizedBox(height: 16),
                    ],
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.border),
                        boxShadow: AppShadows.soft,
                      ),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Detail Pesanan', style: AppTextStyles.h3),
                            const SizedBox(height: 12),
                            Text('Item Pesanan', style: AppTextStyles.caption),
                            ...o.items.map((item) => Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: item.image == null
                                      ? const SizedBox(width: 52, height: 52, child: Icon(Icons.image_outlined, color: AppColors.muted))
                                      : Image.network(
                                          item.image!,
                                          width: 52,
                                          height: 52,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => const SizedBox(width: 52, height: 52, child: Icon(Icons.broken_image_outlined, color: AppColors.muted)),
                                        ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(child: Text('${item.quantity} × ${item.productName} · ${item.variantLabel} · ${formatRupiah(item.price)}', style: AppTextStyles.body)),
                              ]),
                            )),
                            _Row(label: 'Jumlah unit', value: '${o.totalQuantity}'),
                            _Row(label: 'Tanggal Ambil', value: formatDateID(o.pickupDate)),
                            _Row(label: 'Waktu', value: o.pickupSlot),
                            _Row(label: 'Pembayaran', value: '${o.paymentMethodLabel} (${status.label})'),
                            _Row(label: 'Total', value: formatRupiah(o.total)),
                            if (status == OrderStatus.lewatBatas) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.destructive.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'Toko tidak lagi menjamin penyimpanan barang ini. Hubungi admin untuk konfirmasi.',
                                  style: TextStyle(fontSize: 12, color: AppColors.destructive),
                                ),
                              ),
                            ],
                            if (status == OrderStatus.kedaluwarsa) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.muted.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'Batas waktu pembayaran/pengambilan telah habis. Stok telah dilepas kembali ke toko.',
                                  style: TextStyle(fontSize: 12, color: AppColors.muted),
                                ),
                              ),
                            ],
                          ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    if (isCompleted) ...o.items.map((item) => Padding(padding: const EdgeInsets.only(bottom: 8), child: item.reviewId == null ? PrimaryButton(label: 'Beri Ulasan: ${item.productName}', icon: const Icon(Icons.star_outline, size: 16), onPressed: () async { await context.push('/akun/ulasan/write?order=${widget.orderId}&item=${Uri.encodeComponent(item.id)}'); if (context.mounted) await vm.load(); }) : SecondaryButton(label: 'Lihat Ulasan: ${item.productName}', icon: const Icon(Icons.rate_review_outlined, size: 16, color: AppColors.primary), onPressed: () => context.push('/produk/${item.productId}/ulasan?reviewId=${Uri.encodeComponent(item.reviewId!)}')))),

                    if (o.refund != null && o.refund!.shouldShowSection) ...[
                      const SizedBox(height: 16),
                      _RefundSection(order: o),
                    ],

                    if (isWaitingPayment) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.cancel_outlined, size: 16, color: AppColors.destructive),
                          label: const Text('Batalkan Pembelian Pickup', style: TextStyle(color: AppColors.destructive)),
                          onPressed: vm.isProcessingAction ? null : () => _handleCancel(o),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label, value;
  const _Row({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: AppTextStyles.caption.copyWith(fontSize: 13)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: AppTextStyles.body.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RefundSection extends StatelessWidget {
  final OrderModel order;
  const _RefundSection({required this.order});

  void _openWhatsApp(BuildContext context, String template) {
    final rawNumber = context.read<AppConfigViewModel>().whatsappAdminNumber;
    // Normalisasi nomor: buang non-digit; jika diawali 0 ganti dengan 62
    var cleaned = rawNumber.replaceAll(RegExp(r'\D'), '');
    if (cleaned.startsWith('0')) {
      cleaned = '62${cleaned.substring(1)}';
    }
    final encoded = Uri.encodeComponent(template);
    launchUrl(
      Uri.parse('https://wa.me/$cleaned?text=$encoded'),
      mode: LaunchMode.externalApplication,
    );
  }

  @override
  Widget build(BuildContext context) {
    final refund = order.refund!;
    final state = refund.state;
    final eligibleUntil = refund.eligibleUntil != null ? formatDateTimeWib(refund.eligibleUntil!) : '-';
    final refundedAt = refund.refundedAt != null ? formatDateTimeWib(refund.refundedAt!) : '-';
    final paidAt = refund.paidAt != null ? formatDateTimeWib(refund.paidAt!) : '-';

    String text;
    Widget? actionWidget;

    switch (state) {
      case 'dalam_batas_waktu':
        text = 'Kamu bisa mengajukan pembatalan sampai $eligibleUntil. Refund diproses manual oleh admin lewat WhatsApp.';
        actionWidget = SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.chat_outlined, size: 16),
            label: const Text('Ajukan pembatalan via WhatsApp'),
            onPressed: () {
              final tpl = 'Halo admin Sesuatu DariKota Malang, saya ingin mengajukan pembatalan dan refund untuk pesanan ${order.orderNumber} (total ${formatRupiah(order.total)}), dibayar pada $paidAt. Mohon diproses. Terima kasih.';
              _openWhatsApp(context, tpl);
            },
          ),
        );
        break;

      case 'lewat_batas_waktu':
        text = 'Batas waktu pengajuan pembatalan sudah lewat ($eligibleUntil). Jika ada kendala dari pihak toko, hubungi admin.';
        actionWidget = SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.chat_outlined, size: 16),
            label: const Text('Hubungi admin via WhatsApp'),
            onPressed: () {
              final tpl = 'Halo admin Sesuatu DariKota Malang, saya ingin menanyakan pesanan ${order.orderNumber}. Terima kasih.';
              _openWhatsApp(context, tpl);
            },
          ),
        );
        break;

      case 'lewat_batas_pengambilan':
        text = 'Pesanan ini melewati batas pengambilan, sehingga barang dianggap terjual. Jika ada kendala dari pihak toko, hubungi admin.';
        actionWidget = SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.chat_outlined, size: 16),
            label: const Text('Hubungi admin via WhatsApp'),
            onPressed: () {
              final tpl = 'Halo admin Sesuatu DariKota Malang, saya ingin menanyakan pesanan ${order.orderNumber}. Terima kasih.';
              _openWhatsApp(context, tpl);
            },
          ),
        );
        break;

      case 'menunggu_refund':
        text = 'Refund sedang diproses admin. Kamu akan mendapat notifikasi saat dana dikembalikan.';
        actionWidget = SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.chat_outlined, size: 16),
            label: const Text('Tanya status refund via WhatsApp'),
            onPressed: () {
              final tpl = 'Halo admin Sesuatu DariKota Malang, saya ingin menanyakan status refund untuk pesanan ${order.orderNumber}. Terima kasih.';
              _openWhatsApp(context, tpl);
            },
          ),
        );
        break;

      case 'sudah_direfund':
        text = 'Refund selesai pada $refundedAt.';
        actionWidget = null;
        break;

      default:
        return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.currency_exchange, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Pembatalan & Pengembalian Dana', style: AppTextStyles.h3),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(text, style: AppTextStyles.bodyMuted),
          if (actionWidget != null) ...[
            const SizedBox(height: 12),
            actionWidget,
          ],
        ],
      ),
    );
  }
}
