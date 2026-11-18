import '../../core/network/api_exception.dart';
import '../../core/network/api_service.dart';
import '../models/story_ai_model.dart';

abstract class AiRepository {
  Future<StoryAiDraft> generateDraft(StoryAiInput input);
}

class AiRepositoryImpl implements AiRepository {
  AiRepositoryImpl(this._api);
  final ApiService _api;

  @override
  Future<StoryAiDraft> generateDraft(StoryAiInput input) async {
    final res = await _api.post('/ai/story-draft', body: {
      'motif': input.motif.trim(),
      'process': input.process.trim(),
      'inspiration': input.inspiration.trim(),
      if (input.productName != null && input.productName!.isNotEmpty)
        'productName': input.productName,
      if (input.category != null && input.category!.isNotEmpty)
        'category': input.category,
    });
    final draft = res?['draft'];
    if (draft is! Map<String, dynamic>) {
      throw ApiException(502, 'Bantuan AI mengembalikan respons tidak valid', 'AI_BAD_RESPONSE');
    }
    return StoryAiDraft(
      title: (draft['judul'] ?? draft['title'] ?? 'Behind the Design').toString(),
      body: (draft['isi'] ?? draft['body'] ?? '').toString(),
      process: (draft['proses'] ?? draft['process'] ?? '').toString(),
    );
  }
}
