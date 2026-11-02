import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/models/image_variant_link.dart';
import '../network/upload_api.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../utils/image_helper.dart';
import '../utils/photo_rules.dart';

// ============================================================================
// MODEL
// ============================================================================

/// Satu foto di editor: foto yang sudah ada di server ([url]) atau foto baru
/// yang belum diunggah ([file]). Dapat ditautkan ke satu nilai varian.
class PhotoItem {
  static int _seq = 0;

  /// Kunci unik dan stabil (dipakai untuk drag dan perbandingan perubahan).
  final String key;
  final String? url;
  final XFile? file;
  final String? variantOption;
  final String? variantValue;

  PhotoItem._({
    required this.key,
    this.url,
    this.file,
    this.variantOption,
    this.variantValue,
  });

  factory PhotoItem.existing(String url, {String? option, String? value}) =>
      PhotoItem._(key: 'u${_seq++}', url: url, variantOption: option, variantValue: value);

  factory PhotoItem.picked(XFile file) => PhotoItem._(key: 'n${_seq++}', file: file);

  bool get isNew => file != null;
  bool get isLinked => variantOption != null && variantValue != null;

  PhotoItem withVariant(String option, String value) => PhotoItem._(
        key: key,
        url: url,
        file: file,
        variantOption: option,
        variantValue: value,
      );

  PhotoItem withoutVariant() => PhotoItem._(key: key, url: url, file: file);
}

/// Satu opsi varian beserta nilainya, untuk memilih tautan foto.
class VariantChoice {
  final String option;
  final List<String> values;
  const VariantChoice(this.option, this.values);
}

/// Membangun daftar [PhotoItem] dari respons API (`images` + `imageVariants`).
List<PhotoItem> photoItemsFromServer(List<String> images, List<ImageVariantLink> links) {
  final byUrl = <String, ImageVariantLink>{for (final l in links) l.url: l};
  return normalizePhotoOrder([
    for (final url in images)
      PhotoItem.existing(url, option: byUrl[url]?.option, value: byUrl[url]?.value),
  ]);
}

/// Urutan tampilan = urutan yang dinormalkan backend (stable partition):
/// foto tanpa tautan lebih dulu, foto bertautan di akhir.
List<PhotoItem> normalizePhotoOrder(List<PhotoItem> items) {
  return [
    ...items.where((i) => !i.isLinked),
    ...items.where((i) => i.isLinked),
  ];
}

/// Benar bila kedua daftar identik (kunci, urutan, tautan). Untuk `dirty`.
bool photoListsEqual(List<PhotoItem> a, List<PhotoItem> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i].key != b[i].key ||
        a[i].variantOption != b[i].variantOption ||
        a[i].variantValue != b[i].variantValue) {
      return false;
    }
  }
  return true;
}

// ============================================================================
// SINKRONISASI KE SERVER
// ============================================================================

class PhotoSyncResult {
  /// Daftar lengkap URL `images` sesuai urutan editor.
  final List<String> images;

  /// Daftar lengkap `imageVariants` untuk foto yang bertautan.
  final List<Map<String, String>> imageVariants;

  /// URL yang baru diunggah pada sinkronisasi ini (untuk rollback bila
  /// penyimpanan produk gagal: `UploadApi.deleteUrls(newlyUploaded)`).
  final List<String> newlyUploaded;

  const PhotoSyncResult(this.images, this.imageVariants, this.newlyUploaded);
}

/// Mengunggah semua foto baru (urutan terjaga) lalu menyusun `images` dan
/// `imageVariants`. Melempar galat bila unggah gagal; pada kasus itu tidak ada
/// berkas yang tertinggal (UploadApi sudah membersihkan sebagian yang sempat
/// terunggah).
Future<PhotoSyncResult> syncPhotos(List<PhotoItem> items) async {
  final fresh = items.where((i) => i.file != null).map((i) => i.file!).toList();
  final uploaded = fresh.isEmpty ? <String>[] : await UploadApi.uploadMany(fresh);
  var cursor = 0;
  final images = <String>[];
  final variants = <Map<String, String>>[];
  for (final item in items) {
    final url = item.file != null ? uploaded[cursor++] : item.url!;
    images.add(url);
    if (item.isLinked) {
      variants.add({'url': url, 'option': item.variantOption!, 'value': item.variantValue!});
    }
  }
  return PhotoSyncResult(images, variants, uploaded);
}

// ============================================================================
// WIDGET
// ============================================================================

/// Editor foto: tambah, hapus (ikon X), urutkan (tahan lalu seret, atau tombol
/// geser), jadikan utama, dan tautkan ke varian. Semua perubahan hanya di
/// daftar lokal; tidak ada yang dikirim ke server sebelum pemanggil menyimpan
/// (gunakan [syncPhotos]).
class PhotoEditor extends StatelessWidget {
  final List<PhotoItem> items;
  final ValueChanged<List<PhotoItem>> onChanged;
  final int maxPhotos;

  /// Bila diisi, foto dapat ditautkan ke varian. Null = tanpa fitur varian.
  final List<VariantChoice>? variantChoices;
  final String label;
  final String? helper;

  /// Tombol "Batalkan perubahan" tampil bila [dirty] dan [onReset] ada.
  final bool dirty;
  final VoidCallback? onReset;
  final bool enabled;

  const PhotoEditor({
    super.key,
    required this.items,
    required this.onChanged,
    this.maxPhotos = PhotoRules.maxProductPhotos,
    this.variantChoices,
    this.label = 'Foto',
    this.helper,
    this.dirty = false,
    this.onReset,
    this.enabled = true,
  });

  static const double _gap = 8;

  bool get _variantMode => variantChoices != null && variantChoices!.isNotEmpty;

  // ---- operasi daftar ------------------------------------------------------

  void _remove(PhotoItem item) {
    onChanged(items.where((i) => i.key != item.key).toList());
  }

  void _shift(PhotoItem item, int delta) {
    final list = List<PhotoItem>.of(items);
    final from = list.indexWhere((i) => i.key == item.key);
    final to = from + delta;
    if (from < 0 || to < 0 || to >= list.length) return;
    if (list[to].isLinked != item.isLinked) return;
    final moved = list.removeAt(from);
    list.insert(to, moved);
    onChanged(list);
  }

  void _move(String fromKey, String toKey) {
    final list = List<PhotoItem>.of(items);
    final from = list.indexWhere((i) => i.key == fromKey);
    final to = list.indexWhere((i) => i.key == toKey);
    if (from < 0 || to < 0 || from == to) return;
    if (list[from].isLinked != list[to].isLinked) return;
    final moved = list.removeAt(from);
    list.insert(to, moved);
    onChanged(list);
  }

  void _makeMain(PhotoItem item) {
    if (item.isLinked) return;
    final list = items.where((i) => i.key != item.key).toList();
    list.insert(0, item);
    onChanged(list);
  }

  void _setVariant(PhotoItem item, String option, String value) {
    onChanged(normalizePhotoOrder(
      items.map((i) => i.key == item.key ? i.withVariant(option, value) : i).toList(),
    ));
  }

  void _clearVariant(PhotoItem item) {
    onChanged(normalizePhotoOrder(
      items.map((i) => i.key == item.key ? i.withoutVariant() : i).toList(),
    ));
  }

  Future<void> _add(BuildContext context) async {
    final remaining = maxPhotos - items.length;
    if (remaining <= 0) return;
    final res = await PhotoRules.pickMany(maxCount: remaining);
    if (res.accepted.isNotEmpty) {
      onChanged(normalizePhotoOrder([...items, ...res.accepted.map(PhotoItem.picked)]));
    }
    final msg = res.summary;
    if (msg != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  // ---- lembar aksi ---------------------------------------------------------

  Future<void> _openActions(BuildContext context, PhotoItem item) async {
    final plain = items.where((i) => !i.isLinked).toList();
    final canMakeMain = !item.isLinked && plain.isNotEmpty && plain.first.key != item.key;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetCtx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (canMakeMain)
                ListTile(
                  leading: const Icon(Icons.star_outline, color: AppColors.primary),
                  title: Text('Jadikan foto utama', style: AppTextStyles.body),
                  onTap: () {
                    Navigator.of(sheetCtx).pop();
                    _makeMain(item);
                  },
                ),
              if (_variantMode)
                ListTile(
                  leading: const Icon(Icons.link, color: AppColors.primary),
                  title: Text(item.isLinked ? 'Ganti varian' : 'Tautkan ke varian', style: AppTextStyles.body),
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
                    _clearVariant(item);
                  },
                ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: AppColors.destructive),
                title: Text('Hapus foto', style: AppTextStyles.body.copyWith(color: AppColors.destructive)),
                onTap: () {
                  Navigator.of(sheetCtx).pop();
                  _remove(item);
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
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetCtx) {
        return SafeArea(
          child: SingleChildScrollView(
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
                          selected: item.variantOption == choice.option && item.variantValue == value,
                          onSelected: (_) {
                            Navigator.of(sheetCtx).pop();
                            _setVariant(item, choice.option, value);
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                ],
              ],
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
        return Image(image: provider, fit: BoxFit.cover, width: double.infinity, height: double.infinity);
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
            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
          ),
        );
      },
    );
  }

  Widget _circleButton({required IconData icon, required VoidCallback? onTap, double size = 24}) {
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

  Widget _tileVisual(BuildContext context, PhotoItem item, double size, {bool highlight = false}) {
    final listIndex = items.indexWhere((i) => i.key == item.key);
    final plain = items.where((i) => !i.isLinked).toList();
    final isMain = !item.isLinked && plain.isNotEmpty && plain.first.key == item.key;
    final canLeft = listIndex > 0 && items[listIndex - 1].isLinked == item.isLinked;
    final canRight = listIndex >= 0 && listIndex < items.length - 1 && items[listIndex + 1].isLinked == item.isLinked;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: enabled ? () => _openActions(context, item) : null,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: highlight ? AppColors.primary : AppColors.border,
                    width: highlight ? 2 : 1,
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
                decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(999)),
                child: Text(
                  'Utama',
                  style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.onPrimary),
                ),
              ),
            ),
          if (enabled)
            Positioned(
              right: 6,
              top: 6,
              child: _circleButton(icon: Icons.close, onTap: () => _remove(item)),
            ),
          if (enabled)
            Positioned(
              left: 4,
              top: size / 2 - 11,
              child: _circleButton(
                icon: Icons.chevron_left,
                size: 22,
                onTap: canLeft ? () => _shift(item, -1) : null,
              ),
            ),
          if (enabled)
            Positioned(
              right: 4,
              top: size / 2 - 11,
              child: _circleButton(
                icon: Icons.chevron_right,
                size: 22,
                onTap: canRight ? () => _shift(item, 1) : null,
              ),
            ),
          if (item.isLinked)
            Positioned(
              left: 6,
              right: 6,
              bottom: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.mustard.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${item.variantOption}: ${item.variantValue}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.foreground),
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
      onAcceptWithDetails: (details) => _move(details.data, item.key),
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
          childWhenDragging: Opacity(opacity: 0.25, child: _tileVisual(context, item, size)),
          child: _tileVisual(context, item, size, highlight: candidate.isNotEmpty),
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
              const Icon(Icons.add_photo_alternate_outlined, size: 28, color: AppColors.primary),
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
        child: Text(text, style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600)),
      );

  @override
  Widget build(BuildContext context) {
    final plain = items.where((i) => !i.isLinked).toList();
    final linked = items.where((i) => i.isLinked).toList();
    final showTitles = _variantMode && plain.isNotEmpty && linked.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(label, style: AppTextStyles.label)),
            Text('${items.length}/$maxPhotos foto', style: AppTextStyles.caption),
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
                  if (showTitles) _groupTitle('Foto per varian') else const SizedBox(height: _gap),
                  Wrap(
                    spacing: _gap,
                    runSpacing: _gap,
                    children: [for (final item in linked) _tile(context, item, size)],
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
