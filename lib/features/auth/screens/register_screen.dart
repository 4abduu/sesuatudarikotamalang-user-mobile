import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/password_validator.dart';
import '../../../data/models/user_model.dart';
import '../providers/auth_provider.dart';
import '../widgets/password_criteria_checklist.dart';

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
  void dispose() { _nama.dispose(); _email.dispose(); _pw.dispose(); _confirm.dispose(); super.dispose(); }

  void _submit() {
    final v = validatePassword(_pw.text);
    if (_nama.text.trim().isEmpty || _email.text.trim().isEmpty || !v.isValid || _pw.text != _confirm.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Periksa kembali isianmu ya')));
      return;
    }
    context.read<AuthProvider>().login(UserModel(id: 'u-${DateTime.now().millisecondsSinceEpoch}', name: _nama.text, email: _email.text, password: _pw.text, role: Role.buyer));
    context.go('/akun');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(),
      body: SafeArea(child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Buat akun baru', style: AppTextStyles.h1),
        const SizedBox(height: 4),
        Text('Jadilah bagian dari komunitas artisan Kayutangan.', style: AppTextStyles.bodyMuted),
        const SizedBox(height: 24),
        TextField(controller: _nama, decoration: const InputDecoration(labelText: 'Nama lengkap', prefixIcon: Icon(Icons.person_outline))),
        const SizedBox(height: 12),
        TextField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined))),
        const SizedBox(height: 12),
        TextField(controller: _pw, obscureText: !_showPw, onChanged: (_) => setState(() {}), decoration: InputDecoration(labelText: 'Password', prefixIcon: const Icon(Icons.lock_outline), suffixIcon: IconButton(icon: Icon(_showPw ? Icons.visibility_off : Icons.visibility), onPressed: () => setState(() => _showPw = !_showPw)))),
        const SizedBox(height: 8),
        PasswordCriteriaChecklist(password: _pw.text),
        const SizedBox(height: 12),
        TextField(controller: _confirm, obscureText: !_showPw, decoration: const InputDecoration(labelText: 'Konfirmasi password', prefixIcon: Icon(Icons.lock_outline))),
        const SizedBox(height: 24),
        SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _submit, child: const Text('Daftar'))),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('Sudah punya akun? ', style: AppTextStyles.bodyMuted),
          GestureDetector(onTap: () => context.push('/login'), child: const Text('Masuk', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primary))),
        ]),
      ]))),
    );
  }
}
