import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../data/models/creator_report_model.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../shared/app_scaffold.dart';

/// Format "2026-10" menjadi "Oktober 2026".
String formatReportMonth(String month) {
  final parts = month.split('-');
  if (parts.length != 2) return month;
  final y = int.tryParse(parts[0]);
  final m = int.tryParse(parts[1]);
  if (y == null || m == null) return month;
  return DateFormat('MMMM yyyy', 'id_ID').format(DateTime(y, m));
}

/// Dashboard kreator → "Laporan Saya": daftar laporan bulanan yang sudah difinalkan admin.
/// Rute yang disarankan: `/dashboard-kreator/laporan`.
class CreatorReportScreen extends StatefulWidget {
  const CreatorReportScreen({super.key});

  @override
  State<CreatorReportScreen> createState() => _CreatorReportScreenState();
}

class _CreatorReportScreenState extends State<CreatorReportScreen> {
  List<CreatorReportSummary> _reports = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (mounted && auth.isAuthenticated && auth.isCreator) _load();
    });
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await ApiClient.get('/artisans/mine/reports');
      final raw = (res is Map<String, dynamic>) ? res['reports'] : null;
      final list = raw is List
          ? raw.whereType<Map<String, dynamic>>().map(CreatorReportSummary.fromJson).toList()
          : <CreatorReportSummary>[];
      if (!mounted) return;
      setState(() => _reports = list);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (!auth.isAuthenticated || !auth.isCreator) {
      return AppScaffold(
        title: 'Laporan Saya',
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.lock_outline, size: 48, color: AppColors.muted),
              const SizedBox(height: 12),
              Text('Akses khusus kreator', style: AppTextStyles.h2, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: () => context.go('/akun'), child: const Text('Kembali ke Akun')),
            ]),
          ),
        ),
      );
    }

    Widget content;
    if (_loading && _reports.isEmpty) {
      content = const Center(child: CircularProgressIndicator());
    } else if (_error != null && _reports.isEmpty) {
      content = ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 80),
          EmptyState(
            icon: Icons.error_outline,
            title: 'Laporan gagal dimuat',
            description: _error,
            action: OutlinedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Coba lagi'),
            ),
          ),
        ],
      );
    } else if (_reports.isEmpty) {
      content = ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 80),
          EmptyState(
            icon: Icons.description_outlined,
            title: 'Belum ada laporan',
            description: 'Laporan bulanan muncul di sini setelah admin memfinalkannya.',
          ),
        ],
      );
    } else {
      content = ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        itemCount: _reports.length + 1,
        itemBuilder: (_, idx) {
          if (idx == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'Laporan hanya mencakup penjualan lewat aplikasi, tidak termasuk penjualan di kasir.',
                style: AppTextStyles.caption,
              ),
            );
          }
          final r = _reports[idx - 1];
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => context.push('/dashboard-kreator/laporan/${r.month}'),
              child: Container(
                padding: const EdgeInsets.all(14),
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
                      color: AppColors.moss.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.bar_chart, color: AppColors.moss, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(
                        formatReportMonth(r.month),
                        style: GoogleFonts.baloo2(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.foreground,
                        ),
                      ),
                      Text(
                        '${r.itemsSold} pcs terjual · bagianmu ${formatRupiah(r.creatorShare)}',
                        style: AppTextStyles.caption,
                      ),
                    ]),
                  ),
                  const Icon(Icons.chevron_right, color: AppColors.muted),
                ]),
              ),
            ),
          );
        },
      );
    }

    return AppScaffold(
      title: 'Laporan Saya',
      body: RefreshIndicator(onRefresh: _load, child: content),
    );
  }
}

