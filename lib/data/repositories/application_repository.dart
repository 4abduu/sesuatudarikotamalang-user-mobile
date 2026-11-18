import '../../core/network/api_exception.dart';
import '../../core/network/api_service.dart';
import '../models/creator_application_model.dart';

abstract class ApplicationRepository {
  Future<List<CreatorApplicationModel>> getMine();
  Future<CreatorApplicationModel> apply({required String applicantName,
    required String contact, String? brandName, required String description,
    String? categoryId, String? sampleFileUrl, List<String>? samplePhotos});
}

class ApplicationRepositoryImpl implements ApplicationRepository {
  ApplicationRepositoryImpl(this._api);
  final ApiService _api;
  @override
  Future<List<CreatorApplicationModel>> getMine() async {
    final res = await _api.get('/artisans/applications/mine');
    return ((res?['applications'] as List?) ?? const [])
        .map((e) => CreatorApplicationModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<CreatorApplicationModel> apply({required String applicantName,
    required String contact, String? brandName, required String description,
    String? categoryId, String? sampleFileUrl, List<String>? samplePhotos}) async {
    final res = await _api.post('/artisans/apply', body: {
      'applicantName': applicantName,
      'contact': contact,
      if (brandName != null && brandName.trim().isNotEmpty) 'brandName': brandName.trim(),
      'description': description,
      if (categoryId != null && categoryId.isNotEmpty) 'categoryId': categoryId,
      if (sampleFileUrl != null && sampleFileUrl.isNotEmpty) 'sampleFileUrl': sampleFileUrl,
      if (samplePhotos != null && samplePhotos.isNotEmpty) 'samplePhotos': samplePhotos,
    });
    if (res != null && res['application'] != null) {
      return CreatorApplicationModel.fromJson(res['application'] as Map<String, dynamic>);
    }
    throw ApiException(500, 'Gagal mengirim pengajuan kreator.');
  }
}
