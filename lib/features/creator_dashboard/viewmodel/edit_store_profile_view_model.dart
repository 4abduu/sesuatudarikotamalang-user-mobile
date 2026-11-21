import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/utils/photo_rules.dart';
import '../../../data/repositories/catalog_repositories.dart';
import '../../../data/repositories/upload_repository.dart';
import '../../auth/viewmodel/auth_view_model.dart';

class EditStoreProfileViewModel extends ChangeNotifier {
  EditStoreProfileViewModel({required ArtisanRepository repository, required UploadRepository upload, required AuthViewModel auth, Future<PickedPhotos> Function()? pickPhoto})
      : _repository = repository, _upload = upload, _auth = auth, _pickPhoto = pickPhoto ?? PhotoRules.pickOne;
  final ArtisanRepository _repository;
  final UploadRepository _upload;
  final AuthViewModel _auth;
  final Future<PickedPhotos> Function() _pickPhoto;
  static const int nameMax = 191;
  static const int bioMax = 2000;
  bool _disposed = false;
  bool _loading = true;
  bool _saving = false;
  String? _loadError;
  String? _nameError;
  String? _actionError;
  String _name = '';
  String _bio = '';
  String _initialName = '';
  String _initialBio = '';
  String? _effectiveAvatarUrl;
  String? _ownAvatarUrl;
  XFile? _newPhoto;
  bool _removeOwn = false;
  int _requestId = 0;
  bool get isLoading => _loading;
  bool get isSaving => _saving;
  String? get loadError => _loadError;
  String? get nameError => _nameError;
  String? get actionError => _actionError;
  String get name => _name;
  String get bio => _bio;
  XFile? get newPhoto => _newPhoto;
  bool get removeOwn => _removeOwn;
  String get accountName => (_auth.user?.name ?? '').trim();
  String? get accountAvatar => _auth.user?.avatarUrl;
  String? get shownAvatar => _removeOwn ? accountAvatar : _effectiveAvatarUrl;
  bool get canRemove => _ownAvatarUrl != null && !_removeOwn && _newPhoto == null;
  bool get isDirty {
    if (_loading || _loadError != null) return false;
    final trimmed = _name.trim();
    final effective = trimmed.isEmpty ? accountName : trimmed;
    return effective != _initialName || _bio.trim() != _initialBio.trim() || _newPhoto != null || _removeOwn;
  }
  void setName(String value) { if (_saving || _disposed) return; _name = value; _nameError = null; _notify(); }
  void setBio(String value) { if (_saving || _disposed) return; _bio = value; _notify(); }
  void cancelPhoto() { if (_saving || _disposed) return; _newPhoto = null; _notify(); }
  void setRemoveOwn(bool value) { if (_saving || _disposed) return; _removeOwn = value; _notify(); }

  Future<void> load() async {
    if (_disposed || _saving) return;
    final id = ++_requestId;
    _loading = true;
    _loadError = null;
    _notify();
    try {
      final a = await _repository.getMine();
      if (_disposed || id != _requestId) return;
      if (a == null) throw ApiException(404, 'Profil toko tidak ditemukan');
      _initialName = a.name;
      _initialBio = a.bio;
      _effectiveAvatarUrl = a.avatarUrl;
      _ownAvatarUrl = a.ownAvatarUrl;
      _resetDraft();
    } on ApiException catch (e) {
      if (_disposed || id != _requestId) return;
      _loadError = e.message;
    } catch (_) {
      if (_disposed || id != _requestId) return;
      _loadError = 'Gagal memuat profil toko. Periksa koneksimu.';
    } finally {
      if (!_disposed && id == _requestId) { _loading = false; _notify(); }
    }
  }

  Future<String?> pickPhoto() async {
    if (_disposed || _saving) return null;
    final res = await _pickPhoto();
    if (_disposed || _saving) return null;
    if (res.accepted.isNotEmpty) {
      _newPhoto = res.accepted.first;
      _removeOwn = false;
      _notify();
    }
    return res.summary;
  }

  String get photoStatus {
    if (_newPhoto != null) return 'Foto baru akan disimpan';
    if (_removeOwn) {
      return (accountAvatar != null && accountAvatar!.isNotEmpty)
          ? 'Foto toko akan dihapus. Toko memakai foto akunmu.'
          : 'Foto toko akan dihapus. Belum ada foto.';
    }
    if (_ownAvatarUrl == null && (_effectiveAvatarUrl ?? '').isNotEmpty) return 'Memakai foto akunmu';
    if (_ownAvatarUrl == null) return 'Belum ada foto';
    return 'Foto toko milikmu';
  }

  String get nameForInitials {
    final t = _name.trim();
    return t.isNotEmpty ? t : (_initialName.isNotEmpty ? _initialName : accountName);
  }


  Future<bool> save() async {
    if (_disposed || _saving || _loading || _loadError != null) return false;
    _actionError = null;
    final trimmed = _name.trim();
    if (trimmed.isNotEmpty && trimmed.length < 2) {
      _nameError = 'Nama brand minimal 2 karakter'; _notify(); return false;
    }
    if (trimmed.length > nameMax) {
      _nameError = 'Nama brand maksimal $nameMax karakter'; _notify(); return false;
    }
    final body = <String, dynamic>{};
    final effective = trimmed.isEmpty ? accountName : trimmed;
    if (effective != _initialName) body['brandName'] = trimmed;
    final bio = _bio.trim();
    if (bio != _initialBio.trim()) body['bio'] = bio;
    _saving = true;
    _nameError = null;
    _notify();
    String? uploadedUrl;
    try {
      if (_newPhoto != null) {
        uploadedUrl = await _upload.uploadOne(_newPhoto!);
        body['avatarUrl'] = uploadedUrl;
      } else if (_removeOwn) {
        body['avatarUrl'] = null;
      }
      if (body.isEmpty) return false;
      await _repository.updateMine(body);
      return true;
    } on ApiException catch (e) {
      if (uploadedUrl != null) await _upload.deleteUrls([uploadedUrl]);
      if (e.code == 'BRAND_NAME_TAKEN' || e.status == 409) {
        _nameError = 'Nama brand sudah dipakai kreator lain atau sedang diajukan. Gunakan nama lain.';
      } else if (e.code == 'BRAND_NAME_INVALID') {
        _nameError = 'Nama brand harus mengandung minimal 2 huruf atau angka';
      } else if (e.status == 403) {
        _actionError = 'Tokomu sedang dinonaktifkan, perubahan belum bisa disimpan.';
      } else {
        _actionError = e.message;
      }
      return false;
    } catch (_) {
      if (uploadedUrl != null) await _upload.deleteUrls([uploadedUrl]);
      _actionError = 'Gagal menyimpan. Periksa koneksimu lalu coba lagi.';
      return false;
    } finally {
      _saving = false;
      _notify();
    }
  }

  void _resetDraft() {
    _name = _initialName; _bio = _initialBio; _newPhoto = null;
    _removeOwn = false; _nameError = null; _actionError = null;
  }
  void reset() { if (_disposed || _saving) return; _resetDraft(); _notify(); }
  void _notify() { if (!_disposed) notifyListeners(); }
  @override
  void dispose() { _disposed = true; ++_requestId; super.dispose(); }
}
