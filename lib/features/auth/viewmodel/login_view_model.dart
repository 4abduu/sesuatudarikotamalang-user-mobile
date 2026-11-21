import 'package:flutter/foundation.dart';
import '../../../core/network/api_exception.dart';
import '../../../domain/auth/auth_validation_use_cases.dart';
import 'auth_view_model.dart';

class LoginViewModel extends ChangeNotifier {
  LoginViewModel(this._auth);
  final AuthViewModel _auth;
  final ValidateLoginUseCase _validate = ValidateLoginUseCase();
  bool _isSubmitting = false;
  String? _errorMessage;
  String? _errorCode;
  int? _errorStatus;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  String? get errorCode => _errorCode;
  int? get errorStatus => _errorStatus;

  Future<bool> login(String email, String password) {
    final validationError = _validate(email, password);
    if (validationError != null) {
      _errorMessage = validationError;
      notifyListeners();
      return Future.value(false);
    }
    return _run(() => _auth.loginWithApi(email: email, password: password));
  }

  Future<bool> loginWithGoogle() => _run(_auth.loginWithGoogle);

  Future<bool> _run(Future<void> Function() action) async {
    _isSubmitting = true;
    _errorMessage = null;
    _errorCode = null;
    _errorStatus = null;
    notifyListeners();
    try {
      await action();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _errorCode = e.code;
      _errorStatus = e.status;
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
