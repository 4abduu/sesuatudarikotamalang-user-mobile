import '../../core/utils/password_validator.dart';

class ValidateLoginUseCase {
  String? call(String email, String password) {
    if (email.trim().isEmpty) return 'Email wajib diisi';
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email.trim())) return 'Format email tidak valid. Contoh: nama@email.com';
    if (password.isEmpty) return 'Password wajib diisi';
    return null;
  }
}

class ValidateRegisterUseCase {
  String? call(String name, String email, String password, String confirmation) {
    if (name.trim().isEmpty) return 'Nama lengkap wajib diisi';
    if (email.trim().isEmpty) return 'Email wajib diisi';
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email.trim())) return 'Format email tidak valid. Contoh: nama@email.com';
    final result = validatePassword(password);
    if (!result.isValid) return 'Password belum memenuhi semua kriteria keamanan';
    if (password != confirmation) return 'Konfirmasi password tidak sama';
    return null;
  }
}
