import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

void showAuthGateSheet(BuildContext context, {String? next, String? contextLabel}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => Padding(
      // Kartu modal TSX: p-6, jarak antar blok 16 (space-y-4), teks center.
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 56, height: 56, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle), child: const Icon(Icons.login, size: 28, color: AppColors.onPrimary)),
        const SizedBox(height: 16),
        Text(contextLabel != null ? 'Masuk untuk $contextLabel' : 'Masuk dulu yuk!', style: AppTextStyles.h2, textAlign: TextAlign.center),
        const SizedBox(height: 4),
        Text('Kamu perlu masuk atau daftar dulu untuk melanjutkan aksi ini. Tenang, cepat kok.', style: AppTextStyles.bodyMuted, textAlign: TextAlign.center),
        const SizedBox(height: 16),
        SizedBox(width: double.infinity, child: ElevatedButton(
          onPressed: () { Navigator.pop(context); context.push('/login?next=${next ?? GoRouterState.of(context).uri.toString()}'); },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary, foregroundColor: AppColors.onPrimary,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 12),
            textStyle: GoogleFonts.baloo2(fontSize: 14, fontWeight: FontWeight.w700),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
          ),
          child: const Text('Masuk / Daftar'),
        )),
        const SizedBox(height: 16),
        SizedBox(width: double.infinity, child: TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 6), minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
          child: Text('Nanti dulu', style: AppTextStyles.label.copyWith(color: AppColors.muted)),
        )),
        const SizedBox(height: 8),
      ]),
    ),
  );
}
