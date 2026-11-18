import 'package:flutter/foundation.dart';
import '../../../core/network/api_exception.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/models/user_model.dart';

class AuthViewModel extends ChangeNotifier {
  AuthViewModel({required AuthRepository repository})
      : _repository = repository;

  final AuthRepository _repository;
  UserModel? _user;
  bool _hydrated = false;

  UserModel? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isCreator => _user?.role == Role.creator;
  bool get isBuyer => _user?.role == Role.buyer;
  bool get hydrated => _hydrated;

  /// Dipanggil ApiService ketika server menolak token dengan 401.
  /// Pembersihan token dilakukan ApiService; ViewModel membersihkan state UI
  /// dan cache user agar router segera menganggap sesi sudah berakhir.
  void handleUnauthorized() {
    _user = null;
    _repository.clearLocalSession();
    notifyListeners();
  }

  DateTime? _lastRefreshMeTime;

  /// Memperbarui data pengguna dari backend (GET /auth/me).
  /// Mengembalikan true bila role pengguna berubah, false bila tidak / gagal.
  Future<bool> refreshMe() async {
    if (!await _repository.hasToken()) return false;

    final oldRole = _user?.role;
    try {
      _user = await _repository.me();
      await _persist();
      notifyListeners();
      return oldRole != null && _user?.role != oldRole;
    } catch (e) {
      if (e is ApiException && e.status == 401) {
        _user = null;
        await _repository.clearLocalSession();
        notifyListeners();
      }
      // Kegagalan jaringan lain ditelan
    }
    return false;
  }

  /// Cek refreshMe dengan batas throttle 30 detik untuk lifecycle app
  Future<bool> refreshMeThrottled() async {
    if (!isAuthenticated) return false;
    final now = DateTime.now();
    if (_lastRefreshMeTime != null &&
        now.difference(_lastRefreshMeTime!).inSeconds < 30) {
      return false;
    }
    _lastRefreshMeTime = now;
    return await refreshMe();
  }

  Future<void> init() async {
    try {
      _user = await _repository.cachedUser();
      // Ambil profil terbaru dari backend bila ada token
      await refreshMe();
    } catch (_) {}
    _hydrated = true;
    notifyListeners();
  }

  /// Registrasi akun baru (POST /api/auth/register)
  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    await _repository.register(name: name, email: email, password: password);

    // Pendaftaran mengarahkan pengguna ke login; jangan membuka sesi otomatis.
    _user = null;
    await _repository.clearLocalSession();
    notifyListeners();
  }

  /// Login via email & password (POST /api/auth/login)
  Future<void> loginWithApi({
    required String email,
    required String password,
  }) async {
    _user = await _repository.login(email: email, password: password);
    await _persist();
    notifyListeners();
  }

  /// Login via Google Sign-In (POST /api/auth/google {idToken})
  Future<void> loginWithGoogle() async {
    _user = await _repository.loginWithGoogle();
    await _persist();
    notifyListeners();
  }

  /// Logout (panggil POST /api/auth/logout lalu hapus token dan user)
  Future<void> logout() async {
    await _repository.logout();
    _user = null;
    notifyListeners();
  }

  /// Update Profile (PUT /api/auth/profile)
  Future<void> updateProfile({
    String? name,
    String? avatarUrl,
    bool removeAvatar = false,
  }) async {
    _user = await _repository.updateProfile(
        name: name, avatarUrl: avatarUrl, removeAvatar: removeAvatar);
    notifyListeners();
  }

  /// Request Forgot Password (POST /api/auth/forgot-password/request)
  Future<void> requestForgotPassword(String email) async {
    await _repository.requestForgotPassword(email);
  }

  /// Verify Forgot Password (POST /api/auth/forgot-password/verify)
  Future<void> verifyForgotPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    await _repository.verifyForgotPassword(
        email: email, code: code, newPassword: newPassword);
  }

  /// Request Change Email (POST /api/auth/change-email/request)
  Future<void> requestChangeEmail(String newEmail) async {
    await _repository.requestChangeEmail(newEmail);
  }

  /// Verify Change Email (POST /api/auth/change-email/verify)
  Future<void> verifyChangeEmail(String code) async {
    final email = await _repository.verifyChangeEmail(code);
    if (email != null && _user != null) {
      _user = _user!.copyWith(email: email);
      await _persist();
      notifyListeners();
    }
  }

  /// Change Password (POST /api/auth/change-password)
  Future<void> changePasswordApi({
    required String oldPassword,
    required String newPassword,
  }) async {
    await _repository.changePassword(
        oldPassword: oldPassword, newPassword: newPassword);
  }

  void becomeCreator(String creatorId) {
    if (_user == null) return;
    _user = _user!.copyWith(role: Role.creator, creatorId: creatorId);
    notifyListeners();
    _persist();
  }

  void setApplication(String applicationId) {
    if (_user == null) return;
    _user = _user!.copyWith(applicationId: applicationId);
    notifyListeners();
    _persist();
  }

  void changeEmail(String newEmail) {
    if (_user == null) return;
    _user = _user!.copyWith(email: newEmail);
    notifyListeners();
    _persist();
  }

  Future<void> _persist() async {
    if (_user == null) return;
    await _repository.saveCachedUser(_user!);
  }
}
