import 'package:image_picker/image_picker.dart';

abstract interface class UploadRepository {
  Future<String> uploadOne(XFile file);
  Future<List<String>> uploadMany(List<XFile> files);
  Future<void> deleteUrls(Iterable<String> urls);
}
