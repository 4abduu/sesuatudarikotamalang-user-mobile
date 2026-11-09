import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
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
import 'creator_report_screen.dart' show formatReportMonth;

/// Detail laporan satu bulan. Rute yang disarankan: `/dashboard-kreator/laporan/:month`.
class CreatorReportDetailScreen extends StatefulWidget {
  final String month; // YYYY-MM
  const CreatorReportDetailScreen({super.key, required this.month});

  @override
  State<CreatorReportDetailScreen> createState() => _CreatorReportDetailScreenState();
}

class _CreatorReportDetailScreenState extends State<CreatorReportDetailScreen> {
  CreatorReport? _report;
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
      final res = await ApiClient.get('/artisans/mine/reports/${widget.month}');
      final raw = (res is Map<String, dynamic>) ? res['report'] : null;
      if (raw is! Map<String, dynamic>) {
        throw ApiException(404, 'Laporan tidak ditemukan');
      }
      if (!mounted) return;
      setState(() => _report = CreatorReport.fromJson(raw));
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _percentText(double v) => v == v.roundToDouble() ? '${v.toInt()}%' : '${v.toStringAsFixed(1)}%';

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final title = 'Laporan ${formatReportMonth(widget.month)}';

    if (!auth.isAuthenticated || !auth.isCreator) {
      return AppScaffold(
        title: title,
        body: Center(
          child: ElevatedButton(onPressed: () => context.go('/akun'), child: const Text('Kembali ke Akun')),
        ),
      );
    }

    if (_loading) {
      return AppScaffold(title: title, body: const Center(child: CircularProgressIndicator()));
    }

    final r = _report;
    if (_error != null || r == null) {
      return AppScaffold(
        title: title,
        body: ListView(children: [
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
        ]),
      );
    }

    return AppScaffold(
      title: title,
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            _card(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _row('Barang terjual', '${r.itemsSold} pcs'),
                _row('Omzet', formatRupiah(r.revenue)),
                _row('Persentase bagianmu', _percentText(r.sharePercent)),
                const Divider(color: AppColors.border, height: 20),
                _row('Bagianmu', formatRupiah(r.creatorShare), emphasize: true),
                _row('Bagian toko', formatRupiah(r.storeShare)),
              ]),
            ),
            const SizedBox(height: 16),
            Text('Penjualan', style: AppTextStyles.h3),
            const SizedBox(height: 8),
            if (r.sales.isEmpty)
              Text('Tidak ada penjualan pada bulan ini.', style: AppTextStyles.bodyMuted)
            else
              ...r.sales.map(
                (s) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _card(
                    child: Row(children: [
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(
                            s.productName,
                            style: GoogleFonts.baloo2(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.foreground,
                            ),
                          ),
                          Text(
                            '${(s.variantLabel ?? '').trim().isEmpty ? 'Tanpa varian' : s.variantLabel} · ${s.quantity} x ${formatRupiah(s.price)}',
                            style: AppTextStyles.caption,
                          ),
                        ]),
                      ),
                      Text(formatRupiah(s.revenue), style: AppTextStyles.price),
                    ]),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Text('Sisa stok', style: AppTextStyles.h3),
            const SizedBox(height: 8),
            if (r.stock.isEmpty)
              Text('Tidak ada data stok.', style: AppTextStyles.bodyMuted)
            else
              ...r.stock.map(
                (s) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _card(
                    child: Row(children: [
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(
                            s.productName,
                            style: GoogleFonts.baloo2(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.foreground,
                            ),
                          ),
                          Text(
                            (s.variantLabel ?? '').trim().isEmpty ? 'Tanpa varian' : s.variantLabel!,
                            style: AppTextStyles.caption,
                          ),
                        ]),
                      ),
                      Text('${s.stock} pcs', style: AppTextStyles.label),
                    ]),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Text(
              'Laporan hanya mencakup penjualan lewat aplikasi, tidak termasuk penjualan di kasir.',
              style: AppTextStyles.caption,
            ),
          ],
        ),
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.soft,
      ),
      child: child,
    );
  }

  Widget _row(String label, String value, {bool emphasize = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: AppTextStyles.bodyMuted),
        Text(value, style: emphasize ? AppTextStyles.price : AppTextStyles.label),
      ]),
    );
  }
}

