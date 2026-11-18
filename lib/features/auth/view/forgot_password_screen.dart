import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/password_validator.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../shared/app_scaffold.dart';
import 'widgets/auth_field.dart';
import 'widgets/password_criteria_checklist.dart';
import '../viewmodel/forgot_password_view_model.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  int _step = 1;
  final _email = TextEditingController();
  final _otp = TextEditingController();
  final _pw = TextEditingController();
  final _confirm = TextEditingController();
  bool _showPw = false;
  bool _busy = false;
  int _cooldown = 0;

  @override
  void dispose() {
    _email.dispose();
    _otp.dispose();
    _pw.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (_busy || _cooldown > 0) return;
    if (_email.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Isi email dulu')));
      return;
    }
    setState(() => _busy = true);
    try {
      final vm = context.read<ForgotPasswordViewModel>();
      final success = await vm.requestCode(_email.text.trim());
      if (!mounted) return;
      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  vm.errorMessage ?? 'Gagal meminta kode OTP. Coba lagi.')),
        );
        return;
      }
      setState(() {
        _step = 2;
        _cooldown = 30;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Kode OTP telah diminta. Periksa email kamu.')));
      _tick();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _tick() async {
    while (_cooldown > 0 && mounted) {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      setState(() => _cooldown--);
    }
  }

  void _verify() {
    if (RegExp(r'^\d{6}$').hasMatch(_otp.text.trim())) {
      setState(() => _step = 3);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Masukkan kode OTP 6 digit')));
    }
  }

  Future<void> _savePw() async {
    if (_busy) return;
    final v = validatePassword(_pw.text);
    if (!v.isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password belum memenuhi kriteria')));
      return;
    }
    if (_pw.text != _confirm.text) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Password tidak sama')));
      return;
    }
    setState(() => _busy = true);
    try {
      final vm = context.read<ForgotPasswordViewModel>();
      final success = await vm.reset(
          email: _email.text.trim(),
          code: _otp.text.trim(),
          newPassword: _pw.text);
      if (!mounted) return;
      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  vm.errorMessage ?? 'Gagal mengubah password. Coba lagi.')),
        );
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Password berhasil diubah. Silakan masuk.')));
      context.go('/login');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      showBottomNav: false,
      showSearchAction: false,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                for (final step in [1, 2, 3]) ...[
                  if (step > 1) const SizedBox(width: 4),
                  Expanded(
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: step <= _step
                            ? AppColors.primary
                            : AppColors.border,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 24),
            Center(
              child: Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x33000000),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/logos/logo_sesuatu.jpg',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (_step == 1)
              ..._step1()
            else if (_step == 2)
              ..._step2()
            else
              ..._step3(),
          ],
        ),
      ),
    );
  }

  List<Widget> _step1() {
    return [
      Text('Lupa Password', style: AppTextStyles.h1),
      const SizedBox(height: 4),
      Text('Masukkan email kamu, kami kirim kode OTP.',
          style: AppTextStyles.bodyMuted),
      const SizedBox(height: 24),
      AuthField(
          label: 'Email',
          controller: _email,
          icon: Icons.mail_outline,
          keyboardType: TextInputType.emailAddress),
      const SizedBox(height: 24),
      PrimaryButton(
          label: _busy ? 'Mengirim...' : 'Kirim Kode OTP',
          onPressed: _busy ? null : _sendOtp)
    ];
  }

  List<Widget> _step2() {
    return [
      Text('Verifikasi OTP', style: AppTextStyles.h1),
      const SizedBox(height: 4),
      Text(
          'Masukkan kode yang dikirim ke email. Kode diperiksa saat password baru disimpan.',
          style: AppTextStyles.bodyMuted),
      const SizedBox(height: 24),
      AuthField(
          label: 'Kode OTP (6 digit)',
          controller: _otp,
          icon: Icons.lock_outline,
          keyboardType: TextInputType.number,
          maxLength: 6),
      const SizedBox(height: 12),
      if (_cooldown > 0)
        Text('Kirim ulang dalam ${_cooldown}s',
            style: const TextStyle(fontSize: 12, color: AppColors.muted))
      else
        GestureDetector(
            onTap: _sendOtp,
            child: const Text('Kirim ulang kode',
                style: TextStyle(
                    fontSize: 12,
                    color: AppColors.primary,
                    decoration: TextDecoration.underline))),
      const SizedBox(height: 24),
      PrimaryButton(label: 'Verifikasi', onPressed: _verify)
    ];
  }

  List<Widget> _step3() {
    return [
      Text('Password Baru', style: AppTextStyles.h1),
      const SizedBox(height: 4),
      Text('Buat password baru yang aman.', style: AppTextStyles.bodyMuted),
      const SizedBox(height: 24),
      AuthField(
          label: 'Password baru',
          controller: _pw,
          icon: Icons.lock_outline,
          obscureText: !_showPw,
          onChanged: (_) => setState(() {}),
          suffix: AuthEyeToggle(
              visible: _showPw,
              onTap: () => setState(() => _showPw = !_showPw))),
      const SizedBox(height: 12),
      PasswordCriteriaChecklist(password: _pw.text, boxed: true),
      const SizedBox(height: 12),
      AuthField(
          label: 'Konfirmasi password',
          controller: _confirm,
          icon: Icons.lock_outline,
          obscureText: !_showPw,
          suffix: AuthEyeToggle(
              visible: _showPw,
              onTap: () => setState(() => _showPw = !_showPw))),
      const SizedBox(height: 24),
      PrimaryButton(
          label: _busy ? 'Menyimpan...' : 'Simpan Password Baru',
          onPressed: _busy ? null : _savePw),
      TextButton(
          onPressed: _busy ? null : () => setState(() => _step = 2),
          child: const Text('Ubah kode OTP'))
    ];
  }
}
