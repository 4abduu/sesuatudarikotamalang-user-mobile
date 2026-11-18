import 'package:flutter/foundation.dart';
import '../../../data/models/creator_report_model.dart';
import '../../../data/repositories/report_repository.dart';

class CreatorReportDetailViewModel extends ChangeNotifier {
  CreatorReportDetailViewModel(this._repository, {required this.month});
  final ReportRepository _repository;
  final String month;
  CreatorReport? _report;
  CreatorReport? get report => _report;
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
      final result = await _repository.getReport(month);
      if (_disposed || id != _requestId) return;
      _report = result;
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
