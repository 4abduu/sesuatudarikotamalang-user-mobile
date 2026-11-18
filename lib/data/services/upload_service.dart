import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/network/api_exception.dart';
import '../../core/network/api_service.dart';
import '../../core/utils/photo_rules.dart';

class UploadService {
  UploadService(this._api);
  final ApiService _api;

  Future<String> uploadOne(XFile file) async {
    final urls = await _post('/upload/single', 'file', [file]);
    return urls.single;
  }

  Future<List<String>> uploadMany(List<XFile> files) async {
    if (files.isEmpty) return <String>[];
    final urls = <String>[];
    try {
      for (var i = 0; i < files.length; i += PhotoRules.maxPerCall) {
        final end = i + PhotoRules.maxPerCall > files.length
            ? files.length
            : i + PhotoRules.maxPerCall;
        urls.addAll(
            await _post('/upload/multiple', 'files', files.sublist(i, end)));
      }
    } catch (_) {
      if (urls.isNotEmpty) await deleteUrls(urls);
      rethrow;
    }
    return urls;
  }

  Future<void> deleteUrls(Iterable<String> urls) async {
    for (final url in urls) {
      try {
        await _api.delete('/upload', body: {'url': url});
      } catch (_) {}
    }
  }

  Future<List<String>> _post(
      String path, String field, List<XFile> files) async {
    final multipart = <http.MultipartFile>[];
    for (final file in files) {
      final bytes = await file.readAsBytes();
      final mime =
          await PhotoRules.detectPhotoType(file) ?? 'application/octet-stream';
      multipart.add(http.MultipartFile.fromBytes(field, bytes,
          filename: 'foto.${PhotoRules.extensionFor(mime)}',
          contentType: MediaType.parse(mime)));
    }
    final decoded = await _api.postMultipart(path, files: multipart);
    final urls = <String>[];
    if (decoded is Map<String, dynamic>) {
      if (decoded['urls'] is List) {
        urls.addAll((decoded['urls'] as List).map((e) => e.toString()));
      } else if (decoded['url'] != null) {
        urls.add(decoded['url'].toString());
      }
    }
    if (urls.length != files.length) {
      throw ApiException(502, 'Respons unggah tidak valid');
    }
    return urls;
  }
}
