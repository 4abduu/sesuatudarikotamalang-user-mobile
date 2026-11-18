import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'api_exception.dart';
import 'token_storage.dart';

class ApiService {
  ApiService({
    required this.baseUrl,
    required this.tokenStorage,
    http.Client? client,
    this.timeout = const Duration(seconds: 15),
  }) : _client = client ?? http.Client();

  final String baseUrl;
  final TokenStorage tokenStorage;
  final http.Client _client;
  final Duration timeout;
  void Function()? onUnauthorized;

  Uri _buildUri(String path, [Map<String, dynamic>? query]) {
    final cleanPath = path.startsWith('/') ? path : '/$path';
    final uri = Uri.parse('$baseUrl$cleanPath');
    if (query == null || query.isEmpty) return uri;
    return uri.replace(queryParameters: query.map((k, v) => MapEntry(k, v.toString())));
  }

  Future<Map<String, String>> _headers([bool isJson = true]) async {
    final headers = <String, String>{};
    if (isJson) headers['Content-Type'] = 'application/json';
    final token = await tokenStorage.getToken();
    if (token != null && token.isNotEmpty) headers['Authorization'] = 'Bearer $token';
    return headers;
  }

  dynamic handleResponse(http.Response response) {
    dynamic decoded;
    try {
      if (response.body.isNotEmpty) decoded = jsonDecode(response.body);
    } catch (_) {}
    final status = response.statusCode;
    if (status >= 200 && status < 300) return decoded;
    if (status == 401) {
      unawaited(tokenStorage.removeToken());
      onUnauthorized?.call();
    }
    String message;
    String? code;
    Map<String, dynamic>? data;
    if (decoded is Map<String, dynamic>) {
      final requestId = decoded['requestId'] as String?;
      message = status >= 500
          ? (requestId != null && requestId.isNotEmpty ? 'Terjadi kesalahan pada server. Kode: $requestId' : 'Terjadi kesalahan pada server')
          : (decoded['error'] ?? decoded['message'] ?? 'Request gagal').toString();
      code = decoded['code'] as String?;
      data = decoded;
    } else {
      message = status >= 500 ? 'Terjadi kesalahan pada server' : 'Request gagal ($status)';
    }
    throw ApiException(status, message, code, data);
  }

  Future<T> _request<T>(Future<T> Function() request, {bool retryOnce = false}) async {
    for (var attempt = 0; ; attempt++) {
      try {
        return await request().timeout(timeout);
      } on TimeoutException {
        if (retryOnce && attempt == 0) continue;
        throw ApiException(0, 'Koneksi ke server terlalu lama. Coba lagi.', 'TIMEOUT');
      } on http.ClientException {
        if (retryOnce && attempt == 0) {
          await Future<void>.delayed(const Duration(milliseconds: 250));
          continue;
        }
        throw ApiException(0, 'Tidak dapat terhubung ke server. Periksa koneksi internet.', 'NETWORK_ERROR');
      }
    }
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) async =>
      handleResponse(await _request(
        () async => _client.get(_buildUri(path, query), headers: await _headers()),
        retryOnce: true,
      ));

  Future<dynamic> post(String path, {Map<String, dynamic>? body}) async =>
      handleResponse(await _request(() async => _client.post(_buildUri(path), headers: await _headers(), body: body == null ? null : jsonEncode(body))));

  Future<dynamic> put(String path, {Map<String, dynamic>? body}) async =>
      handleResponse(await _request(() async => _client.put(_buildUri(path), headers: await _headers(), body: body == null ? null : jsonEncode(body))));

  Future<dynamic> patch(String path, {Map<String, dynamic>? body}) async =>
      handleResponse(await _request(() async => _client.patch(_buildUri(path), headers: await _headers(), body: body == null ? null : jsonEncode(body))));

  Future<dynamic> delete(String path, {Map<String, dynamic>? body}) async =>
      handleResponse(await _request(() async => _client.delete(_buildUri(path), headers: await _headers(), body: body == null ? null : jsonEncode(body))));

  Future<dynamic> postMultipart(String path, {required List<http.MultipartFile> files, Map<String, String>? fields}) async {
    final request = http.MultipartRequest('POST', _buildUri(path));
    final headers = await _headers(false);
    request.headers.addAll(headers);
    if (fields != null) request.fields.addAll(fields);
    request.files.addAll(files);
    return handleResponse(await _request(
      () async => http.Response.fromStream(await _client.send(request)),
    ));
  }
}
