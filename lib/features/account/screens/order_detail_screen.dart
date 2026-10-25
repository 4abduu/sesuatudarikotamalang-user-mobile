import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/order_status_helper.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../features/account/providers/orders_provider.dart';
import '../../../data/models/order_model.dart';
import '../../../features/reservation/widgets/qr_ticket_card.dart';
import '../../../shared/app_scaffold.dart';

import 'package:url_launcher/url_launcher.dart';
import '../../catalog/providers/products_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../reservation/screens/midtrans_webview_screen.dart';
import '../../reservation/widgets/hold_countdown_widget.dart';

class OrderDetailScreen extends StatefulWidget {
  final String orderId;
  const OrderDetailScreen({super.key, required this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  bool _isLoading = true;
  bool _isProcessingAction = false;

  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  Future<void> _loadOrder() async {
    setState(() => _isLoading = true);
    await context.read<OrdersProvider>().getOrderDetail(widget.orderId);
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _handleCancel(OrderModel order) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Batalkan Reservasi'),
        content: const Text('Apakah Anda yakin ingin membatalkan reservasi ini?'),
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

    setState(() => _isProcessingAction = true);
    try {
      await context.read<OrdersProvider>().cancelOrder(order.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pesanan berhasil dibatalkan.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal membatalkan: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessingAction = false);
    }
  }

  Future<void> _handlePayAgain(OrderModel order) async {
    setState(() => _isProcessingAction = true);
    try {
      // 1. Ambil URL pembayaran dari order.snap['redirect_url'] atau request baru jika belum ada
      String? redirectUrl = order.snap?['redirect_url'] as String?;
      
      if (redirectUrl == null || redirectUrl.isEmpty) {
        final snap = await context.read<OrdersProvider>().payAgain(order.id);
        redirectUrl = snap?['redirect_url'] as String?;
      }

      if (redirectUrl == null || redirectUrl.isEmpty) {
        throw 'Gagal mendapatkan tautan pembayaran.';
      }

      if (!mounted) return;

      // 2. Buka Midtrans WebView Screen
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => MidtransWebViewScreen(
            url: redirectUrl!,
            orderId: order.id,
          ),
        ),
      );

      // 3. Polling status order dari backend (setiap 3 detik hingga maks ~30 detik)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Memeriksa status pembayaran...')),
        );
        for (int i = 0; i < 10; i++) {
          await Future.delayed(const Duration(seconds: 3));
          if (!mounted) break;
          final updated = await context.read<OrdersProvider>().getOrderDetail(order.id);
          if (updated != null && updated.status == OrderStatus.lunas) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Pembayaran berhasil dikonfirmasi!')),
              );
            }
            break;
          }
        }
        if (mounted) await _loadOrder();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Pembayaran: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessingAction = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final orders = context.watch<OrdersProvider>();
    final o = orders.orders.firstWhere((o) => o.id == widget.orderId, orElse: () => orders.orders.first);
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
      leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadOrder,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Column(
                  children: [
                    if (isWaitingPayment && o.holdExpiresAt != null) ...[
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: HoldCountdownWidget(
                          expiresAt: DateTime.tryParse(o.holdExpiresAt!)?.toLocal() ?? DateTime.now().add(const Duration(hours: 1)),
                        ),
                      ),
                    ],
                    if (shouldShowQr) ...[
                      QrTicketCard(code: o.orderNumber),
                      const SizedBox(height: 16),
                    ] else if (isWaitingPayment && o.paymentMethod.toLowerCase() == 'midtrans') ...[
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
                                  onPressed: _isProcessingAction ? null : () => _handlePayAgain(o),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
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

                    if (isCompleted && !o.reviewed) ...[
                      PrimaryButton(
                        label: 'Beri Ulasan',
                        icon: const Icon(Icons.star_outline, size: 16),
                        onPressed: () => context.push('/akun/ulasan/write?order=${widget.orderId}'),
                      ),
                    ] else if (isCompleted && o.reviewed) ...[
                      const Text('Sudah diulas', style: TextStyle(fontSize: 13, color: AppColors.moss)),
                    ],

                    if (isWaitingPayment) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.cancel_outlined, size: 16, color: AppColors.destructive),
                          label: const Text('Batalkan Reservasi', style: TextStyle(color: AppColors.destructive)),
                          onPressed: _isProcessingAction ? null : () => _handleCancel(o),
                        ),
                      ),
                    ],

                    if (status == OrderStatus.lunas) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Pesanan sudah dibayar. Pembatalan mandiri tidak dapat dilakukan.',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.foreground),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.chat_outlined, size: 16, color: AppColors.primary),
                                label: const Text('Butuh Bantuan? Hubungi Admin via WhatsApp'),
                                onPressed: () {
                                  final waNumber = context.read<ProductsProvider>().whatsappAdminNumber;
                                  final msg = Uri.encodeComponent(
                                    'Halo Admin Sesuatu DariKota Malang, saya butuh bantuan untuk pesanan ${o.orderNumber} (${o.productName}).',
                                  );
                                  launchUrl(
                                    Uri.parse('https://wa.me/$waNumber?text=$msg'),
                                    mode: LaunchMode.externalApplication,
                                  );
                                },
                              ),
                            ),
                          ],
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
    return Padding(padding: const EdgeInsets.only(bottom: 6), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [SizedBox(width: 100, child: Text(label, style: AppTextStyles.caption)), const SizedBox(width: 8), Expanded(child: Text(value, textAlign: TextAlign.right, style: AppTextStyles.body))]));
  }
}
