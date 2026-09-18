import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/user_model.dart';
import '../providers/auth_provider.dart';
import '../widgets/demo_login_buttons.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _pw = TextEditingController();
  bool _showPw = false;

  @override
  void dispose() { _email.dispose(); _pw.dispose(); super.dispose(); }

  void _login() {
    if (_email.text.trim().isEmpty || _pw.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Isi email dan password dulu ya')));
      return;
    }
    final auth = context.read<AuthProvider>();
    auth.login(UserModel(id: 'u-${DateTime.now().millisecondsSinceEpoch}', name: _email.text.split('@').first, email: _email.text, password: _pw.text, role: Role.buyer));
    final next = GoRouterState.of(context).uri.queryParameters['next'];
    context.go(next ?? '/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(width: 48, height: 48, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle), child: const Icon(Icons.eco, color: AppColors.onPrimary)),
        const SizedBox(height: 16),
        Text('Masuk ke akunmu', style: AppTextStyles.h1),
        const SizedBox(height: 4),
        Text('Senang melihatmu lagi di Kayutangan.', style: AppTextStyles.bodyMuted),
        const SizedBox(height: 24),
        TextField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined))),
        const SizedBox(height: 12),
        TextField(controller: _pw, obscureText: !_showPw, decoration: InputDecoration(labelText: 'Password', prefixIcon: const Icon(Icons.lock_outline), suffixIcon: IconButton(icon: Icon(_showPw ? Icons.visibility_off : Icons.visibility), onPressed: () => setState(() => _showPw = !_showPw)))),
        Align(alignment: Alignment.centerRight, child: TextButton(onPressed: () => context.push('/lupa-password'), child: const Text('Lupa password?', style: TextStyle(fontSize: 12)))),
        const SizedBox(height: 8),
        SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _login, child: const Text('Masuk'))),
        const SizedBox(height: 20),
        DemoLoginButtons(onSuccess: () {
          final next = GoRouterState.of(context).uri.queryParameters['next'];
          context.go(next ?? '/');
        }),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('Belum punya akun? ', style: AppTextStyles.bodyMuted),
          GestureDetector(onTap: () => context.push('/register'), child: const Text('Daftar di sini', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primary))),
        ]),
        const SizedBox(height: 8),
        GestureDetector(onTap: () => context.go('/'), child: const Text('Lanjut sebagai tamu', style: TextStyle(fontSize: 12, color: AppColors.muted))),
      ]))),
    );
  }
}
