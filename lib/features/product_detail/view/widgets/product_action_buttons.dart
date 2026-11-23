import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/olshop_logo.dart';
import '../../../../data/models/olshop_model.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/secondary_button.dart';
import '../../../auth/viewmodel/auth_view_model.dart';
import '../../../auth/view/widgets/auth_gate_bottom_sheet.dart';
import '../../../catalog/viewmodel/app_config_view_model.dart';
import '../../viewmodel/variant_selection_view_model.dart';
import '../../../cart/viewmodel/cart_view_model.dart';
import 'cart_options_sheet.dart';

class ProductActionButtons extends StatelessWidget {
  final String productId;
  final String productName;
  final String creatorId;
  final bool isOwnProduct;

  /// Link marketplace siap tampil dari backend. Kosong = tombol marketplace disembunyikan
  /// dan tombol WhatsApp memanjang satu baris penuh.
  final List<OlshopLink> olshopLinks;
  const ProductActionButtons({super.key, required this.productId, required this.productName, this.creatorId = '', this.isOwnProduct = false, this.olshopLinks = const []});

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
    if (uri != null) {
      // TikTok Shop perlu dicoba dengan skema aplikasi agar tidak jatuh ke
      // browser/WebView internal ketika aplikasi TikTok tersedia.
      if (link.platform == OlshopPlatform.tiktokshop) {
        final rawUrl = link.url.trim();
        final tiktokScheme = Uri.tryParse(rawUrl.replaceFirst(RegExp(r'^https?:\/\/'), 'tiktok://'));
        if (tiktokScheme != null) {
          try {
            opened = await launchUrl(tiktokScheme, mode: LaunchMode.externalNonBrowserApplication);
          } catch (_) {}
        }
      }
      if (!opened) {
        try {
          opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
        } catch (_) {
          opened = false;
        }
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
    final auth = context.read<AuthViewModel>();
    final variantProvider = context.watch<VariantSelectionViewModel>();
    final isOwn = isOwnProduct || (auth.user?.creatorId != null &&
        auth.user!.creatorId!.isNotEmpty &&
        auth.user!.creatorId == creatorId);
    if (isOwn) {
      return const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('Ini produk milikmu. Kamu tidak dapat membeli atau menambahkannya ke keranjang.')));
    }
    final matched = variantProvider.matchedVariant;
    // Produk tanpa varian memakai satu baris varian standar di backend.
    // Jika data lama belum memiliki baris itu, totalStock tetap menjadi sumber
    // tampilan agar produk stok 0 tidak bisa dipesan lewat tombol ini.
    final int stockAvailable = matched != null
        ? matched.effectiveStock
        : variantProvider.product.totalStock;
    final bool isOutOfStock = stockAvailable <= 0;

    return Column(children: [
      Row(children: [
        Expanded(
          child: PrimaryButton(
            label: isOutOfStock ? 'Stok Habis' : 'Pickup',
            icon: isOutOfStock ? null : const Icon(Icons.storefront_outlined, size: 16),
            fontSize: 13,
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
                    : () async {
                        final repository = context.read<CartViewModel>().repository;
                        final picked = await showModalBottomSheet<PickupSelection>(
                          context: context,
                          isScrollControlled: true,
                          builder: (_) => CartOptionsSheet(repository: repository, productId: productId, pickup: true, initialSelection: variantProvider.selected),
                        );
                        if (picked == null || !context.mounted) return;
                        final encodedSelection = Uri.encodeComponent(jsonEncode(picked.options));
                        final reservationPath = '/reservasi/$productId?variants=$encodedSelection&quantity=${picked.quantity}';
                        if (!auth.isAuthenticated) {
                          showAuthGateSheet(context,
                              next: reservationPath,
                              contextLabel: 'pembelian pickup');
                          return;
                        }
                        context.push(reservationPath);
                      }),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: isOutOfStock || isOwn ? null : () async {
              if (!auth.isAuthenticated) {
                showAuthGateSheet(context, next: '/produk/$productId', contextLabel: 'menambah ke keranjang');
                return;
              }
              final added = await showModalBottomSheet<bool>(
                context: context,
                isScrollControlled: true,
                builder: (_) => CartOptionsSheet(repository: context.read<CartViewModel>().repository, productId: productId, initialSelection: variantProvider.selected),
              );
              if (added == true && context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Produk ditambahkan ke keranjang.')));
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.foreground,
              side: const BorderSide(color: AppColors.primary, width: 1.5),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
              textStyle: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            icon: const Icon(Icons.add_shopping_cart_outlined, size: 17),
            label: const Text('Keranjang'),
          ),
        ),
      ]),
      const SizedBox(height: 8),
      Row(children: [
        Expanded(child: SecondaryButton(fullWidth: true, compact: true, borderColor: AppColors.moss, label: 'WhatsApp', icon: const Icon(Icons.chat_bubble_outline, size: 16, color: AppColors.moss), onPressed: () {
          final waNumber = context.read<AppConfigViewModel>().whatsappAdminNumber;
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
