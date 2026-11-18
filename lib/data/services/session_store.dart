import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class SessionStore {
  static const userKey = 'sdkm-user-auth';

  Future<UserModel?> readUser() async {
    final raw = (await SharedPreferences.getInstance()).getString(userKey);
    if (raw == null) return null;
    try {
      return UserModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveUser(UserModel user) async =>
      (await SharedPreferences.getInstance()).setString(userKey, jsonEncode(user.toJson()));

  Future<void> removeUser() async => (await SharedPreferences.getInstance()).remove(userKey);
}
