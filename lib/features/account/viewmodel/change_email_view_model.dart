import 'package:flutter/foundation.dart';
import '../../auth/viewmodel/auth_view_model.dart';

class ChangeEmailViewModel extends ChangeNotifier {
  ChangeEmailViewModel(this._auth)
      : _oldEmail = _auth.user?.email ?? '', _userId = _auth.user?.id;
  final AuthViewModel _auth;
  final String? _userId;
  String _oldEmail;
  bool _otpSent = false;
  bool _isLoading = false;
  bool _disposed = false;
  String? _actionError;
  String get oldEmail => _oldEmail;
  bool get otpSent => _otpSent;
  bool get isLoading => _isLoading;
  String? get actionError => _actionError;
  bool get _active => !_disposed && _userId != null && _auth.user?.id == _userId;

  Future<bool> request(String value) async {
    if (!_active || _isLoading) return false;
    final email = value.trim();
    _actionError = null;
    if (email.isEmpty) {
      _actionError = 'Isi email baru terlebih dahulu';
    } else if (email.toLowerCase() == _oldEmail.toLowerCase()) {
      _actionError = 'Email baru harus berbeda dari email saat ini';
    }
    if (_actionError != null) { _notify(); return false; }
    _isLoading = true;
    _notify();
    try {
      await _auth.requestChangeEmail(email);
      if (!_active) return false;
      _otpSent = true;
      return true;
    } catch (e) {
      if (_active) _actionError = e.toString();
      return false;
    } finally { _isLoading = false; _notify(); }
  }

  Future<bool> verify(String value) async {
    if (!_active || _isLoading || !_otpSent) return false;
    _actionError = null;
    final code = value.trim();
    if (code.isEmpty) {
      _actionError = 'Masukkan kode OTP';
      _notify();
      return false;
    }
    _isLoading = true;
    _notify();
    try {
      await _auth.verifyChangeEmail(code);
      if (!_active) return false;
      _otpSent = false;
      _oldEmail = _auth.user?.email ?? '';
      return true;
    } catch (e) {
      if (_active) _actionError = e.toString();
      return false;
    } finally { _isLoading = false; _notify(); }
  }

  void _notify() { if (!_disposed) notifyListeners(); }
  @override
  void dispose() { _disposed = true; super.dispose(); }
}
