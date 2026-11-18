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

