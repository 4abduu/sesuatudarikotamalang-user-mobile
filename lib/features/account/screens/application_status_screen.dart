import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/secondary_button.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../data/models/creator_application_model.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/account/providers/applications_provider.dart';
import '../../../shared/app_scaffold.dart';

class ApplicationStatusScreen extends StatefulWidget {
  const ApplicationStatusScreen({super.key});

  @override
  State<ApplicationStatusScreen> createState() => _ApplicationStatusScreenState();
}

class _ApplicationStatusScreenState extends State<ApplicationStatusScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refresh();
    });
  }

  Future<void> _refresh() async {
    final apps = context.read<ApplicationsProvider>();
    final auth = context.read<AuthProvider>();
    await Future.wait([
      apps.fetchMyApplications(),
      auth.refreshMe(),
    ]);
  }

  void _showImagePreview(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                loadingBuilder: (_, child, progress) {
                  if (progress == null) return child;
                  return Container(
                    height: 250,
                    color: AppColors.surfaceAlt,
                    child: const Center(child: CircularProgressIndicator()),
                  );
                },
                errorBuilder: (_, __, ___) => Container(
                  height: 250,
                  color: AppColors.surfaceAlt,
                  child: const Center(
                    child: Icon(Icons.broken_image, size: 48, color: AppColors.muted),
                  ),
                ),
              ),
            ),
            IconButton(
              icon: const CircleAvatar(
                backgroundColor: Colors.black54,
                child: Icon(Icons.close, color: Colors.white, size: 20),
              ),
              onPressed: () => Navigator.of(ctx).pop(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final apps = context.watch<ApplicationsProvider>();
    final app = apps.latestForUser(auth.user?.id ?? '');

    return AppScaffold(
      title: 'Pengajuan Kreator',
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: apps.isLoading && app == null
            ? const Center(child: CircularProgressIndicator())
            : app == null
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      const SizedBox(height: 120),
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const EmptyState(
                              icon: Icons.assignment,
                              title: 'Belum mengajukan',
                              description: 'Kamu belum mengajukan jadi kreator.',
                            ),
                            PrimaryButton(
                              label: 'Daftar Jadi Kreator',
                              onPressed: () => context.push('/daftar-kreator'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: AppShadows.soft,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.store_outlined, size: 20, color: AppColors.primary),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(app.brandName, style: AppTextStyles.h2),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              _StatusChip(status: app.status),
                              const SizedBox(height: 8),
                              Text(app.description, style: AppTextStyles.body.copyWith(height: 1.375)),
                              const SizedBox(height: 8),
                              Text('Diajukan: ${app.submittedAt}', style: AppTextStyles.caption),
                            ],
                          ),
                        ),
                        if (app.samplePhotos.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Text('Foto Sampel Karya', style: AppTextStyles.h3),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 80,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: app.samplePhotos.length,
                              separatorBuilder: (_, __) => const SizedBox(width: 8),
                              itemBuilder: (ctx, idx) {
                                final url = app.samplePhotos[idx];
                                return GestureDetector(
                                  onTap: () => _showImagePreview(context, url),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      url,
                                      width: 80,
                                      height: 80,
                                      fit: BoxFit.cover,
                                      loadingBuilder: (_, child, progress) {
                                        if (progress == null) return child;
                                        return Container(
                                          width: 80,
                                          height: 80,
                                          color: AppColors.surfaceAlt,
                                          child: const Center(
                                            child: SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(strokeWidth: 2),
                                            ),
                                          ),
                                        );
                                      },
                                      errorBuilder: (_, __, ___) => Container(
                                        width: 80,
                                        height: 80,
                                        color: AppColors.surfaceAlt,
                                        child: const Icon(Icons.broken_image, size: 24, color: AppColors.muted),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        if (app.status == ApplicationStatus.pending) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.mustard.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.schedule, size: 20, color: AppColors.mustard),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Menunggu Kurasi — tim kami sedang mengkurasi karyamu (3–5 hari kerja).',
                                    style: AppTextStyles.body.copyWith(height: 1.375),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          SecondaryButton(
                            label: 'Muat ulang status',
                            icon: const Icon(Icons.refresh, size: 18),
                            onPressed: _refresh,
                            verticalPadding: 12,
                            fontSize: 13,
                          ),
                        ] else if (app.status == ApplicationStatus.approved) ...[
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.moss.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Column(
                                children: [
                                  const Icon(Icons.check_circle_outline, size: 32, color: AppColors.moss),
                                  const SizedBox(height: 8),
                                  Text('Selamat! Pengajuanmu diterima.', style: AppTextStyles.h3, textAlign: TextAlign.center),
                                  const SizedBox(height: 12),
                                  if (auth.isCreator)
                                    PrimaryButton(
                                      label: 'Buka Dashboard Kreator',
                                      fullWidth: false,
                                      verticalPadding: 10,
                                      fontSize: 13,
                                      onPressed: () => context.push('/dashboard-kreator'),
                                    )
                                  else ...[
                                    Text(
                                      'Memperbarui peran akunmu…',
                                      style: AppTextStyles.bodyMuted.copyWith(fontSize: 13),
                                    ),
                                    const SizedBox(height: 8),
                                    SecondaryButton(
                                      label: 'Muat ulang peran',
                                      icon: const Icon(Icons.refresh, size: 18),
                                      onPressed: _refresh,
                                      fullWidth: false,
                                      verticalPadding: 8,
                                      fontSize: 12,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ] else ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.destructive.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: SizedBox(
                              width: double.infinity,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.block, size: 24, color: AppColors.destructive),
                                  const SizedBox(height: 8),
                                  Text('Pengajuan ditolak.', style: AppTextStyles.h3),
                                  if (app.rejectReason != null) ...[
                                    const SizedBox(height: 4),
                                    Text(app.rejectReason!, style: AppTextStyles.body.copyWith(fontSize: 13, height: 1.375)),
                                  ],
                                  const SizedBox(height: 12),
                                  SecondaryButton(
                                    label: 'Ajukan Ulang',
                                    fullWidth: false,
                                    verticalPadding: 10,
                                    fontSize: 13,
                                    onPressed: () => context.push('/daftar-kreator'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final ApplicationStatus status;
  const _StatusChip({required this.status});
  @override
  Widget build(BuildContext context) {
    final (label, bg, fg) = switch (status) {
      ApplicationStatus.pending => ('Menunggu Kurasi', AppColors.mustard, const Color(0xFF8A6A1A)),
      ApplicationStatus.approved => ('Kreator Aktif', AppColors.moss, AppColors.moss),
      ApplicationStatus.rejected => ('Ditolak', AppColors.destructive, AppColors.destructive),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: fg)),
    );
  }
}
