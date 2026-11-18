import '../../core/network/api_exception.dart';
import '../../core/network/api_service.dart';
import '../models/product_model.dart';

abstract class StoryRepository {
  Future<List<ProductModel>> getMine();
  Future<void> saveStory({required String productId, required String title,
    required String content, String? process, String? coverImageUrl,
    List<String>? processImages});
}

class StoryRepositoryImpl implements StoryRepository {
  StoryRepositoryImpl(this._api);
  final ApiService _api;

  @override
  Future<List<ProductModel>> getMine() async {
    final res = await _api.get('/products/mine');
    return ((res?['products'] as List?) ?? const [])
        .map((e) => ProductModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<void> saveStory({required String productId, required String title,
    required String content, String? process, String? coverImageUrl,
    List<String>? processImages}) async {
    final res = await _api.post('/products/$productId/story', body: {
      'title': title,
      'content': content,
      if (process != null && process.trim().isNotEmpty) 'process': process.trim(),
      if (coverImageUrl != null) 'coverImageUrl': coverImageUrl,
      if (processImages != null) 'processImages': processImages,
    });
    if (res == null || res['story'] == null) {
      throw ApiException(500, 'Gagal menyimpan cerita produk');
    }
  }
}
