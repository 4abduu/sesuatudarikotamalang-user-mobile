import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

void showAuthGateSheet(BuildContext context, {String? next, String? contextLabel}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => Padding(
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 20),
        Container(width: 56, height: 56, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle), child: const Icon(Icons.login, color: AppColors.onPrimary)),
        const SizedBox(height: 16),
        Text(contextLabel != null ? 'Masuk untuk $contextLabel' : 'Masuk dulu yuk!', style: AppTextStyles.h2, textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text('Kamu perlu masuk atau daftar dulu untuk melanjutkan aksi ini. Tenang, cepat kok.', style: AppTextStyles.bodyMuted, textAlign: TextAlign.center),
        const SizedBox(height: 20),
        SizedBox(width: double.infinity, child: ElevatedButton(
          onPressed: () { Navigator.pop(context); context.push('/login?next=${next ?? GoRouterState.of(context).uri.toString()}'); },
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: AppColors.onPrimary, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999))),
          child: const Text('Masuk / Daftar'),
        )),
        const SizedBox(height: 8),
        TextButton(onPressed: () => Navigator.pop(context), child: Text('Nanti dulu', style: AppTextStyles.label)),
        const SizedBox(height: 8),
      ]),
    ),
  );
}
