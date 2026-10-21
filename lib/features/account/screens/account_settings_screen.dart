import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/password_validator.dart';
import '../../../core/network/api_client.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/widgets/password_criteria_checklist.dart';
import '../../../shared/app_scaffold.dart';

class AccountSettingsScreen extends StatelessWidget {
  const AccountSettingsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return AppScaffold(
      title: 'Pengaturan',
      body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Profil', style: AppTextStyles.h3),
        const SizedBox(height: 12),
        _ProfileSection(),
        const SizedBox(height: 24),
        Text('Ganti Email (OTP)', style: AppTextStyles.h3),
        const SizedBox(height: 12),
        _ChangeEmailOtpSection(),
        const SizedBox(height: 24),
        Text('Ganti Password', style: AppTextStyles.h3),
        const SizedBox(height: 12),
        _ChangePasswordSection(),
        const SizedBox(height: 24),
        OutlinedButton(onPressed: () async { await auth.logout(); if (context.mounted) context.go('/'); }, style: OutlinedButton.styleFrom(foregroundColor: AppColors.destructive), child: const Text('Keluar')),
      ])),
    );
  }
}

class _ProfileSection extends StatefulWidget {
  @override
  State<_ProfileSection> createState() => _ProfileSectionState();
}

class _ProfileSectionState extends State<_ProfileSection> {
  late final TextEditingController _name;
  String? _avatarPath;

  bool _isUploadingAvatar = false;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    _name = TextEditingController(text: auth.user?.name ?? '');
    _avatarPath = auth.user?.avatarUrl;
  }

  @override
  void dispose() { _name.dispose(); super.dispose(); }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final xfile = await picker.pickImage(source: ImageSource.gallery);
    if (xfile != null) {
      setState(() => _isUploadingAvatar = true);
      try {
        final res = await ApiClient.uploadMultipart(
          path: '/upload/single',
          fileField: 'image',
          filePath: xfile.path,
        );
        final url = res['url'] as String?;
        if (url != null && url.isNotEmpty) {
          if (mounted) {
            setState(() => _avatarPath = url);
            await context.read<AuthProvider>().updateProfile(avatarUrl: url);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Foto profil berhasil diperbarui!')),
              );
            }
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal mengunggah foto profil: $e')),
          );
        }
      } finally {
        if (mounted) setState(() => _isUploadingAvatar = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ImageProvider? imageProvider;
    if (_avatarPath != null && _avatarPath!.isNotEmpty) {
      if (_avatarPath!.startsWith('http')) {
        imageProvider = NetworkImage(_avatarPath!);
      } else {
        imageProvider = FileImage(File(_avatarPath!));
      }
    }

    return Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
      GestureDetector(
        onTap: _isUploadingAvatar ? null : _pickImage,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: AppColors.primary,
              backgroundImage: imageProvider,
              child: imageProvider == null
                  ? const Icon(Icons.person, color: AppColors.onPrimary, size: 32)
                  : null,
            ),
            if (_isUploadingAvatar)
              const CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
      const SizedBox(height: 8),
      TextButton(
        onPressed: _isUploadingAvatar ? null : _pickImage,
        child: const Text('Ganti foto profil'),
      ),
      const SizedBox(height: 12),
      TextField(controller: _name, decoration: const InputDecoration(labelText: 'Nama')),
      const SizedBox(height: 12),
      ElevatedButton(
        onPressed: () {
          context.read<AuthProvider>().updateProfile(name: _name.text);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nama disimpan')));
        },
        child: const Text('Simpan Nama'),
      ),
    ])));
  }
}

class _ChangeEmailOtpSection extends StatefulWidget {
  @override
  State<_ChangeEmailOtpSection> createState() => _ChangeEmailOtpSectionState();
}

class _ChangeEmailOtpSectionState extends State<_ChangeEmailOtpSection> {
  final _email = TextEditingController();
  final _otp = TextEditingController();
  bool _otpSent = false;
  bool _isLoading = false;
  late String _oldEmail;

  @override
  void initState() {
    super.initState();
    _oldEmail = context.read<AuthProvider>().user?.email ?? '';
    _email.text = '';
  }

  @override
  void dispose() { _email.dispose(); _otp.dispose(); super.dispose(); }

  Future<void> _sendOtp() async {
    final newEmail = _email.text.trim();
    if (newEmail.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Isi email baru terlebih dahulu')));
      return;
    }
    if (newEmail.toLowerCase() == _oldEmail.toLowerCase()) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Email baru harus berbeda dari email saat ini')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      await context.read<AuthProvider>().requestChangeEmail(newEmail);
      if (mounted) {
        setState(() => _otpSent = true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kode verifikasi telah dikirim ke $_oldEmail')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _verify() async {
    final code = _otp.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Masukkan kode OTP')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      await context.read<AuthProvider>().verifyChangeEmail(code);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Email berhasil diganti!')));
        setState(() {
          _otpSent = false;
          _email.clear();
          _otp.clear();
          _oldEmail = context.read<AuthProvider>().user?.email ?? '';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: AppColors.moss.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
        child: Row(children: [
          const Icon(Icons.info_outline, size: 16, color: AppColors.moss),
          const SizedBox(width: 8),
          Expanded(child: Text('Email saat ini: $_oldEmail', style: AppTextStyles.caption.copyWith(color: AppColors.moss))),
        ]),
      ),
      const SizedBox(height: 12),
      TextField(controller: _email, enabled: !_otpSent && !_isLoading, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email baru', hintText: 'nama@domain.com')),
      if (_otpSent) ...[
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: AppColors.mustard.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Row(children: [
            const Icon(Icons.mark_email_read_outlined, size: 16, color: AppColors.mustard),
            const SizedBox(width: 8),
            Expanded(child: Text('Kode verifikasi telah dikirim ke email Anda saat ini: $_oldEmail', style: AppTextStyles.caption.copyWith(color: AppColors.mustard, fontWeight: FontWeight.w600))),
          ]),
        ),
        const SizedBox(height: 12),
        TextField(controller: _otp, enabled: !_isLoading, keyboardType: TextInputType.number, maxLength: 6, decoration: const InputDecoration(labelText: 'Kode OTP (6 digit)')),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: _isLoading ? null : _verify,
          child: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Verifikasi Email Baru'),
        ),
      ] else
        ElevatedButton(
          onPressed: _isLoading ? null : _sendOtp,
          child: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Kirim Kode Verifikasi'),
        ),
    ])));
  }
}

class _ChangePasswordSection extends StatefulWidget {
  @override
  State<_ChangePasswordSection> createState() => _ChangePasswordSectionState();
}

class _ChangePasswordSectionState extends State<_ChangePasswordSection> {
  final _old = TextEditingController();
  final _new = TextEditingController();
  final _confirm = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() { _old.dispose(); _new.dispose(); _confirm.dispose(); super.dispose(); }

  Future<void> _save() async {
    final v = validatePassword(_new.text);
    if (!v.isValid) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password belum memenuhi kriteria')));
      return;
    }
    if (_new.text != _confirm.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Konfirmasi password tidak sama')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      await context.read<AuthProvider>().changePasswordApi(
        oldPassword: _old.text,
        newPassword: _new.text,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password berhasil diubah')));
        _old.clear();
        _new.clear();
        _confirm.clear();
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
      TextField(controller: _old, obscureText: true, enabled: !_isLoading, decoration: const InputDecoration(labelText: 'Password lama')),
      const SizedBox(height: 12),
      TextField(controller: _new, obscureText: true, enabled: !_isLoading, onChanged: (_) => setState(() {}), decoration: const InputDecoration(labelText: 'Password baru')),
      const SizedBox(height: 8),
      PasswordCriteriaChecklist(password: _new.text),
      const SizedBox(height: 12),
      TextField(controller: _confirm, obscureText: true, enabled: !_isLoading, decoration: const InputDecoration(labelText: 'Konfirmasi password')),
      const SizedBox(height: 12),
      ElevatedButton(
        onPressed: _isLoading ? null : _save,
        child: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Simpan Password Baru'),
      ),
    ])));
  }
}
