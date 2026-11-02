import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import '../utils/photo_rules.dart';
import 'api_client.dart';
import 'api_config.dart';

/// Unggah dan hapus berkas ke backend (API_CONTRACT v1.7, Bagian 8).
///
/// Berbeda dari `ApiClient.uploadMultipart`: nama field benar (`file` /
/// `files`), Content-Type dikirim eksplisit dari byte awal berkas (bukan dari
/// ekstensi), dan berkas dibaca sebagai byte sehingga aman di Flutter Web.
class UploadApi {
  UploadApi._();

  /// Unggah satu foto, mengembalikan URL-nya.
  static Future<String> uploadOne(XFile file) async {
    final urls = await _post('/upload/single', 'file', [file]);
    return urls.first;
  }

  /// Unggah banyak foto (dipecah per 10 berkas). URL dikembalikan dengan
  /// urutan yang sama dengan [files]. Bila satu panggilan gagal, URL yang
  /// sudah terunggah pada panggilan sebelumnya dihapus (best effort) lalu
  /// galat dilempar ulang.
  static Future<List<String>> uploadMany(List<XFile> files) async {
    if (files.isEmpty) return <String>[];
    final urls = <String>[];
    try {
      for (var i = 0; i < files.length; i += PhotoRules.maxPerCall) {
        final end = (i + PhotoRules.maxPerCall > files.length) ? files.length : i + PhotoRules.maxPerCall;
        urls.addAll(await _post('/upload/multiple', 'files', files.sublist(i, end)));
      }
    } catch (_) {
      if (urls.isNotEmpty) await deleteUrls(urls);
      rethrow;
    }
    return urls;
  }

  /// Hapus unggahan yang belum terpasang (untuk rollback). Best effort:
  /// kegagalan diabaikan. JANGAN dipakai untuk foto yang sudah terpasang di
  /// produk/profil, karena backend yang menghapus file itu.
  static Future<void> deleteUrls(Iterable<String> urls) async {
    for (final url in urls) {
      try {
        await ApiClient.delete('/upload', body: {'url': url});
      } catch (_) {}
    }
  }

  static Future<List<String>> _post(String path, String field, List<XFile> files) async {
    final uri = Uri.parse('${ApiConfig.fullBaseUrl}$path');
    final request = http.MultipartRequest('POST', uri);
    final token = await ApiClient.getToken();
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    for (final f in files) {
      final bytes = await f.readAsBytes();
      final mime = await PhotoRules.detectPhotoType(f) ?? 'application/octet-stream';
      final ext = PhotoRules.extensionFor(mime);
      request.files.add(http.MultipartFile.fromBytes(
        field,
        bytes,
        filename: 'foto.$ext',
        contentType: MediaType.parse(mime),
      ));
    }
    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    final decoded = _decode(response);

    final out = <String>[];
    if (decoded is Map<String, dynamic>) {
      final urls = decoded['urls'];
      if (urls is List) {
        out.addAll(urls.map((e) => e.toString()));
      } else if (decoded['url'] != null) {
        out.add(decoded['url'].toString());
      }
    }
    if (out.length != files.length) {
      throw ApiException(502, 'Respons unggah tidak valid');
    }
    return out;
  }

  static dynamic _decode(http.Response response) {
    dynamic decoded;
    try {
      if (response.body.isNotEmpty) decoded = jsonDecode(response.body);
    } catch (_) {
      decoded = null;
    }
    final status = response.statusCode;
    if (status >= 200 && status < 300) return decoded;

    if (status == 401) {
      ApiClient.removeToken();
      ApiClient.onUnauthorized?.call();
    }
    String message;
    String? code;
    Map<String, dynamic>? extra;
    if (decoded is Map<String, dynamic>) {
      message = status >= 500
          ? 'Terjadi kesalahan pada server'
          : (decoded['error'] ?? decoded['message'] ?? 'Request gagal').toString();
      final c = decoded['code'];
      code = c is String ? c : null;
      extra = decoded;
    } else {
      message = status >= 500 ? 'Terjadi kesalahan pada server' : 'Request gagal ($status)';
    }
    throw ApiException(status, message, code, extra);
  }
}
