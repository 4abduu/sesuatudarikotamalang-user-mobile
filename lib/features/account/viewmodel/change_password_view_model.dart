import 'package:flutter/foundation.dart';
import '../../../core/utils/password_validator.dart';
import '../../auth/viewmodel/auth_view_model.dart';

class ChangePasswordViewModel extends ChangeNotifier {
  ChangePasswordViewModel(this._auth) : _userId = _auth.user?.id;
  final AuthViewModel _auth;
  final String? _userId;
  bool _isLoading = false;
  bool _disposed = false;
  String? _actionError;
  bool get isLoading => _isLoading;
  String? get actionError => _actionError;
  bool get _active => !_disposed && _userId != null && _auth.user?.id == _userId;

  Future<bool> save({required String oldPassword, required String newPassword,
    required String confirmation}) async {
    if (!_active || _isLoading) return false;
    _actionError = null;
    if (!validatePassword(newPassword).isValid) {
      _actionError = 'Password belum memenuhi kriteria';
    } else if (newPassword != confirmation) {
      _actionError = 'Konfirmasi password tidak sama';
    }
    if (_actionError != null) { _notify(); return false; }
    _isLoading = true;
    _notify();
    try {
      await _auth.changePasswordApi(oldPassword: oldPassword, newPassword: newPassword);
      return _active;
    } catch (e) {
      if (_active) _actionError = e.toString();
      return false;
    } finally { _isLoading = false; _notify(); }
  }

  void _notify() { if (!_disposed) notifyListeners(); }
  @override
  void dispose() { _disposed = true; super.dispose(); }
}
