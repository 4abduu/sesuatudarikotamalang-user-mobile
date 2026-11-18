import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/craft_cards.dart';
import '../../../features/auth/viewmodel/auth_view_model.dart';
import '../../../shared/app_scaffold.dart';

import '../viewmodel/creator_dashboard_view_model.dart';
import 'widgets/creator_profile_header.dart';

class CreatorDashboardScreen extends StatefulWidget {
  const CreatorDashboardScreen({super.key});

  @override
  State<CreatorDashboardScreen> createState() => _CreatorDashboardScreenState();
}

class _CreatorDashboardScreenState extends State<CreatorDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final auth = context.read<AuthViewModel>();
      if (mounted && auth.isAuthenticated && auth.isCreator) {
        context.read<CreatorDashboardViewModel>().fetchDashboardData();
      }
    });
  }

  Future<void> _open(String location) async {
    await context.push(location);
    if (!mounted) return;
    final auth = context.read<AuthViewModel>();
    if (auth.isAuthenticated && auth.isCreator) {
      await context.read<CreatorDashboardViewModel>().fetchDashboardData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
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

    final dashboard = context.watch<CreatorDashboardViewModel>();
    final products = dashboard.myProducts;
    final artisan = dashboard.artisanProfile;

    return AppScaffold(
      title: 'Dashboard Kreator',
      body: RefreshIndicator(
        onRefresh: () => dashboard.fetchDashboardData(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CreatorProfileHeader(
                artisan: artisan,
                fallbackName: auth.user!.name,
                onEdit: () => _open('/dashboard-kreator/profil-toko'),
              ),
              const SizedBox(height: 16),
              _StatRow(
                products: products,
                rating: artisan?.rating ?? (products.isNotEmpty ? (products.fold<double>(0, (s, p) => s + p.rating) / products.length) : 0.0),
              ),
              const SizedBox(height: 16),
              MenuCard(
                icon: Icons.inventory_2_outlined,
                title: 'Produk Saya',
                subtitle: '${products.length} produk aktif',
                onTap: () => _open('/dashboard-kreator/my-products'),
              ),
              const SizedBox(height: 10),
              MenuCard(
                icon: Icons.auto_stories_outlined,
                title: 'Cerita Saya',
                subtitle: '${products.where((p) => p.hasStory).length} cerita',
                onTap: () => _open('/dashboard-kreator/my-stories'),
              ),
              const SizedBox(height: 10),
              MenuCard(
                icon: Icons.bar_chart_outlined,
                iconColor: AppColors.moss,
                title: 'Laporan Saya',
                subtitle: 'Ringkasan penjualan bulanan',
                onTap: () => _open('/dashboard-kreator/laporan'),
              ),
              const SizedBox(height: 10),
              MenuCard(
                icon: Icons.storefront_outlined,
                title: 'Profil Toko',
                subtitle: 'Foto, nama brand, dan bio',
                onTap: () => _open('/dashboard-kreator/profil-toko'),
              ),

            ],
          ),
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final List products;
  final double rating;
  const _StatRow({required this.products, required this.rating});
  @override
  Widget build(BuildContext context) {
    final ratingText = rating > 0 ? rating.toStringAsFixed(1) : '-';
    return Row(children: [
      Expanded(child: StatChipCard(icon: Icons.inventory_2_outlined, label: 'Produk', value: products.length.toString())),
      const SizedBox(width: 8),
      Expanded(child: StatChipCard(icon: Icons.star, label: 'Rating', value: ratingText)),
      const SizedBox(width: 8),
      Expanded(child: StatChipCard(icon: Icons.sell_outlined, label: 'Terjual', value: products.fold<int>(0, (sum, product) => sum + (product.soldCount as int)).toString())),
    ]);
  }
}
