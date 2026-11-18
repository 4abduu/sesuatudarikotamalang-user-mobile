import 'package:flutter/foundation.dart';
import '../../../data/models/creator_application_model.dart';
import '../../../data/repositories/application_repository.dart';
import '../../auth/viewmodel/auth_view_model.dart';

class ApplicationStatusViewModel extends ChangeNotifier {
  ApplicationStatusViewModel(this._repository, this._auth) : _userId = _auth.user?.id {
    _auth.addListener(_onAuthChanged);
  }
  final ApplicationRepository _repository;
  final AuthViewModel _auth;
  String? _userId;
  List<CreatorApplicationModel> _applications = [];
  bool _isLoading = false;
  bool _disposed = false;
  int _requestId = 0;
  String? _errorMessage;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  CreatorApplicationModel? get application {
    final mine = _applications.where((a) => a.userId == _userId || _userId == '').toList()
      ..sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
    return mine.isEmpty ? null : mine.first;
  }

  void _onAuthChanged() {
    if (_auth.user?.id == _userId) return;
    _userId = _auth.user?.id;
    _requestId++;
    _applications = [];
    _errorMessage = null;
    _isLoading = false;
    _notify();
  }

  Future<void> load() async {
    if (_disposed || _userId == null) return;
    final id = ++_requestId;
    _isLoading = true;
    _errorMessage = null;
    _notify();
    await Future.wait([_loadApplications(id), _auth.refreshMe()]);
    if (_disposed || id != _requestId) return;
    _isLoading = false;
    _notify();
  }

  Future<void> _loadApplications(int id) async {
    try {
      final items = await _repository.getMine();
      if (!_disposed && id == _requestId) _applications = items;
    } catch (e) {
      if (!_disposed && id == _requestId) _errorMessage = e.toString();
    }
  }
  void _notify() { if (!_disposed) notifyListeners(); }
  @override
  void dispose() { _disposed = true; _auth.removeListener(_onAuthChanged); super.dispose(); }
}
