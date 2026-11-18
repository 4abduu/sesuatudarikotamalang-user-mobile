import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sesuatu_darikota_malang/core/network/api_exception.dart';
import 'package:sesuatu_darikota_malang/core/network/api_service.dart';
import 'package:sesuatu_darikota_malang/core/network/token_storage.dart';
import 'package:sesuatu_darikota_malang/core/viewmodel/paged_state.dart';
import 'package:sesuatu_darikota_malang/data/services/upload_service.dart';

class _FakeTokenStorage implements TokenStorage {
  String? value;
  @override
  Future<String?> getToken() async => value;
  @override
  Future<void> saveToken(String token) async => value = token;
  @override
  Future<void> removeToken() async => value = null;
}

void main() {
  test('ApiService mengirim token, query, dan membaca JSON', () async {
    final storage = _FakeTokenStorage()..value = 'token-uji';
    final client = MockClient((request) async {
      expect(request.url.queryParameters['page'], '2');
      expect(request.headers['authorization'], 'Bearer token-uji');
      return http.Response('{"ok":true}', 200);
    });
    final api = ApiService(
        baseUrl: 'http://localhost/api', tokenStorage: storage, client: client);
    expect(await api.get('/items', query: {'page': 2}), {'ok': true});
  });

  test('ApiService 401 menghapus token dan memanggil callback', () async {
    final storage = _FakeTokenStorage()..value = 'kadaluarsa';
    var called = false;
    final api = ApiService(
      baseUrl: 'http://localhost/api',
      tokenStorage: storage,
      client: MockClient(
          (_) async => http.Response('{"error":"Belum login"}', 401)),
    )..onUnauthorized = () => called = true;
    await expectLater(api.get('/private'), throwsA(isA<ApiException>()));
    expect(storage.value, isNull);
    expect(called, isTrue);
  });

  test('PagedState mereset load-more ketika filter memulai halaman baru', () {
    final state = PagedState<String>(limit: 12);
    final first = state.beginFirstPage();
    state.isLoadingMore = true;
    final second = state.beginFirstPage();
    expect(state.isLoadingMore, isFalse);
    expect(state.isStale(first), isTrue);
    expect(state.isStale(second), isFalse);
  });

  test('UploadService memecah batch dan rollback URL batch pertama', () async {
    final storage = _FakeTokenStorage();
    var multipleCalls = 0;
    final deleted = <String>[];
    final client = MockClient((request) async {
      if (request.method == 'DELETE') {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        deleted.add(body['url'] as String);
        return http.Response('{}', 200);
      }
      multipleCalls++;
      if (multipleCalls == 1) {
        return http.Response(
            jsonEncode(
                {'urls': List.generate(10, (i) => 'https://cdn.test/$i')}),
            200);
      }
      return http.Response('{"error":"gagal"}', 500);
    });
    final service = UploadService(ApiService(
        baseUrl: 'http://localhost/api',
        tokenStorage: storage,
        client: client));
    final files = List.generate(
        11,
        (i) => XFile.fromData(Uint8List.fromList([0xFF, 0xD8, 0xFF, i]),
            name: '$i.jpg', mimeType: 'image/jpeg'));
    await expectLater(service.uploadMany(files), throwsA(isA<ApiException>()));
    expect(multipleCalls, 2);
    expect(deleted, hasLength(10));
  });

  test('UploadService uploadOne memakai endpoint unggah tunggal', () async {
    final client = MockClient((request) async {
      expect(request.url.path, '/api/upload/single');
      return http.Response(
          jsonEncode({'url': 'https://cdn.test/avatar.jpg'}), 200);
    });
    final service = UploadService(ApiService(
      baseUrl: 'http://localhost/api',
      tokenStorage: _FakeTokenStorage(),
      client: client,
    ));
    final file = XFile.fromData(
      Uint8List.fromList([0xFF, 0xD8, 0xFF]),
      name: 'avatar.jpg',
      mimeType: 'image/jpeg',
    );
    expect(await service.uploadOne(file), 'https://cdn.test/avatar.jpg');
  });
}
