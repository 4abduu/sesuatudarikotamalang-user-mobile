import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/craft_cards.dart';
import '../../../data/dummy/dummy_creators.dart';
import '../../../data/dummy/dummy_products.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../shared/app_scaffold.dart';

class CreatorDashboardScreen extends StatelessWidget {
  const CreatorDashboardScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (!auth.isAuthenticated || !auth.isCreator) {
      return AppScaffold(title: 'Akses Ditolak', body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.lock, size: 48, color: AppColors.muted),
        const SizedBox(height: 12),
        Text('Akses khusus kreator', style: AppTextStyles.h2),
        const SizedBox(height: 8),
        Text('Kamu belum jadi kreator. Ajukan konsinyasi dulu ya.', style: AppTextStyles.bodyMuted, textAlign: TextAlign.center),
        const SizedBox(height: 16),
        ElevatedButton(onPressed: () => context.push('/daftar-kreator'), child: const Text('Ajukan Jadi Kreator')),
      ])));
    }
    final creator = dummyCreators.firstWhere((c) => c.id == auth.user!.creatorId, orElse: () => dummyCreators.first);
    final products = dummyProducts.where((p) => p.creatorId == creator.id).toList();
    return AppScaffold(
      title: 'Dashboard Kreator',
      body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Halo, ${auth.user!.name}!', style: AppTextStyles.h1),
        Text(creator.specialty, style: AppTextStyles.bodyMuted),
        const SizedBox(height: 16),
        _StatRow(products: products),
        const SizedBox(height: 16),
        MenuCard(
          icon: Icons.inventory_2_outlined,
          title: 'Produk Saya',
          subtitle: '${products.length} produk aktif',
          onTap: () => context.push('/dashboard-kreator/my-products'),
        ),
        const SizedBox(height: 10),
        MenuCard(
          icon: Icons.auto_stories_outlined,
          title: 'Cerita Saya',
          subtitle: '${products.where((p) => p.hasStory).length} cerita',
          onTap: () => context.push('/dashboard-kreator/my-stories'),
        ),
        const SizedBox(height: 10),
        MenuCard(
          icon: Icons.assignment_outlined,
          title: 'Status Pengajuan',
          subtitle: 'Diterima & Tayang',
          onTap: () => context.push('/akun/pengajuan'),
        ),
      ])),
    );
  }
}

class _StatRow extends StatelessWidget {
  final List products;
  const _StatRow({required this.products});
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(child: StatChipCard(icon: Icons.inventory_2_outlined, label: 'Produk', value: products.length.toString())),
      const SizedBox(width: 8),
      const Expanded(child: StatChipCard(icon: Icons.star, label: 'Rating', value: '4.9')),
      const SizedBox(width: 8),
      Expanded(child: StatChipCard(icon: Icons.sell_outlined, label: 'Terjual', value: products.fold<int>(0, (sum, product) => sum + (product.soldCount as int)).toString())),
    ]);
  }
}
