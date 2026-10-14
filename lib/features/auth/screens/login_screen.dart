import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../providers/auth_provider.dart';
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
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  'assets/images/logos/logo_sesuatu.jpg',
                  width: 52,
                  height: 52,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.brush, color: AppColors.onPrimary, size: 26),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Masuk ke akunmu', style: AppTextStyles.h1),
              const SizedBox(height: 4),
              Text('Senang melihatmu lagi di Kayutangan.',
                  style: AppTextStyles.bodyMuted),
              const SizedBox(height: 24),
              TextField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _pw,
                obscureText: !_showPw,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon:
                        Icon(_showPw ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _showPw = !_showPw),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => context.push('/lupa-password'),
                  child: const Text('Lupa password?',
                      style: TextStyle(fontSize: 12)),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Masuk'),
                ),
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
    );
  }
}
