import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/auth/widgets/auth_gate_bottom_sheet.dart';
import '../../../features/account/providers/orders_provider.dart';
import '../../../data/models/order_model.dart';
import '../../../data/models/product_model.dart';
import '../../../shared/app_scaffold.dart';
import '../providers/reservation_flow_provider.dart';
import '../widgets/step_indicator.dart';
import '../widgets/date_time_picker_step.dart';
import '../widgets/payment_method_step.dart';
import '../widgets/hold_countdown_widget.dart';
import 'midtrans_webview_screen.dart';

import '../../../core/network/api_client.dart';
import '../../../features/catalog/providers/products_provider.dart';

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

    final products = context.watch<ProductsProvider>();
    final product = products.products.cast<ProductModel?>().firstWhere(
      (p) => p?.id == productId,
      orElse: () => null,
    );

    if (product == null) {
      return FutureBuilder<ProductModel?>(
        future: products.getProductById(productId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: LoadingIndicator(label: 'Memuat data produk...'));
          }
          final loadedProduct = snapshot.data;
          if (loadedProduct == null) {
            return Scaffold(
              appBar: AppBar(title: const Text('Reservasi')),
              body: const Center(child: Text('Produk tidak ditemukan')),
            );
          }
          return ChangeNotifierProvider(
            create: (_) => ReservationFlowProvider(loadedProduct),
            child: const _ReservationBody(),
          );
        },
      );
    }

    return ChangeNotifierProvider(
      create: (_) => ReservationFlowProvider(product),
      child: const _ReservationBody(),
    );
  }
}

class _ReservationBody extends StatelessWidget {
  const _ReservationBody();
  @override
  Widget build(BuildContext context) {
    final p = context.watch<ReservationFlowProvider>();
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
              Expanded(child: OutlinedButton(onPressed: p.processing ? null : () => p.prevStep(), child: const Text('Kembali'))),
              const SizedBox(width: 8),
              Expanded(child: ElevatedButton(
                onPressed: (p.paymentMethod == null || p.processing) ? null : () async {
                  // Check-at-submit: Validasi stok lokal dulu
                  final err = p.checkAtSubmit(orders: orders.orders);
                  if (err != null) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
                    if (err.contains('habis')) p.restart();
                    return;
                  }

                  p.setProcessing(true);
                  try {
                    final variant = p.variantProvider.matchedVariant;
                    final created = await orders.createOrder(
                      productId: p.product.id,
                      variantId: (p.product.hasVariants && variant != null) ? variant.id : null,
                      pickupDate: p.selectedDate!,
                      pickupSlot: p.selectedSlot!,
                      paymentMethod: p.paymentMethod == PaymentMethod.midtrans ? 'midtrans' : 'cod',
                    );

                    p.setCreatedOrder(created);
                    p.nextStep();

                    if (p.paymentMethod == PaymentMethod.midtrans) {
                      final redirectUrl = created.snap?['redirect_url'] as String?;
                      if (redirectUrl != null && redirectUrl.isNotEmpty) {
                        if (context.mounted) {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => MidtransWebViewScreen(
                                url: redirectUrl,
                                orderId: created.id,
                              ),
                            ),
                          );

                          // Polling status order dari webhook backend (maks 60s, cek tiap 3s)
                          for (int i = 0; i < 15; i++) {
                            await Future.delayed(const Duration(seconds: 3));
                            final updated = await orders.getOrderDetail(created.id);
                            if (updated != null && updated.status == OrderStatus.lunas) {
                              p.setPaid();
                              break;
                            }
                          }
                        }
                      } else {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Pesanan dibuat. Silakan selesaikan pembayaran di detail pesanan.')),
                          );
                        }
                      }
                    } else {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Reservasi berhasil dibuat!')),
                        );
                      }
                    }
                  } on ApiException catch (e) {
                    if (context.mounted) {
                      // Pesan error selalu dari backend; mobile tidak mengganti dengan teks buatan sendiri.
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
                    }
                    if (e.code == 'SLOT_FULL' || e.code == 'SLOT_PASSED' || e.code == 'SLOT_UNAVAILABLE') {
                      // Slot penuh, lewat, atau tidak lagi tersedia: kembali ke pilihan jadwal dengan data slot terbaru.
                      p.backToSchedule();
                    } else if (e.status == 409) {
                      // Konflik stok: mulai ulang alur agar varian dan stok dipilih kembali.
                      p.restart();
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Terjadi kesalahan: ${e.toString()}')),
                      );
                    }
                  } finally {
                    p.setProcessing(false);
                  }
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
