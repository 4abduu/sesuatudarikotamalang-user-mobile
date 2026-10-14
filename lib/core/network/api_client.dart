import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_config.dart';

class ApiException implements Exception {
  final int status;
  final String message;
  final String? code;
  final Map<String, dynamic>? data;

  ApiException(this.status, this.message, [this.code, this.data]);

  @override
  String toString() => message;
}

class ApiClient {
  static const String tokenKey = 'sdkm_auth_token';

  // Callback opsional untuk menangani redirect ke login saat 401
  static void Function()? onUnauthorized;

  static Future<String?> getToken() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getString(tokenKey);
  }

  static Future<void> saveToken(String token) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(tokenKey, token);
  }

  static Future<void> removeToken() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(tokenKey);
  }

  static Uri _buildUri(String path, [Map<String, dynamic>? queryParameters]) {
    final cleanPath = path.startsWith('/') ? path : '/$path';
    final fullUrl = '${ApiConfig.fullBaseUrl}$cleanPath';
    final uri = Uri.parse(fullUrl);
    if (queryParameters != null && queryParameters.isNotEmpty) {
      final sanitizedParams = queryParameters.map((k, v) => MapEntry(k, v.toString()));
      return uri.replace(queryParameters: sanitizedParams);
    }
    return uri;
  }

  static Future<Map<String, String>> _headers([bool isJson = true]) async {
    final headers = <String, String>{};
    if (isJson) {
      headers['Content-Type'] = 'application/json';
    }
    final token = await getToken();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  static dynamic _handleResponse(http.Response response) {
    dynamic decoded;
    try {
      if (response.body.isNotEmpty) {
        decoded = jsonDecode(response.body);
      }
    } catch (_) {
      decoded = null;
    }

    final status = response.statusCode;
    if (status >= 200 && status < 300) {
      return decoded;
    }

    if (status == 401) {
      removeToken();
      onUnauthorized?.call();
    }

    String message;
    String? code;
    Map<String, dynamic>? extraData;

    if (decoded is Map<String, dynamic>) {
      message = (status >= 500)
          ? 'Terjadi kesalahan pada server'
          : (decoded['error'] ?? decoded['message'] ?? 'Request gagal');
      code = decoded['code'] as String?;
      extraData = decoded;
    } else {
      message = status >= 500 ? 'Terjadi kesalahan pada server' : 'Request gagal ($status)';
    }

    throw ApiException(status, message, code, extraData);
  }

  static Future<dynamic> get(String path, {Map<String, dynamic>? queryParameters}) async {
    final uri = _buildUri(path, queryParameters);
    final headers = await _headers(true);
    final res = await http.get(uri, headers: headers);
    return _handleResponse(res);
  }

  static Future<dynamic> post(String path, {Map<String, dynamic>? body}) async {
    final uri = _buildUri(path);
    final headers = await _headers(true);
    final res = await http.post(
      uri,
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(res);
  }

  static Future<dynamic> put(String path, {Map<String, dynamic>? body}) async {
    final uri = _buildUri(path);
    final headers = await _headers(true);
    final res = await http.put(
      uri,
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(res);
  }

  static Future<dynamic> patch(String path, {Map<String, dynamic>? body}) async {
    final uri = _buildUri(path);
    final headers = await _headers(true);
    final res = await http.patch(
      uri,
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(res);
  }

  static Future<dynamic> delete(String path, {Map<String, dynamic>? body}) async {
    final uri = _buildUri(path);
    final headers = await _headers(true);
    final res = await http.delete(
      uri,
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(res);
  }

  static Future<dynamic> uploadMultipart({
    required String path,
    required String fileField,
    required String filePath,
    Map<String, String>? fields,
  }) async {
    final uri = _buildUri(path);
    final request = http.MultipartRequest('POST', uri);
    final token = await getToken();
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    if (fields != null) {
      request.fields.addAll(fields);
    }
    request.files.add(await http.MultipartFile.fromPath(fileField, filePath));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    return _handleResponse(response);
  }
}
