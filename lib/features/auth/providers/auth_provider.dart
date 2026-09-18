import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
    } catch (_) {}
    _hydrated = true;
    notifyListeners();
  }

  Future<void> login(UserModel user) async {
    _user = user;
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_key, jsonEncode(user.toJson()));
    notifyListeners();
  }

  Future<void> logout() async {
    _user = null;
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_key);
    notifyListeners();
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

  void updateProfile({String? name, String? avatarUrl}) {
    if (_user == null) return;
    _user = _user!.copyWith(name: name ?? _user!.name, avatarUrl: avatarUrl ?? _user!.avatarUrl);
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
