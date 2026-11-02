import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';

/// Hasil memilih foto: yang lolos validasi dan pesan untuk yang ditolak.
class PickedPhotos {
  final List<XFile> accepted;
  final List<String> errors;
  const PickedPhotos(this.accepted, this.errors);

  /// Satu kalimat ringkas untuk snackbar, atau null bila tidak ada galat.
  String? get summary {
    if (errors.isEmpty) return null;
    final extra = errors.length - 1;
    return extra > 0 ? '${errors.first} (+$extra foto lain ditolak)' : errors.first;
  }
}

/// Aturan foto sisi klien. Selaras dengan kontrak upload (API_CONTRACT v1.7,
/// Bagian 8): hanya JPEG/PNG/WebP, maksimal 2 MB, maksimal 10 berkas per
/// panggilan. Tipe berkas dinilai dari BYTE AWAL, bukan dari ekstensi, karena
/// image_picker dengan imageQuality dapat meng-encode ulang berkas sehingga
/// ekstensi `.png` bisa berisi JPEG.
class PhotoRules {
  PhotoRules._();

  static const int maxBytes = 2 * 1024 * 1024;
  static const int maxPerCall = 10;
  static const int maxProductPhotos = 10;
  static const int maxStoryProcessPhotos = 10;
  static const int maxSamplePhotos = 10;

  /// Dipakai saat memilih foto (pengecilan di sisi klien).
  static const double pickMaxWidth = 1600;
  static const int pickQuality = 80;

  static const String msgFormat = 'Format foto tidak didukung. Gunakan JPG, PNG, atau WebP.';
  static const String msgSize = 'Ukuran foto maksimal 2 MB.';
  static const String msgUnreadable = 'Foto tidak dapat dibaca.';

  /// MIME dari byte awal; null bila bukan JPEG/PNG/WebP.
  static String? detectMimeFromBytes(Uint8List b) {
    if (b.length >= 3 && b[0] == 0xFF && b[1] == 0xD8 && b[2] == 0xFF) {
      return 'image/jpeg';
    }
    if (b.length >= 8 &&
        b[0] == 0x89 &&
        b[1] == 0x50 &&
        b[2] == 0x4E &&
        b[3] == 0x47 &&
        b[4] == 0x0D &&
        b[5] == 0x0A &&
        b[6] == 0x1A &&
        b[7] == 0x0A) {
      return 'image/png';
    }
    if (b.length >= 12 &&
        b[0] == 0x52 && // R
        b[1] == 0x49 && // I
        b[2] == 0x46 && // F
        b[3] == 0x46 && // F
        b[8] == 0x57 && // W
        b[9] == 0x45 && // E
        b[10] == 0x42 && // B
        b[11] == 0x50) {
      // P
      return 'image/webp';
    }
    return null;
  }

  static String extensionFor(String mime) {
    switch (mime) {
      case 'image/png':
        return 'png';
      case 'image/webp':
        return 'webp';
      default:
        return 'jpg';
    }
  }

  static Future<Uint8List> _readHead(XFile file, int count) async {
    try {
      final builder = BytesBuilder(copy: false);
      await for (final chunk in file.openRead(0, count)) {
        builder.add(chunk);
        if (builder.length >= count) break;
      }
      return builder.takeBytes();
    } catch (_) {
      // Cadangan (mis. platform yang belum mendukung openRead).
      final all = await file.readAsBytes();
      final end = all.length < count ? all.length : count;
      return Uint8List.fromList(all.sublist(0, end));
    }
  }

  /// Tipe berkas dari byte awal: `image/jpeg`, `image/png`, `image/webp`, atau null.
  static Future<String?> detectPhotoType(XFile file) async {
    try {
      return detectMimeFromBytes(await _readHead(file, 12));
    } catch (_) {
      return null;
    }
  }

  /// Mengembalikan pesan galat (Indonesia) atau null bila foto sah.
  static Future<String?> validatePhoto(XFile file) async {
    final String? type = await detectPhotoType(file);
    if (type == null) return msgFormat;
    int size;
    try {
      size = await file.length();
    } catch (_) {
      return msgUnreadable;
    }
    if (size > maxBytes) return msgSize;
    return null;
  }

  static Future<PickedPhotos> _filter(List<XFile> files) async {
    final accepted = <XFile>[];
    final errors = <String>[];
    for (final f in files) {
      final err = await validatePhoto(f);
      if (err == null) {
        accepted.add(f);
      } else {
        errors.add('${f.name}: $err');
      }
    }
    return PickedPhotos(accepted, errors);
  }

  /// Pilih satu foto dari galeri (sudah dikecilkan dan divalidasi).
  static Future<PickedPhotos> pickOne() async {
    final XFile? f = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: pickMaxWidth,
      imageQuality: pickQuality,
    );
    if (f == null) return const PickedPhotos(<XFile>[], <String>[]);
    return _filter([f]);
  }

  /// Pilih beberapa foto dari galeri, paling banyak [maxCount].
  static Future<PickedPhotos> pickMany({required int maxCount}) async {
    if (maxCount <= 0) {
      return const PickedPhotos(<XFile>[], <String>['Jumlah foto sudah mencapai batas.']);
    }
    if (maxCount == 1) return pickOne();
    final List<XFile> picked = await ImagePicker().pickMultiImage(
      maxWidth: pickMaxWidth,
      imageQuality: pickQuality,
      limit: maxCount,
    );
    if (picked.isEmpty) return const PickedPhotos(<XFile>[], <String>[]);
    final extra = <String>[];
    var list = picked;
    if (picked.length > maxCount) {
      list = picked.sublist(0, maxCount);
      extra.add('Maksimal $maxCount foto. Sisanya diabaikan.');
    }
    final res = await _filter(list);
    return PickedPhotos(res.accepted, [...res.errors, ...extra]);
  }
}
