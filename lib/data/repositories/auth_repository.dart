import '../../core/network/api_service.dart';
import '../../core/network/token_storage.dart';
import '../models/user_model.dart';
import '../services/google_auth_service.dart';
import '../services/session_store.dart';

class AuthRepository {
  AuthRepository(this._api, this._tokens, this._session, {GoogleAuthService? google}) : _google = google ?? GoogleAuthService();
  final ApiService _api;
  final TokenStorage _tokens;
  final SessionStore _session;
  final GoogleAuthService _google;

  Future<UserModel> me() async => UserModel.fromJson((await _api.get('/auth/me'))['user']);

  Future<void> register({required String name, required String email, required String password}) async {
    await _api.post('/auth/register', body: {'name': name, 'email': email, 'password': password});
    await clearLocalSession();
  }

  Future<UserModel> login({required String email, required String password}) async => _saveLogin(
        await _api.post('/auth/login', body: {'email': email, 'password': password}),
      );

  Future<UserModel> loginWithGoogle() async => _saveLogin(
        await _api.post('/auth/google', body: {'idToken': await _google.signIn()}),
      );

  Future<void> logout() async {
    try { await _api.post('/auth/logout'); } catch (_) {}
    await clearLocalSession();
  }

  Future<UserModel> updateProfile({String? name, String? avatarUrl, bool removeAvatar = false}) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (removeAvatar) {
      body['avatarUrl'] = null;
    } else if (avatarUrl != null) {
      body['avatarUrl'] = avatarUrl;
    }
    final user = UserModel.fromJson((await _api.put('/auth/profile', body: body))['user']);
    await _session.saveUser(user);
    return user;
  }

  Future<void> requestForgotPassword(String email) async => _api.post('/auth/forgot-password/request', body: {'email': email});
  Future<void> verifyForgotPassword({required String email, required String code, required String newPassword}) async => _api.post('/auth/forgot-password/verify', body: {'email': email, 'code': code, 'newPassword': newPassword});
  Future<void> requestChangeEmail(String newEmail) async => _api.post('/auth/change-email/request', body: {'newEmail': newEmail});

  Future<String?> verifyChangeEmail(String code) async {
    final res = await _api.post('/auth/change-email/verify', body: {'code': code});
    final token = res?['token'] as String?;
    if (token != null) await _tokens.saveToken(token);
    return res?['email'] as String?;
  }

  Future<String?> changePassword({required String oldPassword, required String newPassword}) async {
    final res = await _api.post('/auth/change-password', body: {'oldPassword': oldPassword, 'newPassword': newPassword});
    final token = res?['token'] as String?;
    if (token != null) await _tokens.saveToken(token);
    return token;
  }

  Future<UserModel?> cachedUser() => _session.readUser();
  Future<bool> hasToken() async {
    final token = await _tokens.getToken();
    return token != null && token.isNotEmpty;
  }
  Future<void> saveCachedUser(UserModel user) => _session.saveUser(user);
  Future<void> clearLocalSession() async { await _tokens.removeToken(); await _session.removeUser(); }

  Future<UserModel> _saveLogin(dynamic response) async {
    final token = response['token'] as String;
    await _tokens.saveToken(token);
    final user = UserModel.fromJson(response['user']);
    await _session.saveUser(user);
    return user;
  }
}
