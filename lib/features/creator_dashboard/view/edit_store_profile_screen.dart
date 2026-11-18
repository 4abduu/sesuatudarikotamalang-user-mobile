import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/routing/back_navigation.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/image_helper.dart';
import '../../../core/widgets/creator_avatar.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/secondary_button.dart';
import '../../../data/models/creator_model.dart';
import '../../../shared/app_scaffold.dart';
import '../../auth/viewmodel/auth_view_model.dart';
import '../viewmodel/creator_dashboard_view_model.dart';
import '../viewmodel/edit_store_profile_view_model.dart';

/// Profil Toko kreator: foto toko, nama brand, dan bio.
/// Rute: `/dashboard-kreator/profil-toko`. Satu panggilan `PUT /api/artisans/mine`
/// yang hanya berisi field yang berubah (API_CONTRACT v1.7, "Profil toko").
class EditStoreProfileScreen extends StatefulWidget {
  const EditStoreProfileScreen({super.key});

  @override
  State<EditStoreProfileScreen> createState() => _EditStoreProfileScreenState();
}

class _EditStoreProfileScreenState extends State<EditStoreProfileScreen> {
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _bioCtrl = TextEditingController();
  bool _discarded = false;
  EditStoreProfileViewModel get _vm => context.read<EditStoreProfileViewModel>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final auth = context.read<AuthViewModel>();
      if (auth.isAuthenticated && auth.isCreator) _load();
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    await _vm.load();
    if (!mounted) return;
    _syncControllers();
  }

  void _syncControllers() {
    _nameCtrl.text = _vm.name;
    _bioCtrl.text = _vm.bio;
  }

  Future<void> _pickPhoto() async {
    final message = await _vm.pickPhoto();
    if (mounted && message != null) _snack(message);
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _avatarPreview() {
    const double size = 96;
    if (_vm.newPhoto != null) {
      final provider = safeImageProvider(_vm.newPhoto!.path);
      if (provider != null) {
        return ClipOval(child: Image(image: provider, width: size, height: size, fit: BoxFit.cover));
      }
    }
    final shown = _vm.shownAvatar;
    return CreatorAvatar(avatarUrl: shown, name: _vm.nameForInitials, size: size);
  }

  // ---- simpan --------------------------------------------------------------

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    final vm = _vm;
    final dashboard = context.read<CreatorDashboardViewModel>();
    final messenger = ScaffoldMessenger.of(context);
    if (!await vm.save()) {
      if (mounted && vm.actionError != null) _snack(vm.actionError!);
      return;
    }
    await dashboard.fetchDashboardData();
    if (!mounted) return;
    messenger.showSnackBar(const SnackBar(content: Text('Profil toko disimpan')));
    setState(() => _discarded = true);
      context.popOrParent(true);
  }

  void _reset() {
    _vm.reset();
    _syncControllers();
  }

  Future<void> _handleBack() async {
    if (!_vm.isDirty || _discarded) {
      if (mounted) context.popOrParent();
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
      context.popOrParent();
    }
  }

  // ---- tampilan ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    context.watch<EditStoreProfileViewModel>();
    return PopScope(
      canPop: !_vm.isDirty || _discarded,
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
    final auth = context.watch<AuthViewModel>();
    if (!auth.isAuthenticated || !auth.isCreator) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline, size: 48, color: AppColors.muted),
              const SizedBox(height: 12),
              Text('Akses khusus kreator', style: AppTextStyles.h2, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: () => context.go('/akun'), child: const Text('Kembali ke Akun')),
            ],
          ),
        ),
      );
    }
    if (_vm.isLoading) return const Center(child: CircularProgressIndicator());
    if (_vm.loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 40, color: AppColors.muted),
              const SizedBox(height: 12),
              Text(_vm.loadError!, style: AppTextStyles.bodyMuted, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              SecondaryButton(label: 'Coba lagi', fullWidth: false, compact: true, onPressed: _load),
            ],
          ),
        ),
      );
    }

    final accountName = _vm.accountName;
    final trimmed = _nameCtrl.text.trim();
    final shownName = trimmed.isNotEmpty ? trimmed : accountName;
    final handle = CreatorModel.fromJson({'brandName': shownName.isEmpty ? 'kreator' : shownName}).handle;
    final canRemove = _vm.canRemove;

    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: _avatarPreview()),
          const SizedBox(height: 8),
          Center(child: Text(_vm.photoStatus, style: AppTextStyles.caption, textAlign: TextAlign.center)),
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: _vm.isSaving ? null : _pickPhoto,
                icon: const Icon(Icons.photo_camera_outlined, size: 18),
                label: const Text('Ganti foto'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                  textStyle: GoogleFonts.baloo2(fontSize: 13, fontWeight: FontWeight.w700),
                ),
              ),
              if (_vm.newPhoto != null)
                TextButton(
                  onPressed: _vm.isSaving ? null : _vm.cancelPhoto,
                  child: const Text('Batal pilih foto'),
                ),
              if (canRemove)
                TextButton(
                  onPressed: _vm.isSaving ? null : () => _vm.setRemoveOwn(true),
                  child: const Text('Hapus foto toko', style: TextStyle(color: AppColors.destructive)),
                ),
              if (_vm.removeOwn)
                TextButton(
                  onPressed: _vm.isSaving ? null : () => _vm.setRemoveOwn(false),
                  child: const Text('Batal hapus'),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Text('Nama brand', style: AppTextStyles.label),
          const SizedBox(height: 6),
          TextField(
            controller: _nameCtrl,
            enabled: !_vm.isSaving,
            maxLength: EditStoreProfileViewModel.nameMax,
            textCapitalization: TextCapitalization.words,
            onChanged: _vm.setName,
            decoration: InputDecoration(
              hintText: accountName,
              helperText: 'Kosongkan untuk memakai nama akunmu ($accountName)',
              helperMaxLines: 2,
              errorText: _vm.nameError,
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
            onChanged: _vm.setBio,
            enabled: !_vm.isSaving,
            minLines: 4,
            maxLines: 6,
            maxLength: EditStoreProfileViewModel.bioMax,
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
            loading: _vm.isSaving,
            onPressed: _vm.isDirty ? _save : null,
          ),
          if (_vm.isDirty)
            Center(
              child: TextButton(
                onPressed: _vm.isSaving ? null : _reset,
                child: const Text('Batalkan perubahan'),
              ),
            ),
        ],
      ),
    );
  }
}
