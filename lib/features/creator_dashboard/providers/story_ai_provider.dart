import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';

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

class StoryAiDraft {
  final String title;
  final String body;
  final String process;
  StoryAiDraft({required this.title, required this.body, this.process = ''});
}

/// Input poin singkat dari kreator.
class StoryAiInput {
  final String motif;
  final String process;
  final String inspiration;
  final String? productName;
  final String? category;

  const StoryAiInput({
    required this.motif,
    required this.process,
    required this.inspiration,
    this.productName,
    this.category,
  });

  /// Total panjang karakter gabungan (dipakai untuk validasi minimal 30).
  int get totalLength => motif.length + process.length + inspiration.length;
}

class StoryAiProvider extends ChangeNotifier {
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
    _state = StoryAiState.idle;
    _draft = null;
    _error = null;
    _lastInput = null;
    notifyListeners();
  }

  /// Mulai generate draft ke Backend Express → Gemini API (POST /api/ai/story-draft).
  /// Tidak menyimpan apapun ke form otomatis — View yang memutuskan apakah hasilnya dipakai atau tidak.
  Future<void> generateDraft(StoryAiInput input) async {
    _lastInput = input;
    _state = StoryAiState.loading;
    _draft = null;
    _error = null;
    notifyListeners();

    try {
      final res = await ApiClient.post(
        '/ai/story-draft',
        body: {
          'motif': input.motif.trim(),
          'process': input.process.trim(),
          'inspiration': input.inspiration.trim(),
          if (input.productName != null && input.productName!.isNotEmpty)
            'productName': input.productName,
          if (input.category != null && input.category!.isNotEmpty)
            'category': input.category,
        },
      );

      if (res != null && res['draft'] != null) {
        final draftData = res['draft'] as Map<String, dynamic>;
        _draft = StoryAiDraft(
          title: (draftData['judul'] ?? draftData['title'] ?? 'Behind the Design').toString(),
          body: (draftData['isi'] ?? draftData['body'] ?? '').toString(),
          process: (draftData['proses'] ?? draftData['process'] ?? '').toString(),
        );
        _state = StoryAiState.result;
        notifyListeners();
        return;
      }
      throw ApiException(502, 'Bantuan AI mengembalikan respons tidak valid', 'AI_BAD_RESPONSE');
    } on ApiException catch (e) {
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
      notifyListeners();
    } catch (_) {
      _state = StoryAiState.error;
      _error = StoryAiError(
        kind: StoryAiErrorKind.unavailable,
        message: 'Gagal terhubung ke layanan AI. Kamu bisa menulis sendiri.',
      );
      notifyListeners();
    }
  }

  /// Generate ulang dengan input yang sama.
  Future<void> regenerate() async {
    if (_lastInput == null) return;
    await generateDraft(_lastInput!);
  }
}
