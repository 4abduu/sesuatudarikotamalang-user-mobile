import 'package:shared_preferences/shared_preferences.dart';

abstract class TokenStorage {
  Future<String?> getToken();
  Future<void> saveToken(String token);
  Future<void> removeToken();
}

class SharedPrefsTokenStorage implements TokenStorage {
  static const String key = 'sdkm_auth_token';

  @override
  Future<String?> getToken() async => (await SharedPreferences.getInstance()).getString(key);

  @override
  Future<void> saveToken(String token) async => (await SharedPreferences.getInstance()).setString(key, token);

  @override
  Future<void> removeToken() async => (await SharedPreferences.getInstance()).remove(key);
}
