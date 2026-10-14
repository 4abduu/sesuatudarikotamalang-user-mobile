import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../shared/app_scaffold.dart';

import '../providers/creator_dashboard_provider.dart';

/// Creator dashboard → "Produk Saya" list.
/// Shows products owned by the logged-in creator as shadowed cards
/// (NOT ListTile) with edit affordance → /dashboard-kreator/product-form?id=.
class MyProductsScreen extends StatelessWidget {
  const MyProductsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (!auth.isAuthenticated || !auth.isCreator) {
      return AppScaffold(
        title: 'Produk Saya',
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline, size: 48, color: AppColors.muted),
                const SizedBox(height: 12),
                Text('Akses khusus kreator', style: AppTextStyles.h2, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(onPressed: () => context.go('/akun'), child: const Text('Kembali ke Akun')),
              ],
            ),
          ),
        ),
      );
    }

    final dashboard = context.watch<CreatorDashboardProvider>();
    final products = dashboard.myProducts;

    return AppScaffold(
      title: 'Produk Saya',
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/dashboard-kreator/product-form'),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: AppColors.onPrimary),
      ),
      body: RefreshIndicator(
        onRefresh: () => dashboard.fetchDashboardData(),
        child: dashboard.isLoading && products.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : products.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: 120),
                      EmptyState(
                        icon: Icons.inventory_2_outlined,
                        title: 'Belum ada produk',
                        description: 'Tekan tombol + untuk menambahkan produk pertamamu.',
                      ),
                    ],
                  )
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: products.length,
                    itemBuilder: (_, i) {
                      final p = products[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: AppShadows.soft,
                          ),
                          child: Row(children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryLight]),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.brush, color: AppColors.onPrimary, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(p.name, style: AppTextStyles.label, maxLines: 1, overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 2),
                                  Text('${formatRupiah(p.price)} · Stok ${p.totalStock}', style: AppTextStyles.caption),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
                              onPressed: () => context.push('/dashboard-kreator/product-form?id=${p.id}'),
                            ),
                          ]),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
