import 'package:flutter/foundation.dart';
import '../../../core/network/api_exception.dart';
import '../../../domain/auth/auth_validation_use_cases.dart';
import 'auth_view_model.dart';

class RegisterViewModel extends ChangeNotifier {
  RegisterViewModel(this._auth);
  final AuthViewModel _auth;
  final ValidateRegisterUseCase _validate = ValidateRegisterUseCase();
  bool _isSubmitting = false;
  String? _errorMessage;
  String? _errorCode;
  int? _errorStatus;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  String? get errorCode => _errorCode;
  int? get errorStatus => _errorStatus;

  Future<bool> register(
      {required String name,
      required String email,
      required String password,
      required String confirmation}) async {
    final validationError = _validate(name, email, password, confirmation);
    if (validationError != null) {
      _errorMessage = validationError;
      notifyListeners();
      return false;
    }
    _isSubmitting = true;
    _errorMessage = null;
    _errorCode = null;
    _errorStatus = null;
    notifyListeners();
    try {
      await _auth.register(name: name, email: email, password: password);
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

  Future<bool> registerWithGoogle() async {
    _isSubmitting = true;
    _errorMessage = null;
    _errorCode = null;
    _errorStatus = null;
    notifyListeners();
    try {
      await _auth.loginWithGoogle();
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
