import 'package:image_picker/image_picker.dart';
import 'image_variant_link.dart';

/// Satu foto di editor: foto yang sudah ada di server ([url]) atau foto baru
/// yang belum diunggah ([file]). Dapat ditautkan ke satu nilai varian.
class PhotoItem {
  static int _seq = 0;

  /// Kunci unik dan stabil (dipakai untuk drag dan perbandingan perubahan).
  final String key;
  final String? url;
  final XFile? file;
  final Map<String, String>? variantCombination;

  PhotoItem._({
    required this.key,
    this.url,
    this.file,
    this.variantCombination,
  });

  factory PhotoItem.existing(String url, {Map<String, String>? combination}) =>
      PhotoItem._(key: 'u${_seq++}', url: url, variantCombination: combination);

  factory PhotoItem.picked(XFile file) => PhotoItem._(key: 'n${_seq++}', file: file);

  bool get isNew => file != null;
  bool get isLinked => variantCombination != null && variantCombination!.isNotEmpty;

  PhotoItem withVariant(Map<String, String> combination) => PhotoItem._(
        key: key,
        url: url,
        file: file,
        variantCombination: combination,
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
      PhotoItem.existing(url, combination: byUrl[url]?.combination.isEmpty == true ? null : byUrl[url]?.combination.map((e) => MapEntry(e['option']!, e['value']!)).fold<Map<String, String>>({}, (m, e) => m..[e.key] = e.value)),
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
    if (a[i].key != b[i].key || !_combinationsEqual(a[i].variantCombination, b[i].variantCombination)) {
      return false;
    }
  }
  return true;
}

bool _combinationsEqual(Map<String, String>? a, Map<String, String>? b) {
  if (identical(a, b)) return true;
  if (a == null || b == null || a.length != b.length) return false;
  return a.entries.every((e) => b[e.key] == e.value);
}

class PhotoSyncResult {
  /// Daftar lengkap URL `images` sesuai urutan editor.
  final List<String> images;

  /// Daftar lengkap `imageVariants` untuk foto yang bertautan.
  final List<Map<String, dynamic>> imageVariants;

  /// URL yang baru diunggah pada sinkronisasi ini (untuk rollback bila
  /// penyimpanan produk gagal: `UploadService.deleteUrls(newlyUploaded)`).
  final List<String> newlyUploaded;

  const PhotoSyncResult(this.images, this.imageVariants, this.newlyUploaded);
}

