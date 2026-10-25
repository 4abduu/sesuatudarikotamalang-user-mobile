import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/password_validator.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../shared/app_scaffold.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_field.dart';
import '../widgets/password_criteria_checklist.dart';
import '../widgets/google_sign_in_button.dart';

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
  bool _isLoading = false;

  @override
  void dispose() {
    _nama.dispose();
    _email.dispose();
    _pw.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final v = validatePassword(_pw.text);
    if (_nama.text.trim().isEmpty ||
        _email.text.trim().isEmpty ||
        !v.isValid ||
        _pw.text != _confirm.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Periksa kembali isianmu ya')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await context.read<AuthProvider>().register(
            name: _nama.text.trim(),
            email: _email.text.trim(),
            password: _pw.text.trim(),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pendaftaran berhasil! Silakan masuk ke akunmu.'),
          backgroundColor: AppColors.moss,
        ),
      );
      context.go('/login');
    } catch (e) {
      if (!mounted) return;
      if (e is ApiException) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Pendaftaran gagal: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Google Sign-In — mengambil idToken dari Google lalu POST /api/auth/google
  Future<void> _googleSignUp() async {
    setState(() => _isLoading = true);
    try {
      await context.read<AuthProvider>().loginWithGoogle();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Berhasil masuk dengan Google!'),
          backgroundColor: AppColors.moss,
        ),
      );
      context.go('/');
    } catch (e) {
      if (!mounted) return;
      final msg = e is ApiException ? e.message : 'Login Google gagal: $e';
      if (e is! ApiException || e.status != 0 || !msg.contains('dibatalkan')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
              onChanged: (_) => setState(() {}),
              suffix: AuthEyeToggle(
                visible: _showPw,
                onTap: () => setState(() => _showPw = !_showPw),
              ),
            ),
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
                onTap: () => setState(() => _showPw = !_showPw),
              ),
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'Daftar',
              loading: _isLoading,
              onPressed: _submit,
            ),
            const SizedBox(height: 16),
            GoogleSignInButton(
                label: 'Daftar dengan Google', onTap: _googleSignUp),
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
