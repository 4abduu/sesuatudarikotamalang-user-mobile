import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../shared/app_scaffold.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_field.dart';
import '../widgets/google_sign_in_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _pw = TextEditingController();
  bool _showPw = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _email.dispose();
    _pw.dispose();
    super.dispose();
  }

  void _showGoogleShortcutDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Akun Terhubung ke Google'),
        content: const Text(
          'Akun ini terdaftar menggunakan Google. Silakan masuk menggunakan tombol "Masuk dengan Google".',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Tutup'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _loginWithGoogle();
            },
            child: const Text('Gunakan Google'),
          ),
        ],
      ),
    );
  }

  Future<void> _login() async {
    final email = _email.text.trim();
    final password = _pw.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Isi email dan password dulu ya')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final auth = context.read<AuthProvider>();
      await auth.loginWithApi(email: email, password: password);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Berhasil masuk! Selamat datang kembali.'),
          backgroundColor: AppColors.moss,
        ),
      );
      final next = GoRouterState.of(context).uri.queryParameters['next'];
      context.go(next ?? '/');
    } catch (e) {
      if (!mounted) return;
      if (e is ApiException) {
        if (e.code == 'GOOGLE_ACCOUNT') {
          _showGoogleShortcutDialog();
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal masuk: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loginWithGoogle() async {
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
      final next = GoRouterState.of(context).uri.queryParameters['next'];
      context.go(next ?? '/');
    } catch (e) {
      if (!mounted) return;
      final msg = e is ApiException ? e.message : 'Login Google gagal: $e';
      // Hanya tampilkan error jika bukan "dibatalkan user"
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
      body: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 48, 24, 32),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 80),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: AppShadows.sticker,
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/logos/logo_sesuatu.jpg',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Masuk ke akunmu', style: AppTextStyles.h1),
                const SizedBox(height: 4),
                Text('Senang melihatmu lagi di Kayutangan.',
                    style: AppTextStyles.bodyMuted),
                const SizedBox(height: 24),
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
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => context.push('/lupa-password'),
                    child: Text('Lupa password?',
                        style: AppTextStyles.caption.copyWith(
                            fontWeight: FontWeight.w500,
                            color: AppColors.foreground)),
                  ),
                ),
                const SizedBox(height: 8),
                PrimaryButton(
                  label: 'Masuk',
                  loading: _isLoading,
                  onPressed: _login,
                ),
                const SizedBox(height: 16),
                // ===== Masuk dengan Google =====
                GoogleSignInButton(
                  onTap: _isLoading ? null : _loginWithGoogle,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Belum punya akun? ', style: AppTextStyles.bodyMuted),
                    GestureDetector(
                      onTap: () => context.push('/register'),
                      child: const Text(
                        'Daftar di sini',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => context.go('/'),
                  child: const Text(
                    'Lanjut sebagai tamu',
                    style: TextStyle(fontSize: 12, color: AppColors.muted),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
