import '../../../data/models/image_variant_link.dart';

/// Urutan galeri: foto tanpa tautan varian lebih dulu, foto bertautan di akhir
/// (stable partition). Sama dengan normalisasi di backend, jadi aman dipakai
/// ulang di klien.
List<String> galleryOrder(List<String> images, List<ImageVariantLink> links) {
  final linkedUrls = links.map((l) => l.url).toSet();
  return [
    ...images.where((u) => !linkedUrls.contains(u)),
    ...images.where((u) => linkedUrls.contains(u)),
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
      if (link.url == images[i] && link.option == option && link.value == value) return i;
    }
  }
  return null;
}
