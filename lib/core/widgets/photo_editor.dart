import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../viewmodel/photo_editor_view_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../utils/image_helper.dart';
import 'photo_viewer.dart';

export '../../data/models/photo_item.dart';
export '../viewmodel/photo_editor_view_model.dart' show PhotoEditorViewModel;

class PhotoEditor extends StatefulWidget {
  final PhotoEditorViewModel? viewModel;
  final List<PhotoItem>? items;
  final ValueChanged<List<PhotoItem>>? onChanged;
  final int maxPhotos;
  final List<VariantChoice>? variantChoices;
  final String label;
  final String? helper;
  final bool dirty;
  final VoidCallback? onReset;
  final bool enabled;
  final Set<String>? rejectedKeys;

  const PhotoEditor(
      {super.key,
      required this.viewModel,
      this.items,
      this.onChanged,
      this.maxPhotos = 10,
      this.variantChoices,
      this.label = 'Foto',
      this.helper,
      this.dirty = false,
      this.onReset,
      this.enabled = true,
      this.rejectedKeys})
      : assert(viewModel != null);

  @override
  State<PhotoEditor> createState() => _PhotoEditorState();
}

class _PhotoEditorState extends State<PhotoEditor> {
  late PhotoEditorViewModel _vm;
  void _attach() {
    _vm = widget.viewModel!;
    _vm.addListener(_changed);
  }

  void _detach() {
    _vm.removeListener(_changed);
  }

  @override
  void initState() {
    super.initState();
    _attach();
  }

  @override
  void didUpdateWidget(covariant PhotoEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.viewModel != widget.viewModel) {
      _vm.removeListener(_changed);
      _attach();
    }
  }

  void _changed() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  void dispose() {
    _detach();
    super.dispose();
  }

  List<PhotoItem> get items => _vm.items;
  int get maxPhotos => _vm.maxPhotos;
  List<VariantChoice>? get variantChoices => widget.variantChoices;
  String get label => widget.label;
  String? get helper => widget.helper;
  bool get dirty => _vm.dirty;
  VoidCallback? get onReset => _vm.reset;
  bool get enabled => widget.enabled;
  Set<String>? get rejectedKeys => widget.rejectedKeys ?? _vm.rejectedKeys;
  static const double _gap = 8;
  bool get _variantMode => variantChoices != null && variantChoices!.isNotEmpty;

  Future<void> _add(BuildContext context) async {
    final message = await _vm.add();
    if (message != null && context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) => _buildContent(context);

  // ---- lembar aksi ---------------------------------------------------------

  Future<void> _openActions(BuildContext context, PhotoItem item) async {
    final plain = items.where((i) => !i.isLinked).toList();
    final canMakeMain =
        !item.isLinked && plain.isNotEmpty && plain.first.key != item.key;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetCtx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (canMakeMain)
                ListTile(
                  leading:
                      const Icon(Icons.star_outline, color: AppColors.primary),
                  title: Text('Jadikan foto utama', style: AppTextStyles.body),
                  onTap: () {
                    Navigator.of(sheetCtx).pop();
                    _vm.makeMain(item);
                  },
                ),
              if (_variantMode)
                ListTile(
                  leading: const Icon(Icons.link, color: AppColors.primary),
                  title: Text(
                      item.isLinked ? 'Ganti varian' : 'Tautkan ke varian',
                      style: AppTextStyles.body),
                  onTap: () {
                    Navigator.of(sheetCtx).pop();
                    _openVariantPicker(context, item);
                  },
                ),
              if (_variantMode && item.isLinked)
                ListTile(
                  leading: const Icon(Icons.link_off, color: AppColors.muted),
                  title: Text('Lepas tautan varian', style: AppTextStyles.body),
                  onTap: () {
                    Navigator.of(sheetCtx).pop();
                    _vm.clearVariant(item);
                  },
                ),
              ListTile(
                leading: const Icon(Icons.delete_outline,
                    color: AppColors.destructive),
                title: Text('Hapus foto',
                    style: AppTextStyles.body
                        .copyWith(color: AppColors.destructive)),
                onTap: () {
                  Navigator.of(sheetCtx).pop();
                  _vm.remove(item);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openVariantPicker(BuildContext context, PhotoItem item) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetCtx) {
        final selected = <String, String>{...?item.variantCombination};
        return SafeArea(
          child: StatefulBuilder(
            builder: (context, setSheetState) => SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Tautkan foto ke varian', style: AppTextStyles.h3),
                  const SizedBox(height: 4),
                  Text(
                    'Saat pembeli memilih varian ini, galeri berpindah ke foto ini.',
                    style: AppTextStyles.caption,
                  ),
                  const SizedBox(height: 12),
                  for (final choice in variantChoices!) ...[
                    Text(choice.option, style: AppTextStyles.label),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final value in choice.values)
                          ChoiceChip(
                            label: Text(value),
                            selected: selected[choice.option] == value,
                            onSelected: (_) {
                              setSheetState(
                                  () => selected[choice.option] = value);
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                  ],
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: selected.length == variantChoices!.length
                          ? () {
                              Navigator.of(sheetCtx).pop();
                              _vm.setVariant(item, selected);
                            }
                          : null,
                      child: const Text('Simpan tautan varian'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ---- tampilan ------------------------------------------------------------

  Widget _thumb(PhotoItem item) {
    if (item.file != null) {
      final provider = safeImageProvider(item.file!.path);
      if (provider != null) {
        return Image(
            image: provider,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity);
      }
    }
    return Image.network(
      item.url ?? '',
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (_, __, ___) => Container(
        color: AppColors.surfaceAlt,
        alignment: Alignment.center,
        child: const Icon(Icons.broken_image_outlined, color: AppColors.muted),
      ),
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Container(
          color: AppColors.surfaceAlt,
          alignment: Alignment.center,
          child: const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: AppColors.primary),
          ),
        );
      },
    );
  }

  Widget _circleButton(
      {required IconData icon,
      required VoidCallback? onTap,
      double size = 24}) {
    final active = onTap != null;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Opacity(
        opacity: active ? 1 : 0.3,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: AppColors.foreground.withValues(alpha: 0.6),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: size * 0.65, color: AppColors.onPrimary),
        ),
      ),
    );
  }

  Widget _tileVisual(BuildContext context, PhotoItem item, double size,
      {bool highlight = false}) {
    final listIndex = items.indexWhere((i) => i.key == item.key);
    final plain = items.where((i) => !i.isLinked).toList();
    final isMain =
        !item.isLinked && plain.isNotEmpty && plain.first.key == item.key;
    final canLeft =
        listIndex > 0 && items[listIndex - 1].isLinked == item.isLinked;
    final canRight = listIndex >= 0 &&
        listIndex < items.length - 1 &&
        items[listIndex + 1].isLinked == item.isLinked;
    final isRejected = rejectedKeys != null && rejectedKeys!.contains(item.key);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () {
                final imageProviders = items.map<ImageProvider>((e) {
                  if (e.file != null) {
                    final provider = safeImageProvider(e.file!.path);
                    if (provider != null) return provider;
                  }
                  return NetworkImage(e.url ?? '');
                }).toList();
                final initialIdx = items.indexWhere((i) => i.key == item.key);
                showPhotoViewer(
                  context,
                  images: imageProviders,
                  initialIndex: initialIdx >= 0 ? initialIdx : 0,
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isRejected
                        ? AppColors.destructive
                        : (highlight ? AppColors.primary : AppColors.border),
                    width: isRejected ? 2.5 : (highlight ? 2 : 1),
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: _thumb(item),
              ),
            ),
          ),
          if (isMain)
            Positioned(
              left: 6,
              top: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(999)),
                child: Text(
                  'Utama',
                  style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onPrimary),
                ),
              ),
            ),
          if (isRejected)
            Positioned(
              left: isMain ? 58 : 6,
              top: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                    color: AppColors.destructive,
                    borderRadius: BorderRadius.circular(999)),
                child: Text(
                  'Ditolak',
                  style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.white),
                ),
              ),
            ),
          if (enabled)
            Positioned(
              right: 6,
              top: 6,
              child: _circleButton(
                  icon: Icons.close, onTap: () => _vm.remove(item)),
            ),
          if (enabled)
            Positioned(
              left: 4,
              top: size / 2 - 11,
              child: _circleButton(
                icon: Icons.chevron_left,
                size: 22,
                onTap: canLeft ? () => _vm.shift(item, -1) : null,
              ),
            ),
          if (enabled)
            Positioned(
              right: 4,
              top: size / 2 - 11,
              child: _circleButton(
                icon: Icons.chevron_right,
                size: 22,
                onTap: canRight ? () => _vm.shift(item, 1) : null,
              ),
            ),
          if (enabled)
            Positioned(
              right: 6,
              bottom: 6,
              child: _circleButton(
                icon: Icons.more_horiz,
                size: 24,
                onTap: () => _openActions(context, item),
              ),
            ),
          if (item.isLinked)
            Positioned(
              left: 6,
              right: enabled ? 34 : 6,
              bottom: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.mustard.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  item.variantCombination!.entries
                      .map((e) => '${e.key}: ${e.value}')
                      .join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.foreground),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _tile(BuildContext context, PhotoItem item, double size) {
    if (!enabled) return _tileVisual(context, item, size);
    return DragTarget<String>(
      onWillAcceptWithDetails: (details) {
        if (details.data == item.key) return false;
        final from = items.where((i) => i.key == details.data).toList();
        return from.isNotEmpty && from.first.isLinked == item.isLinked;
      },
      onAcceptWithDetails: (details) => _vm.move(details.data, item.key),
      builder: (ctx, candidate, rejected) {
        return LongPressDraggable<String>(
          data: item.key,
          delay: const Duration(milliseconds: 250),
          onDragStarted: () => HapticFeedback.selectionClick(),
          feedback: Material(
            color: Colors.transparent,
            child: Opacity(
              opacity: 0.9,
              child: SizedBox(
                width: size,
                height: size,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.primary, width: 2),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _thumb(item),
                ),
              ),
            ),
          ),
          childWhenDragging:
              Opacity(opacity: 0.25, child: _tileVisual(context, item, size)),
          child:
              _tileVisual(context, item, size, highlight: candidate.isNotEmpty),
        );
      },
    );
  }

  Widget _addTile(BuildContext context, double size) {
    final full = items.length >= maxPhotos;
    return GestureDetector(
      onTap: (!enabled || full) ? null : () => _add(context),
      child: Opacity(
        opacity: (!enabled || full) ? 0.4 : 1,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border, width: 1.5),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.add_photo_alternate_outlined,
                  size: 28, color: AppColors.primary),
              const SizedBox(height: 4),
              Text('Tambah', style: AppTextStyles.caption),
            ],
          ),
        ),
      ),
    );
  }

  Widget _groupTitle(String text) => Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 6),
        child: Text(text,
            style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600)),
      );

  Widget _buildContent(BuildContext context) {
    final plain = items.where((i) => !i.isLinked).toList();
    final linked = items.where((i) => i.isLinked).toList();
    final showTitles = _variantMode && plain.isNotEmpty && linked.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(label, style: AppTextStyles.label)),
            Text('${items.length}/$maxPhotos foto',
                style: AppTextStyles.caption),
          ],
        ),
        if (helper != null) ...[
          const SizedBox(height: 2),
          Text(helper!, style: AppTextStyles.caption),
        ],
        if (dirty && onReset != null)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: enabled ? onReset : null,
              child: const Text('Batalkan perubahan'),
            ),
          ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, c) {
            final size = (c.maxWidth - _gap * 2) / 3;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showTitles) _groupTitle('Foto umum'),
                Wrap(
                  spacing: _gap,
                  runSpacing: _gap,
                  children: [
                    for (final item in plain) _tile(context, item, size),
                    _addTile(context, size),
                  ],
                ),
                if (linked.isNotEmpty) ...[
                  if (showTitles)
                    _groupTitle('Foto per varian')
                  else
                    const SizedBox(height: _gap),
                  Wrap(
                    spacing: _gap,
                    runSpacing: _gap,
                    children: [
                      for (final item in linked) _tile(context, item, size)
                    ],
                  ),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}
