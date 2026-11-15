import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/craft_cards.dart';
import '../../../features/catalog/providers/products_provider.dart';
import '../../../shared/app_scaffold.dart';

/// Halaman "Tentang Kami": deskripsi toko + kontak (email & WhatsApp) dari pengaturan admin.
/// Dapat dibuka tanpa login.
class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  static const _fallbackText =
      'Sesuatu DariKota Malang menghadirkan karya kreator lokal khas Kota Malang, dari kartu pos sampai keramik, '
      'lengkap dengan cerita di balik setiap karya.';

  @override
  void initState() {
    super.initState();
    // Selalu ambil data terbaru supaya perubahan dari admin langsung terlihat.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<ProductsProvider>().fetchSettings();
    });
  }

  Future<void> _open(Uri uri) async {
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && mounted) _snack('Tidak bisa membuka aplikasi untuk ini');
    } catch (_) {
      if (mounted) _snack('Tidak bisa membuka aplikasi untuk ini');
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Tentang Kami',
      showBottomNav: false,
      body: Consumer<ProductsProvider>(
        builder: (context, prov, _) {
          if (!prov.settingsDone) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          final description = prov.aboutDescription ?? _fallbackText;
          final paragraphs = description
              .split(RegExp(r'\n\s*\n'))
              .map((p) => p.trim())
              .where((p) => p.isNotEmpty)
              .toList();
          final email = prov.contactEmail;
          final wa = prov.settingsOk ? prov.whatsappAdminNumber : '';

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                    boxShadow: AppShadows.sticker,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('KENALI KAMI', style: AppTextStyles.eyebrow),
                      const SizedBox(height: 4),
                      Text('Sesuatu DariKota Malang', style: AppTextStyles.h2),
                      const SizedBox(height: 12),
                      for (var i = 0; i < paragraphs.length; i++) ...[
                        if (i > 0) const SizedBox(height: 12),
                        Text(paragraphs[i], style: AppTextStyles.body.copyWith(height: 1.5)),
                      ],
                    ],
                  ),
                ),
                if ((email != null && email.isNotEmpty) || wa.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text('Hubungi Kami', style: AppTextStyles.h3),
                  const SizedBox(height: 10),
                  if (wa.isNotEmpty)
                    MenuCard(
                      icon: Icons.chat_bubble_outline,
                      title: 'WhatsApp',
                      subtitle: '+$wa',
                      iconColor: AppColors.moss,
                      onTap: () => _open(Uri.parse(
                          'https://wa.me/$wa?text=${Uri.encodeComponent('Halo, saya ingin bertanya tentang Sesuatu DariKota Malang.')}')),
                    ),
                  if (wa.isNotEmpty && email != null && email.isNotEmpty) const SizedBox(height: 10),
                  if (email != null && email.isNotEmpty)
                    MenuCard(
                      icon: Icons.mail_outline,
                      title: 'Email',
                      subtitle: email,
                      onTap: () => _open(Uri(scheme: 'mailto', path: email)),
                    ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
