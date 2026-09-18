import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/password_validator.dart';
import '../widgets/password_criteria_checklist.dart';

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
  String _generatedOtp = '';
  bool _showPw = false;
  int _cooldown = 0;

  @override
  void dispose() { _email.dispose(); _otp.dispose(); _pw.dispose(); _confirm.dispose(); super.dispose(); }

  void _sendOtp() {
    if (_email.text.trim().isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Isi email dulu'))); return; }
    setState(() { _step = 2; _generatedOtp = (Random().nextInt(900000) + 100000).toString(); _cooldown = 30; });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('(Mode demo) Kode OTP kamu: $_generatedOtp'), duration: const Duration(seconds: 5)));
    _tick();
  }

  void _tick() async {
    while (_cooldown > 0 && mounted) {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      setState(() => _cooldown--);
    }
  }

  void _verify() {
    if (_otp.text == _generatedOtp) {
      setState(() => _step = 3);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kode OTP salah')));
    }
  }

  void _savePw() {
    final v = validatePassword(_pw.text);
    if (!v.isValid) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password belum memenuhi kriteria'))); return; }
    if (_pw.text != _confirm.text) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password tidak sama'))); return; }
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password berhasil diubah. Silakan masuk.')));
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [1, 2, 3]
                    .map(
                      (step) => Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          height: 4,
                          decoration: BoxDecoration(
                            color: step <= _step ? AppColors.primary : AppColors.border,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 24),
              if (_step == 1) ..._step1() else if (_step == 2) ..._step2() else ..._step3(),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _step1() {
    return [Text('Lupa Password', style: AppTextStyles.h1), const SizedBox(height: 4), Text('Masukkan email kamu, kami kirim kode OTP.', style: AppTextStyles.bodyMuted), const SizedBox(height: 24),
      TextField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined))),
      const SizedBox(height: 24), SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _sendOtp, child: const Text('Kirim Kode OTP')))];
  }

  List<Widget> _step2() {
    return [Text('Verifikasi OTP', style: AppTextStyles.h1), const SizedBox(height: 4), Text('(Mode demo) Kode OTP: $_generatedOtp', style: const TextStyle(fontSize: 12, color: AppColors.mustard, fontWeight: FontWeight.w600)), const SizedBox(height: 24),
      TextField(controller: _otp, keyboardType: TextInputType.number, maxLength: 6, decoration: const InputDecoration(labelText: 'Kode OTP (6 digit)', prefixIcon: Icon(Icons.password))),
      const SizedBox(height: 8),
      if (_cooldown > 0) Text('Kirim ulang dalam ${_cooldown}s', style: const TextStyle(fontSize: 12, color: AppColors.muted))
      else GestureDetector(onTap: _sendOtp, child: const Text('Kirim ulang kode', style: TextStyle(fontSize: 12, color: AppColors.primary, decoration: TextDecoration.underline))),
      const SizedBox(height: 24), SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _verify, child: const Text('Verifikasi')))];
  }

  List<Widget> _step3() {
    return [Text('Password Baru', style: AppTextStyles.h1), const SizedBox(height: 4), Text('Buat password baru yang aman.', style: AppTextStyles.bodyMuted), const SizedBox(height: 24),
      TextField(controller: _pw, obscureText: !_showPw, onChanged: (_) => setState(() {}), decoration: InputDecoration(labelText: 'Password baru', prefixIcon: const Icon(Icons.lock_outline), suffixIcon: IconButton(icon: Icon(_showPw ? Icons.visibility_off : Icons.visibility), onPressed: () => setState(() => _showPw = !_showPw)))),
      const SizedBox(height: 8), PasswordCriteriaChecklist(password: _pw.text),
      const SizedBox(height: 12), TextField(controller: _confirm, obscureText: !_showPw, decoration: const InputDecoration(labelText: 'Konfirmasi password', prefixIcon: Icon(Icons.lock_outline))),
      const SizedBox(height: 24), SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _savePw, child: const Text('Simpan Password Baru')))];
  }
}
