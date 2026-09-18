import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/password_validator.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/auth/widgets/password_criteria_checklist.dart';
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
        OutlinedButton(
          onPressed: () async {
            await auth.logout();
            if (!context.mounted) return;
            context.go('/');
          },
          style: OutlinedButton.styleFrom(foregroundColor: AppColors.destructive),
          child: const Text('Keluar'),
        ),
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
      if (!mounted) return;
      setState(() => _avatarPath = xfile.path);
      context.read<AuthProvider>().updateProfile(avatarUrl: xfile.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
      GestureDetector(onTap: _pickImage, child: CircleAvatar(radius: 40, backgroundColor: AppColors.primary, backgroundImage: _avatarPath != null ? FileImage(File(_avatarPath!)) : null, child: _avatarPath == null ? const Icon(Icons.person, color: AppColors.onPrimary, size: 32) : null)),
      const SizedBox(height: 8),
      TextButton(onPressed: _pickImage, child: const Text('Ganti foto profil')),
      const SizedBox(height: 12),
      TextField(controller: _name, decoration: const InputDecoration(labelText: 'Nama')),
      const SizedBox(height: 12),
      ElevatedButton(onPressed: () { context.read<AuthProvider>().updateProfile(name: _name.text); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nama disimpan'))); }, child: const Text('Simpan Nama')),
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
  String _generatedOtp = '';
  bool _otpSent = false;

  @override
  void initState() { super.initState(); _email.text = context.read<AuthProvider>().user?.email ?? ''; }
  @override
  void dispose() { _email.dispose(); _otp.dispose(); super.dispose(); }

  void _sendOtp() {
    if (_email.text.trim().isEmpty) return;
    setState(() { _generatedOtp = (DateTime.now().millisecondsSinceEpoch % 900000 + 100000).toString(); _otpSent = true; });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('(Mode demo) Kode OTP: $_generatedOtp')));
  }

  void _verify() {
    if (_otp.text == _generatedOtp) {
      context.read<AuthProvider>().changeEmail(_email.text);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Email berhasil diganti')));
      setState(() => _otpSent = false);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kode OTP salah')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
      TextField(controller: _email, decoration: const InputDecoration(labelText: 'Email baru')),
      const SizedBox(height: 8),
      if (_otpSent) ...[
        TextField(controller: _otp, keyboardType: TextInputType.number, maxLength: 6, decoration: const InputDecoration(labelText: 'Kode OTP')),
        const SizedBox(height: 8),
        ElevatedButton(onPressed: _verify, child: const Text('Verifikasi')),
      ] else
        ElevatedButton(onPressed: _sendOtp, child: const Text('Kirim Kode')),
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

  @override
  void dispose() { _old.dispose(); _new.dispose(); _confirm.dispose(); super.dispose(); }

  void _save() {
    final v = validatePassword(_new.text);
    if (!v.isValid) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password belum memenuhi kriteria'))); return; }
    if (_new.text != _confirm.text) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password tidak sama'))); return; }
    context.read<AuthProvider>().changePassword(_new.text);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password berhasil diubah')));
    _old.clear(); _new.clear(); _confirm.clear(); setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
      TextField(controller: _old, obscureText: true, decoration: const InputDecoration(labelText: 'Password lama')),
      const SizedBox(height: 12),
      TextField(controller: _new, obscureText: true, onChanged: (_) => setState(() {}), decoration: const InputDecoration(labelText: 'Password baru')),
      const SizedBox(height: 8),
      PasswordCriteriaChecklist(password: _new.text),
      const SizedBox(height: 12),
      TextField(controller: _confirm, obscureText: true, decoration: const InputDecoration(labelText: 'Konfirmasi password')),
      const SizedBox(height: 12),
      ElevatedButton(onPressed: _save, child: const Text('Simpan Password Baru')),
    ])));
  }
}
