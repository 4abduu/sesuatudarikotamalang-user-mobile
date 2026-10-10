import 'dart:async';
import 'package:flutter/material.dart';

/// Mock AI story-draft provider — pola ChangeNotifier (sama seperti provider
/// lain di project ini). View tidak memegang logika bisnis apa pun.
///
/// Di versi final, `generateDraft()` akan memanggil backend Express →
/// Gemini API (POST /api/ai/story-draft). Untuk prototype ini, kita
/// menyusun draft **dari isian user** di sisi client dengan delay ±1.5 detik
/// agar terasa realistis saat didemokan.
///
/// Lihat: // TODO: ganti dengan POST /api/ai/story-draft
///
/// Trigger demo state error:
///   - isian mengandung `demo-error`  → 503 (AI tidak tersedia)
///   - isian mengandung `demo-limit`  → 429 (terlalu sering)
///   - isian mengandung `demo-blokir` → 422 (diblokir filter)

enum StoryAiState { idle, loading, result, error }

enum StoryAiErrorKind {
  /// 503 — AI tidak tersedia / timeout
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
  StoryAiDraft({required this.title, required this.body});
}

/// Input poin singkat dari kreator.
class StoryAiInput {
  final String motif;
  final String process;
  final String inspiration;
  const StoryAiInput({
    required this.motif,
    required this.process,
    required this.inspiration,
  });

  /// Total panjang karakter gabungan (dipakai untuk validasi minimal 30).
  int get totalLength => motif.length + process.length + inspiration.length;

  /// True jika salah satu isian mengandung keyword trigger demo error.
  /// Versi produksi tidak akan ada keyword ini — error datang dari backend.
  String? get _demoTrigger {
    final all = '$motif\n$process\n$inspiration'.toLowerCase();
    if (all.contains('demo-error')) return 'demo-error';
    if (all.contains('demo-limit')) return 'demo-limit';
    if (all.contains('demo-blokir')) return 'demo-blokir';
    return null;
  }

  /// Untuk mock: benarkan error yang harus disimulasikan (bila ada).
  String? get demoErrorKind => _demoTrigger;
}

class StoryAiProvider extends ChangeNotifier {
  StoryAiState _state = StoryAiState.idle;
  StoryAiDraft? _draft;
  StoryAiError? _error;
  StoryAiInput? _lastInput;
  int _regenCount = 0;

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
    _regenCount = 0;
    notifyListeners();
  }

  /// Mulai generate draft. Tidak menyimpan apapun ke form otomatis —
  /// View yang memutuskan apakah hasilnya dipakai atau tidak.
  Future<void> generateDraft(StoryAiInput input) async {
    _lastInput = input;
    _state = StoryAiState.loading;
    _draft = null;
    _error = null;
    notifyListeners();

    // Simulasi latensi jaringan ke backend AI.
    // TODO: ganti dengan POST /api/ai/story-draft
    await Future<void>.delayed(const Duration(milliseconds: 1500));

    // Cek trigger error demo (hanya prototype).
    final demo = input.demoErrorKind;
    if (demo != null) {
      _state = StoryAiState.error;
      switch (demo) {
        case 'demo-error':
          _error = StoryAiError(
            kind: StoryAiErrorKind.unavailable,
            message: 'Bantuan AI sedang tidak tersedia. Kamu bisa menulis sendiri.',
          );
          break;
        case 'demo-limit':
          _error = StoryAiError(
            kind: StoryAiErrorKind.rateLimited,
            message: 'Kamu sudah terlalu sering mencoba. Coba lagi nanti ya.',
          );
          break;
        case 'demo-blokir':
          _error = StoryAiError(
            kind: StoryAiErrorKind.blocked,
            message: 'Coba ubah poin-poinnya sedikit.',
          );
          break;
      }
      notifyListeners();
      return;
    }

    // Susun draft dari isian user. Variasi berbeda setiap kali "Buat Ulang"
    // dipanggil dengan input yang sama.
    _draft = _composeDraft(input, _regenCount);
    _regenCount = (_regenCount + 1) % 3;
    _state = StoryAiState.result;
    notifyListeners();
  }

  /// Generate ulang dengan input yang sama.
  Future<void> regenerate() async {
    if (_lastInput == null) return;
    await generateDraft(_lastInput!);
  }

  /// Susun draft cerita orang pertama "aku/kami" dari poin singkat user.
  /// Bahasa Indonesia hangat, tanpa emoji, tanpa harga/kontak, tanpa
  /// fakta karangan — hanya merangkai kata-kata user sendiri.
  StoryAiDraft _composeDraft(StoryAiInput input, int variation) {
    final motif = input.motif.trim();
    final process = input.process.trim();
    final inspiration = input.inspiration.trim();

    // Fallback aman jika salah satu field kosong.
    final motifPhrase = motif.isEmpty ? 'karya ini' : motif;
    final processPhrase = process.isEmpty
        ? 'proses yang meneliti setiap detailnya'
        : process;
    final inspirationPhrase = inspiration.isEmpty
        ? 'lingkungan sekitar yang kaya cerita'
        : inspiration;

    final titles = [
      'Cerita di Balik $motifPhrase',
      'Menggarap $motifPhrase',
      'Lahir dari $inspirationPhrase',
    ];

    final openings = [
      'Aku mulai menggarap $motifPhrase dari rasa penasaran sederhana.',
      'Semua berawal dari $inspirationPhrase — sebuah suasana yang susah aku lupakan.',
      'Ada momen yang bikin aku pengen mendokumentasikan $motifPhrase ini.',
    ];

    final middles = [
      'Prosesnya sendiri $processPhrase. Aku sengaja mengambil waktu supaya tiap detailnya terasa tepat, bukan buru-buru selesai.',
      'Lewat $processPhrase, aku belajar banyak hal kecil yang akhirnya bikin karya ini jadi apa adanya sekarang.',
      'Aku nggak mau terburu — $processPhrase butuh kesabaran, dan rasa sabar itu justru yang bikin hasilnya bermakna.',
    ];

    final closings = [
      'Kalau ada satu hal yang aku pengen orang lain tangkap dari karya ini, ya rasa tenang yang sama aku rasakan pas bikin.',
      'Harapannya, siapa pun yang lihat $motifPhrase ini bisa ngerasain sedikit dari suasana yang menggerakkan aku.',
      'Selesai sudah. Aku cuma berharap karya ini jadi jendela kecil ke cerita yang sebenernya lebih besar dari diriku.',
    ];

    final title = titles[variation % titles.length];
    final body =
        '${openings[variation % openings.length]}\n\n'
        '${middles[variation % middles.length]}\n\n'
        '${closings[variation % closings.length]}';

    return StoryAiDraft(title: title, body: body);
  }
}
