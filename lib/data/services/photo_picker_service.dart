import 'package:image_picker/image_picker.dart';
import '../../core/utils/photo_rules.dart';

/// Pemilihan berkas platform; aturan MIME dan ukuran tetap di PhotoRules.
class PhotoPickerService {
  PhotoPickerService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();
  final ImagePicker _picker;

  Future<PickedPhotos> pickOne() async {
    final file = await _picker.pickImage(source: ImageSource.gallery,
      maxWidth: PhotoRules.pickMaxWidth, imageQuality: PhotoRules.pickQuality);
    if (file == null) return const PickedPhotos([], []);
    return _filter([file]);
  }

  Future<PickedPhotos> pickMany({required int maxCount}) async {
    if (maxCount <= 0) {
      return const PickedPhotos([], ['Jumlah foto sudah mencapai batas.']);
    }
    if (maxCount == 1) return pickOne();
    final picked = await _picker.pickMultiImage(maxWidth: PhotoRules.pickMaxWidth,
      imageQuality: PhotoRules.pickQuality, limit: maxCount);
    final result = await _filter(picked.take(maxCount).toList());
    return PickedPhotos(result.accepted, [...result.errors,
      if (picked.length > maxCount) 'Maksimal $maxCount foto. Sisanya diabaikan.']);
  }

  Future<PickedPhotos> _filter(List<XFile> files) async {
    final accepted = <XFile>[];
    final errors = <String>[];
    for (final file in files) {
      final error = await PhotoRules.validatePhoto(file);
      if (error == null) { accepted.add(file); }
      else { errors.add('${file.name}: $error'); }
    }
    return PickedPhotos(accepted, errors);
  }
}
