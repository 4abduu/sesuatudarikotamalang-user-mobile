import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sesuatu_darikota_malang/core/network/api_service.dart';
import 'package:sesuatu_darikota_malang/core/network/token_storage.dart';
import 'package:sesuatu_darikota_malang/data/models/user_model.dart';
import 'package:sesuatu_darikota_malang/data/repositories/auth_repository.dart';
import 'package:sesuatu_darikota_malang/data/services/session_store.dart';
import 'package:sesuatu_darikota_malang/features/auth/viewmodel/auth_view_model.dart';

class _Tokens implements TokenStorage {
  String? value;
  @override
  Future<String?> getToken() async => value;
  @override
  Future<void> saveToken(String token) async => value = token;
  @override
  Future<void> removeToken() async => value = null;
}

void main() {
  test('AuthRepository login mengirim body, menyimpan token dan cache user', () async {
    SharedPreferences.setMockInitialValues({});
    final tokens = _Tokens();
    final client = MockClient((request) async {
      expect(request.method, 'POST');
      expect(request.url.path, '/api/auth/login');
      expect(jsonDecode(request.body), {'email': 'a@b.test', 'password': 'rahasia'});
      return http.Response(jsonEncode({'token': 'jwt-uji', 'user': {'id': 'u1', 'name': 'A', 'email': 'a@b.test', 'role': 'buyer'}}), 200);
    });
    final repo = AuthRepository(
      ApiService(baseUrl: 'http://localhost/api', tokenStorage: tokens, client: client),
      tokens,
      SessionStore(),
    );
    final user = await repo.login(email: 'a@b.test', password: 'rahasia');
    expect(user.id, 'u1');
    expect(tokens.value, 'jwt-uji');
    expect((await repo.cachedUser())?.email, 'a@b.test');
  });

  test('SessionStore tidak menyimpan password user', () async {
    SharedPreferences.setMockInitialValues({});
    final store = SessionStore();
    await store.saveUser(const UserModel(id: 'u1', name: 'A', email: 'a@b.test', role: Role.buyer));
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(SessionStore.userKey), isNot(contains('password')));
  });

  test('AuthViewModel memulihkan cache lalu menerima role terbaru dari /auth/me', () async {
    SharedPreferences.setMockInitialValues({});
    final tokens = _Tokens()..value = 'jwt-uji';
    final repo = AuthRepository(
      ApiService(
        baseUrl: 'http://localhost/api',
        tokenStorage: tokens,
        client: MockClient((request) async {
          expect(request.url.path, '/api/auth/me');
          return http.Response(jsonEncode({'user': {'id': 'u1', 'name': 'A', 'email': 'a@b.test', 'role': 'creator', 'creatorId': 'c1'}}), 200);
        }),
      ),
      tokens,
      SessionStore(),
    );
    await repo.saveCachedUser(const UserModel(id: 'u1', name: 'A', email: 'a@b.test', role: Role.buyer));
    final vm = AuthViewModel(repository: repo);
    await vm.init();
    expect(vm.hydrated, isTrue);
    expect(vm.isCreator, isTrue);
    expect(vm.user?.creatorId, 'c1');
  });

  test('AuthViewModel membersihkan sesi saat /auth/me mengembalikan 401', () async {
    SharedPreferences.setMockInitialValues({});
    final tokens = _Tokens()..value = 'jwt-uji';
    final repo = AuthRepository(
      ApiService(baseUrl: 'http://localhost/api', tokenStorage: tokens, client: MockClient((_) async => http.Response('{"error":"Belum login"}', 401))),
      tokens,
      SessionStore(),
    );
    await repo.saveCachedUser(const UserModel(id: 'u1', name: 'A', email: 'a@b.test', role: Role.buyer));
    final vm = AuthViewModel(repository: repo);
    await vm.init();
    expect(vm.user, isNull);
    expect(tokens.value, isNull);
  });

  test('ApiService 401 membersihkan state AuthViewModel lewat callback global', () async {
    SharedPreferences.setMockInitialValues({});
    final tokens = _Tokens()..value = 'jwt-uji';
    final api = ApiService(
      baseUrl: 'http://localhost/api',
      tokenStorage: tokens,
      client: MockClient((_) async => http.Response('{"error":"Belum login"}', 401)),
    );
    final repo = AuthRepository(api, tokens, SessionStore());
    await repo.saveCachedUser(const UserModel(id: 'u1', name: 'A', email: 'a@b.test', role: Role.buyer));
    final vm = AuthViewModel(repository: repo);
    await vm.init();
    vm.handleUnauthorized();
    expect(vm.user, isNull);
    await Future<void>.delayed(Duration.zero);
    expect(await repo.cachedUser(), isNull);
  });
}
