import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/auth_provider.dart';

class DemoLoginButtons extends StatelessWidget {
  final VoidCallback? onSuccess;
  const DemoLoginButtons({super.key, this.onSuccess});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    return Column(children: [
      const Row(children: [
        Expanded(child: Divider()),
        Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('atau coba demo', style: TextStyle(fontSize: 11, color: AppColors.muted, fontWeight: FontWeight.w600))),
        Expanded(child: Divider()),
      ]),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: _DemoBtn(label: 'Pembeli', desc: 'Beli & beri ulasan', color: AppColors.surface, fg: AppColors.foreground, onTap: () { auth.login(auth.demoUsers[0]); onSuccess?.call(); })),
        const SizedBox(width: 8),
        Expanded(child: _DemoBtn(label: 'Kreator', desc: '+ dashboard kreator', color: const Color(0x156B7A3D), fg: AppColors.moss, onTap: () { auth.login(auth.demoUsers[1]); onSuccess?.call(); })),
      ]),
    ]);
  }
}

class _DemoBtn extends StatelessWidget {
  final String label, desc;
  final Color color, fg;
  final VoidCallback onTap;
  const _DemoBtn({required this.label, required this.desc, required this.color, required this.fg, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: fg)), Text(desc, style: const TextStyle(fontSize: 11, color: AppColors.muted))]),
      ),
    );
  }
}
