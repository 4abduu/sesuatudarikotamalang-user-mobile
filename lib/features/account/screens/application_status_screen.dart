import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_text_styles.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/secondary_button.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../data/dummy/dummy_creators.dart';
import '../../../data/models/creator_application_model.dart';
import '../../../data/models/notification_model.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/account/providers/applications_provider.dart';
import '../../../features/notifications/providers/notifications_provider.dart';
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
      context.read<ApplicationsProvider>().fetchMyApplications();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final apps = context.watch<ApplicationsProvider>();
    final app = apps.latestForUser(auth.user?.id ?? '');
    return AppScaffold(
      title: 'Pengajuan Kreator',
      body: RefreshIndicator(
        onRefresh: () => apps.fetchMyApplications(),
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
                            const EmptyState(icon: Icons.assignment, title: 'Belum mengajukan', description: 'Kamu belum mengajukan jadi kreator.'),
                            PrimaryButton(label: 'Daftar Jadi Kreator', onPressed: () => context.push('/daftar-kreator')),
                          ],
                        ),
                      ),
                    ],
                  )
                : SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    child: Column(children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: AppShadows.soft,
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [const Icon(Icons.store_outlined, size: 20, color: AppColors.primary), const SizedBox(width: 8), Text(app.brandName, style: AppTextStyles.h2)]),
                const SizedBox(height: 8),
                _StatusChip(status: app.status),
                const SizedBox(height: 8),
                Text(app.description, style: AppTextStyles.body.copyWith(height: 1.375)),
                const SizedBox(height: 8),
                Text('Diajukan: ${app.submittedAt}', style: AppTextStyles.caption),
              ]),
            ),
            const SizedBox(height: 12),
            if (app.status == ApplicationStatus.pending)
              Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppColors.mustard.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)), child: Row(children: [const Icon(Icons.schedule, size: 20, color: AppColors.mustard), const SizedBox(width: 8), Expanded(child: Text('Menunggu Kurasi — tim kami sedang mengkurasi karyamu (3–5 hari kerja).', style: AppTextStyles.body.copyWith(height: 1.375)))]))
            else if (app.status == ApplicationStatus.approved)
              Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppColors.moss.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)), child: Center(child: Column(children: [const Icon(Icons.check_circle_outline, size: 24, color: AppColors.moss), const SizedBox(height: 8), Text('Selamat! Pengajuanmu diterima.', style: AppTextStyles.h3, textAlign: TextAlign.center), const SizedBox(height: 12), PrimaryButton(label: 'Buka Dashboard Kreator', fullWidth: false, verticalPadding: 10, fontSize: 13, onPressed: () => context.push('/dashboard-kreator'))])))
            else
              Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppColors.destructive.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)), child: SizedBox(width: double.infinity, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Icon(Icons.block, size: 24, color: AppColors.destructive), const SizedBox(height: 8), Text('Pengajuan ditolak.', style: AppTextStyles.h3), if (app.rejectReason != null) ...[const SizedBox(height: 4), Text(app.rejectReason!, style: AppTextStyles.body.copyWith(fontSize: 13, height: 1.375))], const SizedBox(height: 12), SecondaryButton(label: 'Ajukan Ulang', fullWidth: false, verticalPadding: 10, fontSize: 13, onPressed: () => context.push('/daftar-kreator'))]))),
            if (app.status == ApplicationStatus.pending) ...[
              const SizedBox(height: 12),
              SecondaryButton(
                label: '[Demo] Simulasikan Hasil Kurasi',
                onPressed: () => _showSimulateDialog(context, app),
                icon: const Icon(Icons.science_outlined, size: 18),
                verticalPadding: 12,
                fontSize: 13,
              ),
            ],
          ]),
        ),
      ),
    );
  }

  void _showSimulateDialog(BuildContext context, CreatorApplicationModel app) {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        // Handler dipindahkan apa adanya (tanpa perubahan logika).
        Future<void> onReject() async {
              const reason = 'Maaf, karya belum memenuhi kriteria kurasi kami saat ini. Silakan ajukan ulang dengan referensi yang lebih matang.';
              await context.read<ApplicationsProvider>().updateStatus(
                app.id,
                ApplicationStatus.rejected,
                rejectReason: reason,
              );
              if (context.mounted) {
                context.read<NotificationsProvider>().addNotification(
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
        }

        Future<void> onApprove() async {
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
                context.read<NotificationsProvider>().addNotification(
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
        }

        final initials = app.applicantName
            .split(' ')
            .where((w) => w.isNotEmpty)
            .map((w) => w[0])
            .take(2)
            .join()
            .toUpperCase();
        return AlertDialog(
          backgroundColor: AppColors.surface,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          actionsPadding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          title: null,
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Simulasi Hasil Kurasi', style: AppTextStyles.h3),
                const SizedBox(height: 16),
                Text(
                  'Pilih hasil simulasi kurasi tim (mode demo):',
                  style: AppTextStyles.bodyMuted.copyWith(fontSize: 13, height: 1.375),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(children: [
                    Container(
                      width: 48,
                      height: 48,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                      child: Text(
                        initials.isEmpty ? '?' : initials,
                        style: AppTextStyles.title.copyWith(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.onPrimary),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            app.applicantName,
                            style: AppTextStyles.title.copyWith(fontSize: 15, fontWeight: FontWeight.w700),
                          ),
                          Text(
                            'Brand: ${app.brandName}',
                            style: AppTextStyles.caption.copyWith(fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: 16),
                Text(
                  app.description,
                  style: AppTextStyles.body.copyWith(fontSize: 13, height: 1.375),
                ),
              ],
            ),
          ),
          actions: [
            Row(children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.of(dialogCtx).pop(),
                  style: TextButton.styleFrom(
                    backgroundColor: AppColors.background,
                    foregroundColor: AppColors.muted,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: const StadiumBorder(),
                    textStyle: GoogleFonts.baloo2(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  child: const Text('Batal'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: onReject,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.destructive,
                    backgroundColor: AppColors.surface,
                    side: BorderSide(color: AppColors.destructive.withValues(alpha: 0.3)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: const StadiumBorder(),
                    textStyle: GoogleFonts.baloo2(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                  child: const Text('Tolak'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: PrimaryButton(
                  label: 'Terima',
                  onPressed: onApprove,
                  verticalPadding: 10,
                  fontSize: 12,
                ),
              ),
            ]),
          ],
        );
      },
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
    return Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: bg.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(999)), child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: fg)));
  }
}
