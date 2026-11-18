import 'package:flutter/foundation.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/viewmodel/photo_editor_view_model.dart';
import '../../../data/repositories/story_repository.dart';
import '../../../data/services/upload_service.dart';

class StoryFormViewModel extends ChangeNotifier {
  StoryFormViewModel({required this.productId, required StoryRepository repository,
    required UploadService uploads, required this.photos})
      : _repository = repository, _uploads = uploads;
  final String productId;
  final StoryRepository _repository;
  final UploadService _uploads;
  final PhotoEditorViewModel photos;
  String _title = '', _content = '', _process = '', _productName = '';
  String? _actionError, _errorMessage;
  bool _isLoading = false, _isSaving = false, _disposed = false;
  int _requestId = 0;
  String get title => _title;
  String get content => _content;
  String get process => _process;
  String get productName => _productName;
  String? get actionError => _actionError;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  // Pertahankan penentuan mode lama berdasarkan judul form saat ini.
  bool get isEdit => _title.isNotEmpty;
  String get successMessage => isEdit
      ? 'Cerita "$_title" diperbarui' : 'Cerita "$_title" ditambahkan';

  void updateFields({required String title, required String content, required String process}) {
    _title = title; _content = content; _process = process;
  }

  Future<void> load() async {
    if (_disposed || productId.isEmpty) return;
    final id = ++_requestId;
    _isLoading = true;
    _errorMessage = null;
    _notify();
    try {
      final products = await _repository.getMine();
      if (_disposed || id != _requestId) return;
      for (final product in products) {
        if (product.id != productId) continue;
        _productName = product.name;
        _title = product.story?.title ?? '';
        _content = product.story?.body ?? '';
        _process = product.story?.process ?? '';
        photos.setInitialItems(photoItemsFromServer(product.story?.processImages ?? [], const []));
        break;
      }
    } catch (e) {
      if (!_disposed && id == _requestId) _errorMessage = e.toString();
    } finally {
      if (!_disposed && id == _requestId) { _isLoading = false; _notify(); }
    }
  }

  Future<bool> submit() async {
    if (_disposed || _isSaving || _isLoading) return false;
    _actionError = null;
    if (_title.trim().isEmpty || _content.trim().isEmpty) {
      _actionError = 'Judul dan isi cerita wajib diisi';
      _notify();
      return false;
    }
    _isSaving = true;
    _notify();
    PhotoSyncResult? sync;
    try {
      try {
        sync = await photos.sync();
      } on ApiException catch (e) {
        _actionError = 'Foto gagal diunggah: ${e.message}';
        return false;
      } catch (e) {
        _actionError = 'Foto gagal diunggah: $e';
        return false;
      }
      if (_disposed) {
        await _uploads.deleteUrls(sync.newlyUploaded);
        return false;
      }
      await _repository.saveStory(productId: productId, title: _title.trim(),
        content: _content.trim(), process: _process.trim().isNotEmpty ? _process.trim() : null,
        processImages: sync.images);
      return true;
    } catch (e) {
      if (sync != null && sync.newlyUploaded.isNotEmpty) {
        await _uploads.deleteUrls(sync.newlyUploaded);
      }
      _actionError = 'Gagal menyimpan cerita: $e';
      return false;
    } finally {
      _isSaving = false;
      _notify();
    }
  }
  void _notify() { if (!_disposed) notifyListeners(); }
  @override
  void dispose() { _disposed = true; _requestId++; photos.dispose(); super.dispose(); }
}
