import 'package:flutter/foundation.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/viewmodel/photo_editor_view_model.dart';
import '../../../data/models/creator_application_model.dart';
import '../../../data/repositories/application_repository.dart';
import '../../../data/services/upload_service.dart';
import '../../auth/viewmodel/auth_view_model.dart';

class ApplicationFormViewModel extends ChangeNotifier {
  ApplicationFormViewModel({required ApplicationRepository repository,
    required AuthViewModel auth, required UploadService uploadService,
    PhotoPicker? pickMany})
      : _repository = repository, _auth = auth, _uploadService = uploadService,
        photos = PhotoEditorViewModel(uploadService: uploadService, pickMany: pickMany),
        _applicantName = auth.user?.name ?? '' {
    photos.addListener(_photosChanged);
  }

  final ApplicationRepository _repository;
  final AuthViewModel _auth;
  final UploadService _uploadService;
  final PhotoEditorViewModel photos;
  String _applicantName;
  String _contact = '';
  String _brandName = '';
  String _description = '';
  String? _categoryId;
  String? _brandError;
  String? _photoError;
  String? _actionError;
  String? _loadError;
  bool _isSubmitting = false;
  bool _disposed = false;
  int _loadId = 0;

  String get applicantName => _applicantName;
  String get contact => _contact;
  String get brandName => _brandName;
  String get description => _description;
  String? get categoryId => _categoryId;
  String? get brandError => _brandError;
  String? get photoError => _photoError;
  String? get actionError => _actionError;
  String? get loadError => _loadError;
  bool get isSubmitting => _isSubmitting;

  void setApplicantName(String value) { _applicantName = value; }
  void setContact(String value) { _contact = value; }
  void setDescription(String value) { _description = value; }
  void setBrandName(String value) { _brandName = value; _brandError = null; _notify(); }
  void setCategoryId(String? value) { _categoryId = value; _notify(); }

  void _photosChanged() {
    if (photos.items.isNotEmpty) _photoError = null;
    _notify();
  }

  /// Layar menentukan navigasi, VM menentukan apakah pengajuan masih pending.
  Future<bool> loadPendingApplication() async {
    if (!_auth.isAuthenticated || _disposed) return false;
    final id = ++_loadId;
    final userId = _auth.user?.id;
    _loadError = null;
    try {
      final applications = await _repository.getMine();
      if (_disposed || id != _loadId || userId != _auth.user?.id) return false;
      final mine = applications.where((a) => a.userId == userId).toList()
        ..sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
      return mine.isNotEmpty && mine.first.status == ApplicationStatus.pending;
    } catch (e) {
      if (!_disposed && id == _loadId) { _loadError = e.toString(); _notify(); }
      return false;
    }
  }

  bool _validate() {
    if (_applicantName.trim().isEmpty || _description.trim().isEmpty) {
      _actionError = 'Lengkapi nama lengkap dan deskripsi produk';
    } else if (!RegExp(r'^(?:\+62|62|0)[0-9]{8,13}$').hasMatch(_contact.trim())) {
      _actionError = 'Masukkan nomor WhatsApp yang valid, misalnya 081234567890';
    } else if (photos.items.isEmpty) {
      _photoError = 'Minimal 1 foto sampel produk';
      _actionError = _photoError;
    }
    return _actionError == null;
  }

  Future<bool> submit() async {
    if (_disposed || _isSubmitting || !_auth.isAuthenticated || !_auth.isBuyer) return false;
    _actionError = null;
    if (!_validate()) { _notify(); return false; }
    final applicantName = _applicantName.trim();
    final contact = _contact.trim();
    final brandName = _brandName.trim();
    final description = _description.trim();
    final categoryId = _categoryId;
    final userId = _auth.user?.id;
    _isSubmitting = true;
    _brandError = null;
    _photoError = null;
    _notify();

    PhotoSyncResult? sync;
    try {
      try {
        sync = await photos.sync();
      } on ApiException catch (e) {
        if (e.code == 'IMAGE_REJECTED') {
          _actionError = 'Ada foto yang tidak pantas. Hapus foto bertanda merah lalu coba lagi.';
        } else if (e.code == 'MODERATION_UNAVAILABLE') {
          _actionError = 'Pemeriksaan foto sedang tidak tersedia. Coba lagi nanti.';
        } else {
          _actionError = 'Foto sampel gagal diunggah: ${e.message}';
        }
        return false;
      } catch (e) {
        _actionError = 'Foto sampel gagal diunggah: $e';
        return false;
      }
      if (_disposed || userId != _auth.user?.id) {
        await _uploadService.deleteUrls(sync.newlyUploaded);
        return false;
      }
      final app = await _repository.apply(
        applicantName: applicantName, contact: contact,
        brandName: brandName.isEmpty ? null : brandName,
        description: description, categoryId: categoryId,
        samplePhotos: sync.images,
        sampleFileUrl: sync.images.isNotEmpty ? sync.images.first : null,
      );
      // Penyimpanan sudah berhasil: jangan rollback URL yang sudah terpasang.
      if (userId == _auth.user?.id) _auth.setApplication(app.id);
      return true;
    } on ApiException catch (e) {
      if (sync != null && sync.newlyUploaded.isNotEmpty) {
        await _uploadService.deleteUrls(sync.newlyUploaded);
      }
      if (e.code == 'BRAND_NAME_TAKEN' || e.code == 'BRAND_NAME_INVALID') {
        _brandError = e.message;
      } else { _actionError = e.message; }
      return false;
    } catch (e) {
      if (sync != null && sync.newlyUploaded.isNotEmpty) {
        await _uploadService.deleteUrls(sync.newlyUploaded);
      }
      _actionError = 'Gagal mengirim pengajuan: $e';
      return false;
    } finally {
      _isSubmitting = false;
      _notify();
    }
  }

  void _notify() { if (!_disposed) notifyListeners(); }
  @override
  void dispose() {
    _disposed = true;
    _loadId++;
    photos.removeListener(_photosChanged);
    photos.dispose();
    super.dispose();
  }
}
