import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/network/api_exception.dart';
import '../../../data/services/photo_picker_service.dart';
import '../../../data/services/upload_service.dart';
import '../../auth/viewmodel/auth_view_model.dart';

class ProfileSettingsViewModel extends ChangeNotifier {
  ProfileSettingsViewModel(this._auth, this._upload, this._picker)
      : _userId = _auth.user?.id, _name = _auth.user?.name ?? '';
  final AuthViewModel _auth;
  final UploadService _upload;
  final PhotoPickerService _picker;
  final String? _userId;
  String _name;
  bool _isUploadingAvatar = false;
  bool _isSavingName = false;
  bool _isPicking = false;
  bool _disposed = false;
  String? _actionError;
  String? _pickerMessage;
  String get name => _name;
  String? get avatarUrl => _auth.user?.avatarUrl;
  bool get isUploadingAvatar => _isUploadingAvatar;
  bool get isSavingName => _isSavingName;
  String? get actionError => _actionError;
  String? get pickerMessage => _pickerMessage;
  bool get _active => !_disposed && _userId != null && _auth.user?.id == _userId;

  Future<XFile?> pickPhoto() async {
    if (!_active || _isPicking || _isUploadingAvatar) return null;
    _isPicking = true;
    _pickerMessage = null;
    try {
      final result = await _picker.pickOne();
      if (!_active) return null;
      _pickerMessage = result.summary;
      return result.accepted.isEmpty ? null : result.accepted.first;
    } catch (_) {
      if (_active) _pickerMessage = 'Foto tidak dapat dibaca.';
      return null;
    } finally { _isPicking = false; _notify(); }
  }

  Future<bool> saveAvatar(XFile photo) async {
    if (!_active || _isUploadingAvatar || _isSavingName) return false;
    _isUploadingAvatar = true;
    _actionError = null;
    _notify();
    String? uploaded;
    bool saved = false;
    try {
      uploaded = await _upload.uploadOne(photo);
      if (!_active) return false;
      await _auth.updateProfile(avatarUrl: uploaded);
      saved = true;
      return _active;
    } on ApiException catch (e) {
      if (_active) _actionError = e.message;
      return false;
    } catch (_) {
      if (_active) _actionError = 'Tidak bisa terhubung ke server. Periksa koneksi lalu coba lagi.';
      return false;
    } finally {
      // Hanya URL baru yang belum berhasil dipasang boleh dihapus.
      if (!saved && uploaded != null) await _upload.deleteUrls([uploaded]);
      _isUploadingAvatar = false;
      _notify();
    }
  }

  Future<bool> removeAvatar() async {
    if (!_active || _isUploadingAvatar || _isSavingName) return false;
    _isUploadingAvatar = true;
    _actionError = null;
    _notify();
    try {
      await _auth.updateProfile(removeAvatar: true);
      return _active;
    } on ApiException catch (e) {
      if (_active) _actionError = e.message;
      return false;
    } catch (_) {
      if (_active) _actionError = 'Gagal menghapus foto profil. Periksa koneksi Anda.';
      return false;
    } finally { _isUploadingAvatar = false; _notify(); }
  }

  Future<bool> saveName(String value) async {
    if (!_active || _isSavingName || _isUploadingAvatar) return false;
    _isSavingName = true;
    _actionError = null;
    _notify();
    try {
      await _auth.updateProfile(name: value);
      if (!_active) return false;
      _name = value;
      return true;
    } catch (e) {
      if (_active) _actionError = e is ApiException ? e.message : e.toString();
      return false;
    } finally { _isSavingName = false; _notify(); }
  }

  void _notify() { if (!_disposed) notifyListeners(); }
  @override
  void dispose() { _disposed = true; super.dispose(); }
}
