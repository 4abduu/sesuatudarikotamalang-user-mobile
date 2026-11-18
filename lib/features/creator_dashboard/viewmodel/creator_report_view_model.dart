import 'package:flutter/foundation.dart';
import '../../../data/models/creator_report_model.dart';
import '../../../data/repositories/report_repository.dart';

class CreatorReportViewModel extends ChangeNotifier {
  CreatorReportViewModel(this._repository);
  final ReportRepository _repository;
  
  List<CreatorReportSummary> _reports = [];
  List<CreatorReportSummary> get reports => List.unmodifiable(_reports);
  bool _isLoading = true;
  bool get isLoading => _isLoading;
  String? _errorMessage;
  String? get errorMessage => _errorMessage;
  bool _disposed = false;
  int _requestId = 0;

  Future<void> load() async {
    if (_disposed) return;
    final id = ++_requestId;
    _isLoading = true;
    _errorMessage = null;
    _notify();
    try {
      final result = await _repository.getReports();
      if (_disposed || id != _requestId) return;
      _reports = result;
    } catch (e) {
      if (_disposed || id != _requestId) return;
      _errorMessage = e.toString();
    } finally {
      if (!_disposed && id == _requestId) {
        _isLoading = false;
        _notify();
      }
    }
  }

  void _notify() { if (!_disposed) notifyListeners(); }
  @override
  void dispose() { _disposed = true; ++_requestId; super.dispose(); }
}
