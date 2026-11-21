import '../../core/utils/password_validator.dart';

class ValidateLoginUseCase {
  String? call(String email, String password) {
    if (email.trim().isEmpty || password.trim().isEmpty) {
      return 'Isi email dan password dulu ya';
    }
    return null;
  }
}

class ValidateRegisterUseCase {
  String? call(String name, String email, String password, String confirmation) {
    final result = validatePassword(password);
    if (name.trim().isEmpty || email.trim().isEmpty || !result.isValid || password != confirmation) {
      return 'Periksa kembali isianmu ya';
    }
    return null;
  }
}
