import 'package:flutter/foundation.dart';
import '../../../core/network/api_exception.dart';
import 'auth_view_model.dart';

class ForgotPasswordViewModel extends ChangeNotifier {
  ForgotPasswordViewModel(this._auth);
  final AuthViewModel _auth;
  bool _isSubmitting = false;
  String? _errorMessage;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;

  Future<bool> requestCode(String email) =>
      _run(() => _auth.requestForgotPassword(email));

  Future<bool> reset(
          {required String email,
          required String code,
          required String newPassword}) =>
      _run(() => _auth.verifyForgotPassword(
          email: email, code: code, newPassword: newPassword));

  Future<bool> _run(Future<void> Function() action) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await action();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }
}
