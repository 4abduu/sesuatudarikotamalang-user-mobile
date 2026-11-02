import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/upload_api.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/image_helper.dart';
import '../../../core/utils/photo_rules.dart';
import '../../../core/widgets/creator_avatar.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/secondary_button.dart';
import '../../../data/models/creator_model.dart';
import '../../../shared/app_scaffold.dart';
import '../../auth/providers/auth_provider.dart';
import '../../creators/providers/artisans_provider.dart';
import '../providers/creator_dashboard_provider.dart';

/// Profil Toko kreator: foto toko, nama brand, dan bio.
/// Rute: `/dashboard-kreator/profil-toko`. Satu panggilan `PUT /api/artisans/mine`
/// yang hanya berisi field yang berubah (API_CONTRACT v1.7, "Profil toko").
class EditStoreProfileScreen extends StatefulWidget {
  const EditStoreProfileScreen({super.key});

  @override
  State<EditStoreProfileScreen> createState() => _EditStoreProfileScreenState();
}

class _EditStoreProfileScreenState extends State<EditStoreProfileScreen> {
  static const int _bioMax = 2000;
  static const int _nameMax = 191;
  static const String _msgTaken = 'Nama brand sudah dipakai kreator lain atau sedang diajukan. Gunakan nama lain.';
  static const String _msgInvalid = 'Nama brand harus mengandung minimal 2 huruf atau angka';

  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _bioCtrl = TextEditingController();

  bool _loading = true;
  String? _loadError;
  bool _saving = false;

  String _initialName = '';
  String _initialBio = '';
  String? _effectiveAvatarUrl; // foto efektif (foto toko atau foto akun)
  String? _ownAvatarUrl; // foto toko milik sendiri, null bila memakai foto akun

  XFile? _newPhoto;
  bool _removeOwn = false;
  String? _nameError;
  bool _discarded = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl.addListener(_onTyping);
    _bioCtrl.addListener(_onTyping);
    _load();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  void _onTyping() {
    if (mounted && !_loading) setState(() {});
  }

  String get _accountName => (context.read<AuthProvider>().user?.name ?? '').trim();
  String? get _accountAvatar => context.read<AuthProvider>().user?.avatarUrl;

  bool get _dirty {
    if (_loading || _loadError != null) return false;
    final trimmed = _nameCtrl.text.trim();
    final effective = trimmed.isEmpty ? _accountName : trimmed;
    return effective != _initialName ||
        _bioCtrl.text.trim() != _initialBio.trim() ||
        _newPhoto != null ||
        _removeOwn;
  }

  // ---- muat ----------------------------------------------------------------

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final res = await ApiClient.get('/artisans/mine');
      final a = res is Map<String, dynamic> ? res['artisan'] : null;
      if (a is! Map<String, dynamic>) {
        throw ApiException(404, 'Profil toko tidak ditemukan');
      }
      _initialName = (a['brandName'] ?? '').toString();
      _initialBio = (a['bio'] ?? '').toString();
      _effectiveAvatarUrl = a['avatarUrl'] as String?;
      _ownAvatarUrl = a['ownAvatarUrl'] as String?;
      _nameCtrl.text = _initialName;
      _bioCtrl.text = _initialBio;
      _newPhoto = null;
      _removeOwn = false;
      _nameError = null;
    } on ApiException catch (e) {
      _loadError = e.message;
    } catch (_) {
      _loadError = 'Gagal memuat profil toko. Periksa koneksimu.';
    }
    if (mounted) setState(() => _loading = false);
  }

  // ---- foto ----------------------------------------------------------------

  Future<void> _pickPhoto() async {
    final res = await PhotoRules.pickOne();
    if (!mounted) return;
    if (res.accepted.isNotEmpty) {
      setState(() {
        _newPhoto = res.accepted.first;
        _removeOwn = false;
      });
    }
    final msg = res.summary;
    if (msg != null) _snack(msg);
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  String get _photoStatus {
    if (_newPhoto != null) return 'Foto baru akan disimpan';
    if (_removeOwn) {
      return (_accountAvatar != null && _accountAvatar!.isNotEmpty)
          ? 'Foto toko akan dihapus. Toko memakai foto akunmu.'
          : 'Foto toko akan dihapus. Belum ada foto.';
    }
    if (_ownAvatarUrl == null && (_effectiveAvatarUrl ?? '').isNotEmpty) return 'Memakai foto akunmu';
    if (_ownAvatarUrl == null) return 'Belum ada foto';
    return 'Foto toko milikmu';
  }

  String get _nameForInitials {
    final t = _nameCtrl.text.trim();
    return t.isNotEmpty ? t : (_initialName.isNotEmpty ? _initialName : _accountName);
  }

  Widget _avatarPreview() {
    const double size = 96;
    if (_newPhoto != null) {
      final provider = safeImageProvider(_newPhoto!.path);
      if (provider != null) {
        return ClipOval(child: Image(image: provider, width: size, height: size, fit: BoxFit.cover));
      }
    }
    final shown = _removeOwn ? _accountAvatar : _effectiveAvatarUrl;
    return CreatorAvatar(avatarUrl: shown, name: _nameForInitials, size: size);
  }

  // ---- simpan --------------------------------------------------------------

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    final trimmed = _nameCtrl.text.trim();
    if (trimmed.isNotEmpty && trimmed.length < 2) {
      setState(() => _nameError = 'Nama brand minimal 2 karakter');
      return;
    }
    if (trimmed.length > _nameMax) {
      setState(() => _nameError = 'Nama brand maksimal $_nameMax karakter');
      return;
    }

    final body = <String, dynamic>{};
    final effective = trimmed.isEmpty ? _accountName : trimmed;
    if (effective != _initialName) body['brandName'] = trimmed; // "" = kembali ke nama akun
    final bio = _bioCtrl.text.trim();
    if (bio != _initialBio.trim()) body['bio'] = bio; // "" = hapus bio

    final dashboard = context.read<CreatorDashboardProvider>();
    final artisans = context.read<ArtisansProvider>();
    final messenger = ScaffoldMessenger.of(context);

    setState(() {
      _saving = true;
      _nameError = null;
    });

    String? uploadedUrl;
    try {
      if (_newPhoto != null) {
        uploadedUrl = await UploadApi.uploadOne(_newPhoto!);
        body['avatarUrl'] = uploadedUrl;
      } else if (_removeOwn) {
        body['avatarUrl'] = null; // hapus foto toko milik sendiri
      }
      if (body.isEmpty) {
        if (mounted) setState(() => _saving = false);
        return;
      }
      await ApiClient.put('/artisans/mine', body: body);
    } on ApiException catch (e) {
      if (uploadedUrl != null) await UploadApi.deleteUrls([uploadedUrl]);
      _handleError(e);
      return;
    } catch (_) {
      if (uploadedUrl != null) await UploadApi.deleteUrls([uploadedUrl]);
      if (mounted) {
        setState(() => _saving = false);
        _snack('Gagal menyimpan. Periksa koneksimu lalu coba lagi.');
      }
      return;
    }

    // Berhasil: muat ulang data yang menampilkan profil toko.
    await dashboard.fetchDashboardData();
    await artisans.fetchArtisans();
    if (!mounted) return;
    messenger.showSnackBar(const SnackBar(content: Text('Profil toko disimpan')));
    setState(() {
      _saving = false;
      _discarded = true;
    });
    context.pop();
  }

  void _handleError(ApiException e) {
    if (!mounted) return;
    setState(() => _saving = false);
    if (e.code == 'BRAND_NAME_TAKEN' || e.status == 409) {
      setState(() => _nameError = _msgTaken);
    } else if (e.code == 'BRAND_NAME_INVALID') {
      setState(() => _nameError = _msgInvalid);
    } else if (e.status == 403) {
      _snack('Tokomu sedang dinonaktifkan, perubahan belum bisa disimpan.');
    } else {
      _snack(e.message);
    }
  }

  // ---- batal / keluar ------------------------------------------------------

  void _reset() {
    setState(() {
      _nameCtrl.text = _initialName;
      _bioCtrl.text = _initialBio;
      _newPhoto = null;
      _removeOwn = false;
      _nameError = null;
    });
  }

  Future<void> _handleBack() async {
    if (!_dirty || _discarded) {
      if (mounted) context.pop();
      return;
    }
    final discard = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Buang perubahan?'),
        content: const Text('Perubahan profil tokomu belum disimpan.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Tetap di sini')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Buang', style: TextStyle(color: AppColors.destructive)),
          ),
        ],
      ),
    );
    if (discard == true && mounted) {
      setState(() => _discarded = true);
      context.pop();
    }
  }

  // ---- tampilan ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_dirty || _discarded,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _handleBack();
      },
      child: AppScaffold(
        title: 'Profil Toko',
        showBottomNav: false,
        showSearchAction: false,
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: _handleBack),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 40, color: AppColors.muted),
              const SizedBox(height: 12),
              Text(_loadError!, style: AppTextStyles.bodyMuted, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              SecondaryButton(label: 'Coba lagi', fullWidth: false, compact: true, onPressed: _load),
            ],
          ),
        ),
      );
    }

    final accountName = _accountName;
    final trimmed = _nameCtrl.text.trim();
    final shownName = trimmed.isNotEmpty ? trimmed : accountName;
    final handle = CreatorModel.fromJson({'brandName': shownName.isEmpty ? 'kreator' : shownName}).handle;
    final canRemove = _ownAvatarUrl != null && !_removeOwn && _newPhoto == null;

    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: _avatarPreview()),
          const SizedBox(height: 8),
          Center(child: Text(_photoStatus, style: AppTextStyles.caption, textAlign: TextAlign.center)),
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SecondaryButton(
                label: 'Ganti foto',
                fullWidth: false,
                compact: true,
                icon: const Icon(Icons.photo_camera_outlined, size: 16),
                onPressed: _saving ? null : _pickPhoto,
              ),
              if (_newPhoto != null)
                TextButton(
                  onPressed: _saving ? null : () => setState(() => _newPhoto = null),
                  child: const Text('Batal pilih foto'),
                ),
              if (canRemove)
                TextButton(
                  onPressed: _saving ? null : () => setState(() => _removeOwn = true),
                  child: const Text('Hapus foto toko', style: TextStyle(color: AppColors.destructive)),
                ),
              if (_removeOwn)
                TextButton(
                  onPressed: _saving ? null : () => setState(() => _removeOwn = false),
                  child: const Text('Batal hapus'),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Text('Nama brand', style: AppTextStyles.label),
          const SizedBox(height: 6),
          TextField(
            controller: _nameCtrl,
            enabled: !_saving,
            maxLength: _nameMax,
            textCapitalization: TextCapitalization.words,
            onChanged: (_) {
              if (_nameError != null) setState(() => _nameError = null);
            },
            decoration: InputDecoration(
              hintText: accountName,
              helperText: 'Kosongkan untuk memakai nama akunmu ($accountName)',
              helperMaxLines: 2,
              errorText: _nameError,
              errorMaxLines: 3,
              counterText: '',
            ),
          ),
          const SizedBox(height: 6),
          Text('Tampil sebagai @$handle', style: AppTextStyles.caption),
          const SizedBox(height: 20),
          Text('Bio', style: AppTextStyles.label),
          const SizedBox(height: 6),
          TextField(
            controller: _bioCtrl,
            enabled: !_saving,
            minLines: 4,
            maxLines: 6,
            maxLength: _bioMax,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText: 'Ceritakan tokomu singkat saja',
              helperText: 'Tampil di halaman profil tokomu. Kosongkan untuk menghapus bio.',
              helperMaxLines: 2,
            ),
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            label: 'Simpan',
            loading: _saving,
            onPressed: _dirty ? _save : null,
          ),
          if (_dirty)
            Center(
              child: TextButton(
                onPressed: _saving ? null : _reset,
                child: const Text('Batalkan perubahan'),
              ),
            ),
        ],
      ),
    );
  }
}
