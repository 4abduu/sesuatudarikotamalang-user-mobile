import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/secondary_button.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/auth/widgets/auth_gate_bottom_sheet.dart';
import '../providers/variant_selection_provider.dart';

class ProductActionButtons extends StatelessWidget {
  final String productId;
  final String productName;
  final String creatorId;
  const ProductActionButtons({super.key, required this.productId, required this.productName, this.creatorId = ''});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final variantProvider = context.watch<VariantSelectionProvider>();
    final isOwn = auth.user?.creatorId != null &&
        auth.user!.creatorId!.isNotEmpty &&
        auth.user!.creatorId == creatorId;
    return Column(children: [
      PrimaryButton(
        label: 'Pesan untuk Pick-up di Toko',
        icon: const Icon(Icons.store, size: 18),
        onPressed: isOwn
          ? () {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Ini produkmu sendiri'),
                  content: const Text('Kamu tidak bisa memesan produk sendiri. Untuk uji coba, gunakan akun pembeli lain atau logout dulu.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Mengerti')),
                  ],
                ),
              );
            }
          : () {
              if (!auth.isAuthenticated) {
                showAuthGateSheet(context, next: '/reservasi/$productId', contextLabel: 'pesan pickup');
                return;
              }
              context.push('/reservasi/$productId');
            },
      ),
      const SizedBox(height: 8),
      Row(children: [
        Expanded(child: SecondaryButton(fullWidth: true, label: 'WhatsApp', icon: const Icon(Icons.chat, size: 16, color: AppColors.moss), onPressed: () {
          final text = 'Halo, saya mau tanya stok untuk $productName (varian: ${variantProvider.variantLabel}). Apakah masih tersedia?';
          launchUrl(Uri.parse('https://wa.me/6281234567890?text=${Uri.encodeComponent(text)}'));
        })),
        const SizedBox(width: 8),
        Expanded(child: SecondaryButton(fullWidth: true, label: 'Shopee', icon: const Icon(Icons.shopping_bag, size: 16, color: AppColors.primary), onPressed: () {
          launchUrl(Uri.parse('https://shopee.co.id/sesuatu-darikota-malang'));
        })),
      ]),
    ]);
  }
}
