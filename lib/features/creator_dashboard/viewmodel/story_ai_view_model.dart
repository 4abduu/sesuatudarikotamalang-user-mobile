import 'package:flutter/foundation.dart';
import '../../../core/network/api_exception.dart';

import '../../../data/models/story_ai_model.dart';
import '../../../data/repositories/ai_repository.dart';
export '../../../data/models/story_ai_model.dart';

enum StoryAiState { idle, loading, result, error }

enum StoryAiErrorKind {
  /// 502 / 503 / 504 — AI tidak tersedia / timeout / bad response
  unavailable,
  /// 429 — terlalu sering mencoba
  rateLimited,
  /// 422 — diblokir filter konten
  blocked,
}

class StoryAiError {
  final StoryAiErrorKind kind;
  final String message;
  StoryAiError({required this.kind, required this.message});
}

class StoryAiViewModel extends ChangeNotifier {
  StoryAiViewModel({required AiRepository repository}) : _repository = repository;
  final AiRepository _repository;
  bool _disposed = false;
  int _requestId = 0;

  static bool canGenerate(StoryAiInput input) => validationHint(input) == null;
  static String? validationHint(StoryAiInput input) {
    if (input.totalLength == 0) return 'Isi minimal beberapa poin singkat ya';
    if (input.motif.length + input.inspiration.length < 15) {
      return 'Isi Motif atau Inspirasi sebagai dasar cerita. Proses saja belum cukup.';
    }
    if (input.totalLength < 30) {
      return 'Total karakter dari semua poin minimal 30 ya (${30 - input.totalLength} lagi)';
    }
    return null;
  }

  void _notify() { if (!_disposed) notifyListeners(); }
  @override
  void dispose() { _disposed = true; _requestId++; super.dispose(); }

  StoryAiState _state = StoryAiState.idle;
  StoryAiDraft? _draft;
  StoryAiError? _error;
  StoryAiInput? _lastInput;

  StoryAiState get state => _state;
  StoryAiDraft? get draft => _draft;
  StoryAiError? get error => _error;
  bool get isLoading => _state == StoryAiState.loading;

  /// Reset ke state idle (tutup panel / buka lagi).
  void reset() {
    _requestId++;
    _state = StoryAiState.idle;
    _draft = null;
    _error = null;
    _lastInput = null;
    _notify();
  }

  /// Mulai generate draft ke Backend Express → Gemini API (POST /api/ai/story-draft).
  /// Tidak menyimpan apapun ke form otomatis — View yang memutuskan apakah hasilnya dipakai atau tidak.
  Future<void> generateDraft(StoryAiInput input) async {
    if (_disposed || isLoading || !canGenerate(input)) return;
    final requestId = ++_requestId;
    _lastInput = input;
    _state = StoryAiState.loading;
    _draft = null;
    _error = null;
    _notify();

    try {
      final draft = await _repository.generateDraft(input);
      if (_disposed || requestId != _requestId) return;
      _draft = draft;
      _state = StoryAiState.result;
      _notify();
    } on ApiException catch (e) {
      if (_disposed || requestId != _requestId) return;
      _state = StoryAiState.error;
      if (e.status == 429 || e.code == 'RATE_LIMITED') {
        _error = StoryAiError(
          kind: StoryAiErrorKind.rateLimited,
          message: 'Kamu sudah terlalu sering mencoba. Coba lagi nanti ya.',
        );
      } else if (e.status == 422 || e.code == 'AI_CONTENT_BLOCKED') {
        _error = StoryAiError(
          kind: StoryAiErrorKind.blocked,
          message: e.message.isNotEmpty ? e.message : 'Konten terdeteksi sensitif, coba ubah poin-poin cerita kamu.',
        );
      } else {
        _error = StoryAiError(
          kind: StoryAiErrorKind.unavailable,
          message: 'Bantuan AI sedang tidak tersedia. Kamu bisa menulis sendiri.',
        );
      }
      _notify();
    } catch (_) {
      if (_disposed || requestId != _requestId) return;
      _state = StoryAiState.error;
      _error = StoryAiError(
        kind: StoryAiErrorKind.unavailable,
        message: 'Gagal terhubung ke layanan AI. Kamu bisa menulis sendiri.',
      );
      _notify();
    }
  }

  /// Generate ulang dengan input yang sama.
  Future<void> regenerate() async {
    if (_lastInput == null) return;
    await generateDraft(_lastInput!);
  }
}
