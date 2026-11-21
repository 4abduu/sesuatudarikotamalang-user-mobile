import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../shared/app_scaffold.dart';
import '../viewmodel/register_view_model.dart';
import 'widgets/auth_field.dart';
import 'widgets/password_criteria_checklist.dart';
import 'widgets/google_sign_in_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nama = TextEditingController();
  final _email = TextEditingController();
  final _pw = TextEditingController();
  final _confirm = TextEditingController();
  bool _showPw = false;

  @override
  void dispose() {
    _nama.dispose();
    _email.dispose();
    _pw.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final vm = context.read<RegisterViewModel>();
    final success = await vm.register(
        name: _nama.text.trim(),
        email: _email.text.trim(),
        password: _pw.text.trim(),
        confirmation: _confirm.text,
      );
      if (!mounted) return;
      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(vm.errorMessage ?? 'Pendaftaran gagal.')),
        );
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pendaftaran berhasil! Silakan masuk ke akunmu.'),
          backgroundColor: AppColors.moss,
        ),
      );
    context.go('/login');
  }

  /// Google Sign-In — mengambil idToken dari Google lalu POST /api/auth/google
  Future<void> _googleSignUp() async {
    final vm = context.read<RegisterViewModel>();
    final success = await vm.registerWithGoogle();
      if (!mounted) return;
      final message = vm.errorMessage ?? 'Login Google gagal.';
      if (!success) {
        if (vm.errorStatus != 0 || !message.contains('dibatalkan')) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(message)));
        }
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Berhasil masuk dengan Google!'),
          backgroundColor: AppColors.moss,
        ),
      );
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<RegisterViewModel>();
    return AppScaffold(
      showBottomNav: false,
      showSearchAction: false,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            const SizedBox(height: 16),
            Text('Buat akun baru', style: AppTextStyles.h1),
            const SizedBox(height: 4),
            Text(
              'Jadilah bagian dari komunitas artisan Kayutangan.',
              style: AppTextStyles.bodyMuted,
            ),
            const SizedBox(height: 24),
            AuthField(
              label: 'Nama lengkap',
              controller: _nama,
              icon: Icons.person_outline,
            ),
            const SizedBox(height: 12),
            AuthField(
              label: 'Email',
              controller: _email,
              icon: Icons.mail_outline,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            AuthField(
              label: 'Password',
              controller: _pw,
              icon: Icons.lock_outline,
              obscureText: !_showPw,
              suffix: AuthEyeToggle(
                visible: _showPw,
                onTap: () => setState(() => _showPw = !_showPw),
              ),
            ),
            const SizedBox(height: 12),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _pw,
              builder: (_, value, __) =>
                  PasswordCriteriaChecklist(password: value.text, boxed: true),
            ),
            const SizedBox(height: 12),
            AuthField(
              label: 'Konfirmasi password',
              controller: _confirm,
              icon: Icons.lock_outline,
              obscureText: !_showPw,
              suffix: AuthEyeToggle(
                visible: _showPw,
                onTap: () => setState(() => _showPw = !_showPw),
              ),
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'Daftar',
              loading: vm.isSubmitting,
              onPressed: vm.isSubmitting ? null : _submit,
            ),
            const SizedBox(height: 16),
            GoogleSignInButton(
                label: 'Daftar dengan Google', onTap: vm.isSubmitting ? null : _googleSignUp),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Sudah punya akun? ', style: AppTextStyles.bodyMuted),
                GestureDetector(
                  onTap: () => context.push('/login'),
                  child: const Text(
                    'Masuk',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
