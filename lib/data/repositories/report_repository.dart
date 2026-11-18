import '../../core/network/api_exception.dart';
import '../../core/network/api_service.dart';
import '../models/creator_report_model.dart';

class ReportRepository {
  ReportRepository(this._api);
  final ApiService _api;

  Future<List<CreatorReportSummary>> getReports() async {
    final res = await _api.get('/artisans/mine/reports');
    final raw = res is Map<String, dynamic> ? res['reports'] : null;
    return raw is List
        ? raw.whereType<Map<String, dynamic>>().map(CreatorReportSummary.fromJson).toList()
        : <CreatorReportSummary>[];
  }

  Future<CreatorReport> getReport(String month) async {
    final res = await _api.get('/artisans/mine/reports/$month');
    final raw = res is Map<String, dynamic> ? res['report'] : null;
    if (raw is! Map<String, dynamic>) {
      throw ApiException(404, 'Laporan tidak ditemukan');
    }
    return CreatorReport.fromJson(raw);
  }
}
