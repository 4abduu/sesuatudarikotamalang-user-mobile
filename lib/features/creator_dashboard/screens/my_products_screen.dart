import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
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
class MyProductsScreen extends StatefulWidget {
  const MyProductsScreen({super.key});

  @override
  State<MyProductsScreen> createState() => _MyProductsScreenState();
}

class _MyProductsScreenState extends State<MyProductsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<CreatorDashboardProvider>().fetchDashboardData();
      }
    });
  }

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
      floatingActionButton: DecoratedBox(
        // Bayangan FAB: 0 6px 20px primary 40% (TSX).
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 6))],
        ),
        child: FloatingActionButton(
          onPressed: () => context.push('/dashboard-kreator/product-form'),
          backgroundColor: AppColors.primary,
          elevation: 0,
          focusElevation: 0,
          hoverElevation: 0,
          highlightElevation: 0,
          shape: const CircleBorder(),
          child: const Icon(Icons.add, color: AppColors.onPrimary, size: 24),
        ),
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
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                    itemCount: products.length + 1,
                    itemBuilder: (_, idx) {
                      if (idx == 0) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text('Daftar produk kamu', style: AppTextStyles.bodyMuted),
                        );
                      }
                      final p = products[idx - 1];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.border),
                            boxShadow: AppShadows.soft,
                          ),
                          child: Row(children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [AppColors.primary, AppColors.primaryLight],
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.brush, color: AppColors.onPrimary, size: 16),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(p.name, style: GoogleFonts.baloo2(fontSize: 13, fontWeight: FontWeight.w500, height: 1.25, color: AppColors.foreground), maxLines: 1, overflow: TextOverflow.ellipsis),
                                  Text('${formatRupiah(p.price)} · Stok ${p.totalStock}', style: AppTextStyles.caption),
                                ],
                              ),
                            ),
                            IconButton(
                              style: IconButton.styleFrom(
                                backgroundColor: AppColors.background,
                                fixedSize: const Size(32, 32),
                                minimumSize: const Size(32, 32),
                                padding: EdgeInsets.zero,
                              ),
                              iconSize: 16,
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
