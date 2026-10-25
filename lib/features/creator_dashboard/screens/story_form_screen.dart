import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/secondary_button.dart';
import '../../../shared/app_scaffold.dart';
import '../providers/story_ai_provider.dart';

/// Form to add/edit the "Behind the Design" story for a product.
///
/// Fields:
///   - Optional "Bantu Tulis dengan AI" (modal bottom sheet) — fills Judul + Isi
///   - Judul cerita
///   - Isi cerita (multiline)
///   - Upload foto proses (image_picker, multiple; thumbnails shown)
///
/// Edit mode: when `?productId=<id>` matches a product with an
/// existing story, pre-fill the title and body. Save → SnackBar + pop.
import 'package:provider/provider.dart';
import '../../../data/models/product_model.dart';
import '../providers/creator_dashboard_provider.dart';

class StoryFormScreen extends StatefulWidget {
  final String productId;
  const StoryFormScreen({super.key, this.productId = ''});

  @override
  State<StoryFormScreen> createState() => _StoryFormScreenState();
}

class _StoryFormScreenState extends State<StoryFormScreen> {
  final _judul = TextEditingController();
  final _isi = TextEditingController();
  final List<String> _photos = [];
  String _productName = '';
  bool _isSaving = false;
  bool get _isEdit => _judul.text.isNotEmpty;

  @override
  void initState() {
    super.initState();
    if (widget.productId.isNotEmpty) {
      final dashboard = context.read<CreatorDashboardProvider>();
      final p = dashboard.myProducts.cast<ProductModel?>().firstWhere(
        (x) => x?.id == widget.productId,
        orElse: () => null,
      );
      if (p != null) {
        _productName = p.name;
        if (p.hasStory) {
          _judul.text = p.story!.title;
          _isi.text = p.story!.body;
        }
      }
    }
  }

  @override
  void dispose() {
    _judul.dispose();
    _isi.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final files = await picker.pickMultiImage(imageQuality: 80);
    if (files.isNotEmpty) {
      setState(() => _photos.addAll(files.map((f) => f.path)));
    }
  }

  Future<void> _save() async {
    if (_judul.text.trim().isEmpty || _isi.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Judul dan isi cerita wajib diisi')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final dashboard = context.read<CreatorDashboardProvider>();
      await dashboard.saveStory(
        productId: widget.productId,
        title: _judul.text.trim(),
        content: _isi.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isEdit ? 'Cerita "${_judul.text}" diperbarui' : 'Cerita "${_judul.text}" ditambahkan')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan cerita: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  /// Buka panel AI — showModalBottomSheet. View tidak memegang logika bisnis:
  /// semua state dialihkan ke StoryAiProvider. Karena sheet perlu mengisi
  /// field Judul/Isi di parent saat "Gunakan Draft Ini", kita passing
  /// callback `applyDraft` yang membaca controller di sini.
  void _openAiHelper() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _AiHelperSheet(
        applyDraft: (draft) {
          setState(() {
            _judul.text = draft.title;
            _isi.text = draft.body;
          });
        },
        hasExistingContent: _judul.text.isNotEmpty || _isi.text.isNotEmpty,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: _isEdit ? 'Edit Cerita' : 'Tambah Cerita',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_productName.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.moss.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(children: [
                  const Icon(Icons.inventory_2_outlined, size: 18, color: AppColors.moss),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        style: AppTextStyles.caption,
                        children: [
                          const TextSpan(text: 'Untuk produk: '),
                          TextSpan(
                            text: _productName,
                            style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.moss),
                          ),
                        ],
                      ),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 16),
            ],

            // ===== Bantu Tulis dengan AI (opsional) =====
            _AiHelpCard(onTap: _openAiHelper),
            const SizedBox(height: 16),

            Text('Judul Cerita', style: _formLabel),
            const SizedBox(height: 6),
            TextField(
              controller: _judul,
              style: AppTextStyles.body,
              decoration: _fieldDecoration('cth: Jendela yang Nggak Pernah Ketutup'),
            ),
            const SizedBox(height: 16),
            Text('Isi Cerita', style: _formLabel),
            const SizedBox(height: 6),
            TextField(
              controller: _isi,
              minLines: 6,
              maxLines: 8,
              style: AppTextStyles.body.copyWith(height: 1.3),
              decoration: _fieldDecoration('Ceritakan inspirasi di balik karya ini...').copyWith(alignLabelWithHint: true),
            ),
            const SizedBox(height: 16),
            Text('Foto Proses Pembuatan', style: _formLabel),
            const SizedBox(height: 4),
            Text('Unggah beberapa foto proses (opsional)', style: AppTextStyles.caption),
            const SizedBox(height: 8),
            _PhotoGallery(photos: _photos, onPick: _pickPhoto, onRemove: (i) => setState(() => _photos.removeAt(i))),
            const SizedBox(height: 16),
            PrimaryButton(
              label: _isSaving
                  ? 'Menyimpan...'
                  : (_isEdit ? 'Simpan Perubahan' : 'Tambah Cerita'),
              onPressed: _isSaving ? null : _save,
              icon: const Icon(Icons.check, size: 16),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: SecondaryButton(
                label: 'Batal',
                onPressed: () => context.pop(),
                icon: const Icon(Icons.close, size: 16),
                verticalPadding: 12,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

/* ------------------------------------------------------------------ */
/* Style helpers (visual only) — sesuai 19-mformcerita.tsx            */
/* ------------------------------------------------------------------ */

/// Label field: Baloo 2 14 semibold (font-display text-[14px] font-semibold).
TextStyle get _formLabel =>
    AppTextStyles.title.copyWith(fontSize: 14, fontWeight: FontWeight.w600);

/// Field: fill surface, border 1px, radius 12, padding 12, hint muted.
InputDecoration _fieldDecoration(String hint) => InputDecoration(
      hintText: hint,
      hintStyle: AppTextStyles.bodyMuted,
      contentPadding: const EdgeInsets.all(12),
    );

/* ------------------------------------------------------------------ */
/* AI Help Card — tombol opsional di atas Judul Cerita                */
/* ------------------------------------------------------------------ */

class _AiHelpCard extends StatelessWidget {
  final VoidCallback onTap;
  const _AiHelpCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.moss.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.moss.withValues(alpha: 0.25)),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.moss.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.auto_awesome, size: 20, color: AppColors.moss),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Bantu Tulis dengan AI', style: AppTextStyles.title.copyWith(fontSize: 14, color: AppColors.moss)),
                    const SizedBox(height: 2),
                    Text('Isi poin singkat, AI susun draft ceritanya.', style: AppTextStyles.caption),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.moss, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

/* ------------------------------------------------------------------ */
/* AI Helper Sheet — 4 state (input / loading / result / error)       */
/*                                                                    */
/* View TIDAK memegang logika bisnis. Hanya membaca state dari         */
/* StoryAiProvider via context.watch & menampilkan UI yang sesuai.    */
/* ------------------------------------------------------------------ */

class _AiHelperSheet extends StatefulWidget {
  final void Function(StoryAiDraft draft) applyDraft;
  final bool hasExistingContent;
  const _AiHelperSheet({
    required this.applyDraft,
    required this.hasExistingContent,
  });

  @override
  State<_AiHelperSheet> createState() => _AiHelperSheetState();
}

class _AiHelperSheetState extends State<_AiHelperSheet> {
  final _provider = StoryAiProvider();
  final _motif = TextEditingController();
  final _process = TextEditingController();
  final _inspiration = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Listenable harus didaftarkan sebelum build pertama supaya rebuild
    // sheet terjadi setiap kali provider notify.
    _provider.addListener(_onProviderChanged);
  }

  void _onProviderChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _provider.removeListener(_onProviderChanged);
    _provider.dispose();
    _motif.dispose();
    _process.dispose();
    _inspiration.dispose();
    super.dispose();
  }

  int get _totalLength =>
      _motif.text.length + _process.text.length + _inspiration.text.length;
  bool get _canGenerate => _totalLength >= 30;

  void _generate() {
    if (!_canGenerate) return;
    FocusScope.of(context).unfocus();
    _provider.generateDraft(StoryAiInput(
      motif: _motif.text,
      process: _process.text,
      inspiration: _inspiration.text,
    ));
  }

  void _useDraft() {
    // AI tidak pernah menyimpan otomatis — kita hanya mengisi field form.
    // Jika form parent sudah terisi, minta konfirmasi dulu.
    final draft = _provider.draft;
    if (draft == null) return;
    if (widget.hasExistingContent) {
      _confirmUseDraft(draft);
      return;
    }
    _applyDraft(draft);
  }

  void _confirmUseDraft(StoryAiDraft draft) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Isi cerita saat ini akan diganti', style: AppTextStyles.h3),
        content: Text('Lanjut mengganti dengan draft dari AI?', style: AppTextStyles.body),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Batal')),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _applyDraft(draft);
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.moss,
              foregroundColor: AppColors.onMoss,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
            ),
            child: const Text('Ganti'),
          ),
        ],
      ),
    );
  }

  void _applyDraft(StoryAiDraft draft) {
    widget.applyDraft(draft);
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Draft dimasukkan ke form. Jangan lupa simpan ya.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Grabber
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Header
                Row(
                  children: [
                    Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.moss.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.auto_awesome, size: 18, color: AppColors.moss),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text('Bantu Tulis dengan AI', style: AppTextStyles.title.copyWith(fontSize: 14, fontWeight: FontWeight.w700)),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, size: 16, color: AppColors.muted),
                      tooltip: 'Tutup',
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'AI hanya memakai poin yang kamu tulis, tidak mengarang fakta.',
                  style: AppTextStyles.caption,
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: SingleChildScrollView(
                    child: _buildBodyForState(),
                  ),
                ),
                const SizedBox(height: 12),
                _buildFooterAction(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBodyForState() {
    switch (_provider.state) {
      case StoryAiState.idle:
        return _InputForm(
          motif: _motif,
          process: _process,
          inspiration: _inspiration,
          onChanged: () => setState(() {}),
          canGenerate: _canGenerate,
          onGenerate: _generate,
        );
      case StoryAiState.loading:
        return const _LoadingView();
      case StoryAiState.result:
        return _ResultView(
          draft: _provider.draft!,
          onUseDraft: _useDraft,
          onRegenerate: () => _provider.regenerate(),
          onWriteSelf: () => Navigator.of(context).pop(),
        );
      case StoryAiState.error:
        return _ErrorView(
          error: _provider.error!,
          onRetry: _generate,
          onWriteSelf: () => Navigator.of(context).pop(),
        );
    }
  }

  Widget _buildFooterAction() {
    switch (_provider.state) {
      case StoryAiState.idle:
        return PrimaryButton(
          label: 'Buat Draft',
          onPressed: _canGenerate ? _generate : null,
          icon: const Icon(Icons.auto_awesome, size: 16),
          color: AppColors.moss,
        );
      case StoryAiState.loading:
        // TSX state "loading": hanya spinner + skeleton, tanpa tombol.
        return const SizedBox.shrink();
      case StoryAiState.result:
      case StoryAiState.error:
        return const SizedBox.shrink();
    }
  }
}

/* ------------------------------------------------------------------ */
/* State 1: Input Form                                                  */
/* ------------------------------------------------------------------ */

class _InputForm extends StatelessWidget {
  final TextEditingController motif;
  final TextEditingController process;
  final TextEditingController inspiration;
  final VoidCallback onChanged;
  final VoidCallback onGenerate;
  final bool canGenerate;

  const _InputForm({
    required this.motif,
    required this.process,
    required this.inspiration,
    required this.onChanged,
    required this.onGenerate,
    required this.canGenerate,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PointField(
          label: 'Motif / objek yang digambar',
          controller: motif,
          placeholder: 'singa dengan latar bangunan heritage',
          onChanged: onChanged,
        ),
        const SizedBox(height: 8),
        _PointField(
          label: 'Proses pembuatan',
          controller: process,
          placeholder: 'sketsa tangan lalu didigitalkan, dicetak enamel',
          onChanged: onChanged,
        ),
        const SizedBox(height: 8),
        _PointField(
          label: 'Inspirasi di baliknya',
          controller: inspiration,
          placeholder: 'jalan Basuki Rahmat sore hari',
          onChanged: onChanged,
        ),
        const SizedBox(height: 12),
        if (!canGenerate)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Isi minimal beberapa poin singkat ya',
              style: AppTextStyles.caption.copyWith(color: AppColors.mustard),
            ),
          ),
      ],
    );
  }
}

OutlineInputBorder _pointBorder(Color color, {double width = 1}) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: color, width: width),
    );

class _PointField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String placeholder;
  final VoidCallback onChanged;
  const _PointField({
    required this.label,
    required this.controller,
    required this.placeholder,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTextStyles.label),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (_, v, __) => Text(
                '${v.text.length}/300',
                style: AppTextStyles.caption.copyWith(
                  fontSize: 11,
                  color: v.text.length > 300 ? AppColors.destructive : AppColors.muted,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLength: 300,
          maxLines: 3,
          minLines: 2,
          onChanged: (_) => onChanged(),
          style: AppTextStyles.label.copyWith(fontWeight: FontWeight.w400),
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: AppTextStyles.label.copyWith(fontWeight: FontWeight.w400, color: AppColors.muted),
            counterText: '', // pakai counter custom di atas
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            border: _pointBorder(AppColors.border),
            enabledBorder: _pointBorder(AppColors.border),
            focusedBorder: _pointBorder(AppColors.primary, width: 1.5),
          ),
        ),
      ],
    );
  }
}

/* ------------------------------------------------------------------ */
/* State 2: Loading                                                     */
/* ------------------------------------------------------------------ */

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const SizedBox(
              width: 18, height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.moss),
            ),
            const SizedBox(width: 10),
            Text('AI lagi merangkai ceritamu…', style: AppTextStyles.title.copyWith(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.moss)),
          ],
        ),
        const SizedBox(height: 12),
        // Skeleton shimmer (lebar mengikuti TSX: 128 / 100% / 92% / 85% ...)
        const _ShimmerBlock(width: 128, height: 14),
        const SizedBox(height: 8),
        const _ShimmerBlock(width: double.infinity, height: 10),
        const SizedBox(height: 8),
        const _ShimmerBlock(width: double.infinity, widthFactor: 0.92, height: 10),
        const SizedBox(height: 8),
        const _ShimmerBlock(width: double.infinity, widthFactor: 0.85, height: 10),
        const SizedBox(height: 20),
        const _ShimmerBlock(width: 112, height: 14),
        const SizedBox(height: 8),
        const _ShimmerBlock(width: double.infinity, height: 10),
        const SizedBox(height: 8),
        const _ShimmerBlock(width: double.infinity, widthFactor: 0.90, height: 10),
      ],
    );
  }
}

class _ShimmerBlock extends StatefulWidget {
  final double width;
  final double height;
  final double widthFactor;
  const _ShimmerBlock({required this.width, required this.height, this.widthFactor = 1});

  @override
  State<_ShimmerBlock> createState() => _ShimmerBlockState();
}

class _ShimmerBlockState extends State<_ShimmerBlock> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    final effectiveWidth = widget.width == double.infinity
        ? double.infinity
        : (widget.width.isFinite ? widget.width : double.infinity);
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        final alpha = 0.55 + 0.35 * _c.value;
        final block = Container(
          width: effectiveWidth,
          height: widget.height,
          decoration: BoxDecoration(
            color: AppColors.border.withValues(alpha: alpha),
            borderRadius: BorderRadius.circular(4),
          ),
        );
        if (widget.widthFactor == 1) return block;
        return Align(
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: widget.widthFactor,
            child: SizedBox(height: widget.height, child: block),
          ),
        );
      },
    );
  }
}

/* ------------------------------------------------------------------ */
/* State 3: Result / Pratinjau                                          */
/* ------------------------------------------------------------------ */

class _ResultView extends StatelessWidget {
  final StoryAiDraft draft;
  final VoidCallback onUseDraft;
  final VoidCallback onRegenerate;
  final VoidCallback onWriteSelf;
  const _ResultView({
    required this.draft,
    required this.onUseDraft,
    required this.onRegenerate,
    required this.onWriteSelf,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.mustard.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.mustard.withValues(alpha: 0.4)),
          ),
          child: Row(
            children: [
              const Icon(Icons.visibility_outlined, size: 16, color: AppColors.mustard),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Draft dari AI — periksa dulu sebelum disimpan',
                  style: AppTextStyles.caption.copyWith(color: AppColors.mustard, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text('Judul Cerita', style: AppTextStyles.label.copyWith(fontSize: 12)),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Text(draft.title, style: AppTextStyles.title.copyWith(fontSize: 14, fontWeight: FontWeight.w700)),
        ),
        const SizedBox(height: 12),
        Text('Isi Cerita', style: AppTextStyles.label.copyWith(fontSize: 12)),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Text(draft.body, style: AppTextStyles.body.copyWith(fontSize: 13, height: 1.625)),
        ),
        const SizedBox(height: 12),
        PrimaryButton(
          label: 'Gunakan Draft Ini',
          onPressed: onUseDraft,
          icon: const Icon(Icons.check_circle_outline, size: 18),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: SecondaryButton(
                label: 'Buat Ulang',
                onPressed: onRegenerate,
                icon: const Icon(Icons.refresh, size: 16),
                verticalPadding: 12,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: SecondaryButton(
                label: 'Tulis Sendiri',
                onPressed: onWriteSelf,
                icon: const Icon(Icons.edit_outlined, size: 16),
                verticalPadding: 12,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/* ------------------------------------------------------------------ */
/* State 4: Error                                                       */
/* ------------------------------------------------------------------ */

class _ErrorView extends StatelessWidget {
  final StoryAiError error;
  final VoidCallback onRetry;
  final VoidCallback onWriteSelf;
  const _ErrorView({
    required this.error,
    required this.onRetry,
    required this.onWriteSelf,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.destructive.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.destructive.withValues(alpha: 0.25)),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: AppColors.destructive.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.cloud_off_outlined, size: 22, color: AppColors.destructive),
          ),
          const SizedBox(height: 12),
          Text('Yah, ada kendala', style: AppTextStyles.title.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(
            error.message,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMuted.copyWith(fontSize: 13),
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            label: 'Coba Lagi',
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 16),
          ),
          const SizedBox(height: 4),
          SecondaryButton(
            label: 'Tulis Sendiri',
            onPressed: onWriteSelf,
            icon: const Icon(Icons.edit_outlined, size: 16),
            verticalPadding: 12,
            fontSize: 14,
          ),
        ],
      ),
    );
  }
}

/* ------------------------------------------------------------------ */
/* Photo Gallery (tidak diubah dari versi sebelumnya)                   */
/* ------------------------------------------------------------------ */

class _PhotoGallery extends StatelessWidget {
  final List<String> photos;
  final VoidCallback onPick;
  final ValueChanged<int> onRemove;
  const _PhotoGallery({required this.photos, required this.onPick, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ...photos.asMap().entries.map((e) {
          return Stack(
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: DecorationImage(image: FileImage(File(e.value)), fit: BoxFit.cover),
                  boxShadow: AppShadows.soft,
                ),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: GestureDetector(
                  onTap: () => onRemove(e.key),
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(color: AppColors.destructive, shape: BoxShape.circle),
                    child: const Icon(Icons.close, size: 12, color: AppColors.onPrimary),
                  ),
                ),
              ),
            ],
          );
        }),
        GestureDetector(
          onTap: onPick,
          child: CustomPaint(
            foregroundPainter: const _DashedRRectPainter(color: AppColors.border, radius: 12, strokeWidth: 1.5),
            child: Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_photo_alternate_outlined, size: 24, color: AppColors.muted),
                SizedBox(height: 4),
                Text('Tambah', style: TextStyle(fontSize: 10, color: AppColors.muted)),
              ],
            ),
          ),
          ),
        ),
      ],
    );
  }
}

/// Border putus-putus (dashed) untuk tile "Tambah" — hanya visual.
class _DashedRRectPainter extends CustomPainter {
  final Color color;
  final double radius;
  final double strokeWidth;
  const _DashedRRectPainter({required this.color, required this.radius, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(strokeWidth / 2, strokeWidth / 2, size.width - strokeWidth, size.height - strokeWidth),
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);
    const dash = 5.0;
    const gap = 4.0;
    for (final metric in path.computeMetrics()) {
      double d = 0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, (d + dash).clamp(0, metric.length)), paint);
        d += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRRectPainter old) =>
      old.color != color || old.radius != radius || old.strokeWidth != strokeWidth;
}
