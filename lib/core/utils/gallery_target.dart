import '../../data/models/image_variant_link.dart';

/// Urutan galeri: foto tanpa tautan varian lebih dulu, foto bertautan di akhir
/// (stable partition). Sama dengan normalisasi di backend, jadi aman dipakai
/// ulang di klien.
List<String> galleryOrder(
  List<String> images,
  List<ImageVariantLink> links, {
  List<String> optionNames = const [],
  List<List<String>> optionValues = const [],
}) {
  final linkedUrls = links.map((l) => l.url).toSet();
  final originalIndex = {for (var i = 0; i < images.length; i++) images[i]: i};
  final linkByUrl = {for (final link in links) link.url: link};

  int compareLinked(String a, String b) {
    final aLink = linkByUrl[a];
    final bLink = linkByUrl[b];
    if (aLink == null || bLink == null) return originalIndex[a]!.compareTo(originalIndex[b]!);
    for (var axis = 0; axis < optionNames.length; axis++) {
      final option = optionNames[axis];
      Map<String, String>? partFor(ImageVariantLink link) {
        for (final part in link.combination) {
          if (part['option'] == option) return part;
        }
        return null;
      }
      final values = axis < optionValues.length ? optionValues[axis] : const <String>[];
      final aPart = partFor(aLink);
      final bPart = partFor(bLink);
      final aRank = aPart == null ? values.length + 1 : values.indexOf(aPart['value'] ?? '');
      final bRank = bPart == null ? values.length + 1 : values.indexOf(bPart['value'] ?? '');
      final normalizedA = aRank < 0 ? values.length : aRank;
      final normalizedB = bRank < 0 ? values.length : bRank;
      if (normalizedA != normalizedB) return normalizedA.compareTo(normalizedB);
    }
    return originalIndex[a]!.compareTo(originalIndex[b]!);
  }

  final linked = images.where(linkedUrls.contains).toList()..sort(compareLinked);
  return [
    ...images.where((u) => !linkedUrls.contains(u)),
    ...linked,
  ];
}

/// Indeks terendah yang nilainya berbeda antara dua pilihan varian. Pilihan
/// pada opsi tertentu mereset opsi sesudahnya, jadi indeks terendah yang
/// berubah adalah opsi yang benar-benar diubah pembeli. Null bila tak berubah.
int? changedAxisBetween(List<String?> before, List<String?> after) {
  final n = before.length < after.length ? before.length : after.length;
  for (var i = 0; i < n; i++) {
    if (before[i] != after[i]) return i;
  }
  return null;
}

/// Indeks foto (pada [images] yang SUDAH berurutan tampil) yang harus
/// ditampilkan setelah pembeli mengubah opsi [changedAxis]: foto pertama yang
/// tertaut ke nilai terpilih opsi itu. Null bila tidak ada foto tertaut, yaitu
/// galeri tidak berpindah.
int? galleryTargetIndex({
  required List<String> images,
  required List<ImageVariantLink> links,
  required List<String> optionNames,
  required List<String?> selected,
  required int? changedAxis,
}) {
  if (changedAxis == null) return null;
  if (changedAxis < 0 || changedAxis >= optionNames.length || changedAxis >= selected.length) {
    return null;
  }
  final value = selected[changedAxis];
  if (value == null) return null;
  final option = optionNames[changedAxis];
  for (var i = 0; i < images.length; i++) {
    for (final link in links) {
      final matchesCombination = link.combination.any((pair) => pair['option'] == option && pair['value'] == value);
      final matchesLegacy = link.option == option && link.value == value;
      if (link.url == images[i] && (matchesCombination || matchesLegacy)) return i;
    }
  }
  return null;
}
