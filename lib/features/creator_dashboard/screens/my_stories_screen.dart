import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../data/dummy/dummy_creators.dart';
import '../../../data/dummy/dummy_products.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../shared/app_scaffold.dart';

/// Lists the creator's products and the "Behind the Design" story
/// status for each. For products with a story → show story title +
/// "Edit Cerita" button. For products without → "Tambah Cerita"
/// button. Both buttons navigate to [StoryFormScreen] with `?productId=`.
class MyStoriesScreen extends StatelessWidget {
  const MyStoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (!auth.isAuthenticated || !auth.isCreator) {
      return AppScaffold(
        title: 'Cerita Saya',
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
    final creator = dummyCreators.firstWhere(
      (c) => c.id == auth.user!.creatorId,
      orElse: () => dummyCreators.first,
    );
    final products = dummyProducts.where((p) => p.creatorId == creator.id).toList();
    return AppScaffold(
      title: 'Cerita Saya',
      body: products.isEmpty
          ? const EmptyState(
              icon: Icons.auto_stories_outlined,
              title: 'Belum ada produk',
              description: 'Tambahkan produk dulu untuk mulai menulis cerita di balik desain.',
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: products.length,
              itemBuilder: (_, i) {
                final p = products[i];
                final hasStory = p.hasStory;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: AppShadows.soft,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryLight]),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.brush, color: AppColors.onPrimary, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p.name, style: AppTextStyles.label, maxLines: 2, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 2),
                              Text(formatRupiah(p.price), style: AppTextStyles.caption),
                              const SizedBox(height: 8),
                              if (hasStory) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.moss.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.auto_stories, size: 12, color: AppColors.moss),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          p.story!.title,
                                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.moss),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ] else
                                Text('Belum ada cerita', style: AppTextStyles.caption),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton.tonal(
                          onPressed: () => context.push('/dashboard-kreator/story-form?productId=${p.id}'),
                          style: FilledButton.styleFrom(
                            backgroundColor: hasStory ? AppColors.surfaceAlt : AppColors.primary.withValues(alpha: 0.12),
                            foregroundColor: hasStory ? AppColors.foreground : AppColors.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                          ),
                          child: Text(hasStory ? 'Edit' : 'Tambah Cerita', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
