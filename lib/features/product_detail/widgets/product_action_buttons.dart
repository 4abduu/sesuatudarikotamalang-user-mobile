import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/olshop_logo.dart';
import '../../../data/models/olshop_model.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/secondary_button.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/auth/widgets/auth_gate_bottom_sheet.dart';
import '../../../features/catalog/providers/products_provider.dart';
import '../providers/variant_selection_provider.dart';

class ProductActionButtons extends StatelessWidget {
  final String productId;
  final String productName;
  final String creatorId;

  /// Link marketplace siap tampil dari backend. Kosong = tombol marketplace disembunyikan
  /// dan tombol WhatsApp memanjang satu baris penuh.
  final List<OlshopLink> olshopLinks;
  const ProductActionButtons({super.key, required this.productId, required this.productName, this.creatorId = '', this.olshopLinks = const []});

  Future<void> _openLink(BuildContext context, OlshopLink link) async {
    final label = link.platform.label;
    if (link.isStoreFallback) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Produk ini tidak punya link khusus'),
          content: Text('Produk ini belum punya link khusus di $label. Kamu akan diarahkan ke halaman toko kami di $label.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('Lanjut ke $label')),
          ],
        ),
      );
      if (proceed != true || !context.mounted) return;
    }
    final uri = Uri.tryParse(link.url);
    var opened = false;
    if (uri != null && uri.scheme == 'https') {
      try {
        opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {
        opened = false;
      }
    }
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Tidak bisa membuka $label')));
    }
  }

  void _showPicker(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Beli di marketplace', style: AppTextStyles.h3),
              const SizedBox(height: 2),
              Text('Pilih marketplace tujuan', style: AppTextStyles.caption),
              const SizedBox(height: 12),
              for (final link in olshopLinks)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: OlshopLogo(platform: link.platform, size: 32),
                  title: Text(link.platform.label, style: AppTextStyles.title),
                  subtitle: Text(link.isStoreFallback ? 'Halaman toko' : 'Link produk', style: AppTextStyles.caption),
                  trailing: const Icon(Icons.open_in_new, size: 18, color: AppColors.muted),
                  onTap: () {
                    Navigator.pop(ctx);
                    _openLink(context, link);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOlshopButton(BuildContext context) {
    final single = olshopLinks.length == 1;
    final first = olshopLinks.first;
    final label = single ? 'Beli di ${first.platform.label}' : 'Beli di Marketplace';
    final borderColor = single ? first.platform.color : AppColors.primary;
    final shown = olshopLinks.take(3).toList();
    return OutlinedButton(
      onPressed: () => single ? _openLink(context, first) : _showPicker(context),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.foreground,
        side: BorderSide(color: borderColor, width: 1.5),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        textStyle: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600),
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        if (single)
          OlshopLogo(platform: first.platform, size: 18)
        else
          SizedBox(
            width: 18.0 + (shown.length - 1) * 12,
            height: 18,
            child: Stack(children: [
              for (var i = 0; i < shown.length; i++)
                Positioned(
                  left: i * 12.0,
                  child: DecoratedBox(
                    decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.surface, width: 1.5)),
                    child: ClipOval(child: OlshopLogo(platform: shown[i].platform, size: 18)),
                  ),
                ),
            ]),
          ),
        const SizedBox(width: 6),
        Flexible(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis)),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final variantProvider = context.watch<VariantSelectionProvider>();
    final isOwn = auth.user?.creatorId != null &&
        auth.user!.creatorId!.isNotEmpty &&
        auth.user!.creatorId == creatorId;
    final matched = variantProvider.matchedVariant;
    final int stockAvailable = matched != null ? matched.effectiveStock : 1;
    final bool isOutOfStock = stockAvailable <= 0;

    return Column(children: [
      PrimaryButton(
        label: isOutOfStock ? 'Stok Habis' : 'Pesan untuk Pick-up di Toko',
        icon: isOutOfStock ? null : const Icon(Icons.storefront_outlined, size: 16),
        onPressed: isOutOfStock
            ? null
            : (isOwn
                ? () {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Ini produkmu sendiri'),
                        content: const Text(
                            'Kamu tidak bisa memesan produk sendiri. Untuk uji coba, gunakan akun pembeli lain atau logout dulu.'),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Mengerti')),
                        ],
                      ),
                    );
                  }
                : () {
                    if (!auth.isAuthenticated) {
                      showAuthGateSheet(context,
                          next: '/reservasi/$productId',
                          contextLabel: 'pesan pickup');
                      return;
                    }
                    context.push('/reservasi/$productId');
                  }),
      ),
      const SizedBox(height: 8),
      Row(children: [
        Expanded(child: SecondaryButton(fullWidth: true, compact: true, borderColor: AppColors.moss, label: 'WhatsApp', icon: const Icon(Icons.chat_bubble_outline, size: 16, color: AppColors.moss), onPressed: () {
          final waNumber = context.read<ProductsProvider>().whatsappAdminNumber;
          final text = 'Halo, saya mau tanya stok untuk $productName (varian: ${variantProvider.variantLabel}). Apakah masih tersedia?';
          launchUrl(Uri.parse('https://wa.me/$waNumber?text=${Uri.encodeComponent(text)}'), mode: LaunchMode.externalApplication);
        })),
        // Tombol marketplace hanya ada bila produk punya link; kalau tidak, WhatsApp memanjang penuh.
        if (olshopLinks.isNotEmpty) ...[
          const SizedBox(width: 8),
          Expanded(child: _buildOlshopButton(context)),
        ],
      ]),
    ]);
  }
}
