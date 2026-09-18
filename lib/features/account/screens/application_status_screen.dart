import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../data/dummy/dummy_creators.dart';
import '../../../data/models/creator_application_model.dart';
import '../../../data/models/notification_model.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/account/providers/applications_provider.dart';
import '../../../features/notifications/providers/notifications_provider.dart';
import '../../../shared/app_scaffold.dart';

class ApplicationStatusScreen extends StatelessWidget {
  const ApplicationStatusScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final apps = context.watch<ApplicationsProvider>();
    final app = apps.latestForUser(auth.user?.id ?? '');
    return AppScaffold(
      title: 'Pengajuan Kreator',
      body: app == null
        ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            const EmptyState(icon: Icons.assignment, title: 'Belum mengajukan', description: 'Kamu belum mengajukan jadi kreator.'),
            PrimaryButton(label: 'Daftar Jadi Kreator', onPressed: () => context.push('/daftar-kreator')),
          ]))
        : SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: AppShadows.soft,
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [const Icon(Icons.store, color: AppColors.primary), const SizedBox(width: 8), Text(app.brandName, style: AppTextStyles.h2)]),
                const SizedBox(height: 8),
                _StatusChip(status: app.status),
                const SizedBox(height: 8),
                Text(app.description, style: AppTextStyles.body),
                const SizedBox(height: 8),
                Text('Diajukan: ${app.submittedAt}', style: AppTextStyles.caption),
              ]),
            ),
            const SizedBox(height: 16),
            if (app.status == ApplicationStatus.pending)
              Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppColors.mustard.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)), child: Row(children: [const Icon(Icons.hourglass_top, color: AppColors.mustard), const SizedBox(width: 8), Expanded(child: Text('Menunggu Kurasi — tim kami sedang mengkurasi karyamu (3–5 hari kerja).', style: AppTextStyles.body))]))
            else if (app.status == ApplicationStatus.approved)
              Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppColors.moss.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)), child: Column(children: [const Icon(Icons.check_circle, color: AppColors.moss), const SizedBox(height: 8), Text('Selamat! Pengajuanmu diterima.', style: AppTextStyles.h3, textAlign: TextAlign.center), const SizedBox(height: 8), PrimaryButton(label: 'Buka Dashboard Kreator', onPressed: () => context.push('/dashboard-kreator'))]))
            else
              Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppColors.destructive.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)), child: Column(children: [const Icon(Icons.cancel, color: AppColors.destructive), const SizedBox(height: 8), Text('Pengajuan ditolak.', style: AppTextStyles.h3), if (app.rejectReason != null) ...[const SizedBox(height: 4), Text(app.rejectReason!, style: AppTextStyles.body)], const SizedBox(height: 8), OutlinedButton(onPressed: () => context.push('/daftar-kreator'), child: const Text('Ajukan Ulang'))])),
            if (app.status == ApplicationStatus.pending) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _showSimulateDialog(context, app),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                  icon: const Icon(Icons.science_outlined, size: 18),
                  label: const Text('[Demo] Simulasikan Hasil Kurasi'),
                ),
              ),
            ],
          ])),
    );
  }

  void _showSimulateDialog(BuildContext context, CreatorApplicationModel app) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Simulasi Hasil Kurasi'),
        content: const Text('Pilih hasil simulasi kurasi tim (mode demo):'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Batal'),
          ),
          OutlinedButton(
            style: OutlinedButton.styleFrom(foregroundColor: AppColors.destructive),
            onPressed: () async {
              const reason = 'Maaf, karya belum memenuhi kriteria kurasi kami saat ini. Silakan ajukan ulang dengan referensi yang lebih matang.';
              await context.read<ApplicationsProvider>().updateStatus(
                app.id,
                ApplicationStatus.rejected,
                rejectReason: reason,
              );
              if (context.mounted) {
                await context.read<NotificationsProvider>().addNotification(
                  NotificationModel(
                    id: 'n-${DateTime.now().millisecondsSinceEpoch}',
                    type: NotificationType.creator,
                    title: 'Pengajuan konsinyasi ditolak',
                    body: 'Pengajuan untuk "${app.brandName}" ditolak. Lihat detail di halaman pengajuan.',
                    date: 'Baru saja',
                    read: false,
                  ),
                );
              }
              if (context.mounted) Navigator.of(dialogCtx).pop();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('[Demo] Pengajuan ditolak. Notifikasi ditambahkan.')),
                );
              }
            },
            child: const Text('Tolak'),
          ),
          ElevatedButton(
            onPressed: () async {
              final auth = context.read<AuthProvider>();
              await context.read<ApplicationsProvider>().updateStatus(
                app.id,
                ApplicationStatus.approved,
              );
              // Promote user to creator with the matching creatorId (if any).
              final creatorId = dummyCreators.firstWhere(
                (c) => c.name.toLowerCase() == app.applicantName.toLowerCase(),
                orElse: () => dummyCreators.first,
              ).id;
              auth.becomeCreator(creatorId);
              if (context.mounted) {
                await context.read<NotificationsProvider>().addNotification(
                  NotificationModel(
                    id: 'n-${DateTime.now().millisecondsSinceEpoch}',
                    type: NotificationType.creator,
                    title: 'Pengajuan konsinyasi diterima!',
                    body: 'Selamat! Pengajuan untuk "${app.brandName}" diterima. Akun kreatormu kini aktif.',
                    date: 'Baru saja',
                    read: false,
                  ),
                );
              }
              if (context.mounted) Navigator.of(dialogCtx).pop();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('[Demo] Pengajuan diterima. Kamu kini seorang kreator!')),
                );
              }
            },
            child: const Text('Terima'),
          ),
        ],
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
      ApplicationStatus.approved => ('Kreator Aktif', AppColors.moss, AppColors.onMoss),
      ApplicationStatus.rejected => ('Ditolak', AppColors.destructive, AppColors.onPrimary),
    };
    return Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: bg.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(999)), child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: fg)));
  }
}
