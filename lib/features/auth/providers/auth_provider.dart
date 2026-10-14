import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/config/google_config.dart';
import '../../../core/network/api_client.dart';
import '../../../data/models/user_model.dart';

const _demoUsers = <UserModel>[
  UserModel(id: 'u-buyer', name: 'Maya Anggraini', email: 'maya@email.com', password: 'buyer123', role: Role.buyer),
  UserModel(id: 'u-creator', name: 'Dini Aulia', email: 'dini.draws@gmail.com', password: 'creator123', role: Role.creator, creatorId: 'dini-aulia'),
];

class AuthProvider extends ChangeNotifier {
  UserModel? _user;
  bool _hydrated = false;

  UserModel? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isCreator => _user?.role == Role.creator;
  bool get isBuyer => _user?.role == Role.buyer;
  bool get hydrated => _hydrated;

  static const _key = 'sdkm-user-auth';

  Future<void> init() async {
    try {
      final sp = await SharedPreferences.getInstance();
      final raw = sp.getString(_key);
      if (raw != null) {
        _user = UserModel.fromJson(jsonDecode(raw));
      }
      
      // Ambil profil terbaru dari backend bila ada token
      final token = await ApiClient.getToken();
      if (token != null && token.isNotEmpty) {
        try {
          final res = await ApiClient.get('/auth/me');
          if (res != null && res['user'] != null) {
            _user = UserModel.fromJson(res['user']);
            await _persist();
          }
        } catch (e) {
          if (e is ApiException && e.status == 401) {
            _user = null;
            await sp.remove(_key);
          }
        }
      }
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
    final res = await ApiClient.post('/auth/register', body: {
      'name': name,
      'email': email,
      'password': password,
    });

    final token = res['token'] as String;
    await ApiClient.saveToken(token);
    _user = UserModel.fromJson(res['user']);
    await _persist();
    notifyListeners();
  }

  /// Login via email & password (POST /api/auth/login)
  Future<void> loginWithApi({
    required String email,
    required String password,
  }) async {
    final res = await ApiClient.post('/auth/login', body: {
      'email': email,
      'password': password,
    });

    final token = res['token'] as String;
    await ApiClient.saveToken(token);
    _user = UserModel.fromJson(res['user']);
    await _persist();
    notifyListeners();
  }

  /// Login via Google Sign-In (POST /api/auth/google {idToken})
  Future<void> loginWithGoogle() async {
    if (GoogleConfig.webClientId.isEmpty || GoogleConfig.webClientId.startsWith('GANTI')) {
      throw ApiException(
        0,
        'Google Client ID belum diisi. Silakan masukkan Client ID di lib/core/config/google_config.dart.',
      );
    }

    final googleSignIn = GoogleSignIn(
      clientId: kIsWeb ? GoogleConfig.webClientId : null,
      serverClientId: kIsWeb ? null : GoogleConfig.webClientId,
      scopes: ['email', 'profile'],
    );

    // Sign out dulu agar always show account picker
    await googleSignIn.signOut();
    final account = await googleSignIn.signIn();

    if (account == null) {
      // User membatalkan dialog pilih akun
      throw ApiException(0, 'Login Google dibatalkan');
    }

    final auth = await account.authentication;
    final idToken = auth.idToken;

    if (idToken == null) {
      throw ApiException(0, 'Gagal mendapatkan token Google. Pastikan Web Client ID sudah dikonfigurasi.');
    }

    final res = await ApiClient.post('/auth/google', body: {'idToken': idToken});
    final token = res['token'] as String;
    await ApiClient.saveToken(token);
    _user = UserModel.fromJson(res['user']);
    await _persist();
    notifyListeners();
  }

  /// Login mock/manual lokal untuk kompatibilitas UI demo
  Future<void> login(UserModel user) async {
    _user = user;
    await _persist();
    notifyListeners();
  }

  /// Logout (hapus token dan user)
  Future<void> logout() async {
    _user = null;
    await ApiClient.removeToken();
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_key);
    notifyListeners();
  }

  /// Update Profile (PUT /api/auth/profile)
  Future<void> updateProfile({String? name, String? avatarUrl}) async {
    try {
      final res = await ApiClient.put('/auth/profile', body: {
        if (name != null) 'name': name,
        if (avatarUrl != null) 'avatarUrl': avatarUrl,
      });
      if (res != null && res['user'] != null) {
        _user = UserModel.fromJson(res['user']);
        await _persist();
        notifyListeners();
        return;
      }
    } catch (_) {
      // Jika offline / gagal, fallback perbarui lokal
    }
    if (_user == null) return;
    _user = _user!.copyWith(
      name: name ?? _user!.name,
      avatarUrl: avatarUrl ?? _user!.avatarUrl,
    );
    notifyListeners();
    await _persist();
  }

  /// Request Forgot Password (POST /api/auth/forgot-password/request)
  Future<void> requestForgotPassword(String email) async {
    await ApiClient.post('/auth/forgot-password/request', body: {'email': email});
  }

  /// Verify Forgot Password (POST /api/auth/forgot-password/verify)
  Future<void> verifyForgotPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    await ApiClient.post('/auth/forgot-password/verify', body: {
      'email': email,
      'code': code,
      'newPassword': newPassword,
    });
  }

  /// Request Change Email (POST /api/auth/change-email/request)
  Future<void> requestChangeEmail(String newEmail) async {
    await ApiClient.post('/auth/change-email/request', body: {'newEmail': newEmail});
  }

  /// Verify Change Email (POST /api/auth/change-email/verify)
  Future<void> verifyChangeEmail(String code) async {
    final res = await ApiClient.post('/auth/change-email/verify', body: {'code': code});
    if (res != null && res['email'] != null && _user != null) {
      _user = _user!.copyWith(email: res['email']);
      await _persist();
      notifyListeners();
    }
  }

  /// Change Password (POST /api/auth/change-password)
  Future<void> changePasswordApi({
    required String oldPassword,
    required String newPassword,
  }) async {
    await ApiClient.post('/auth/change-password', body: {
      'oldPassword': oldPassword,
      'newPassword': newPassword,
    });
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

  void changePassword(String newPw) {
    if (_user == null) return;
    _user = _user!.copyWith(password: newPw);
    notifyListeners();
    _persist();
  }

  Future<void> _persist() async {
    if (_user == null) return;
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_key, jsonEncode(_user!.toJson()));
  }

  List<UserModel> get demoUsers => _demoUsers;
}
