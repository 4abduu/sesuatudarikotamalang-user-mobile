import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// Kolom isian bergaya TSX `Field` (halaman login/register/lupa password):
/// label 13px di atas, kotak radius 12 bg surface + border, ikon prefix 16px
/// muted, teks 14px. Hanya tampilan — controller & handler tetap dari layar.
class AuthField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData? icon;
  final int maxLines;
  final TextInputType? keyboardType;
  final bool obscureText;
  final ValueChanged<String>? onChanged;
  final int? maxLength;
  final Widget? suffix;

  const AuthField({
    super.key,
    required this.label,
    required this.controller,
    this.icon,
    this.maxLines = 1,
    this.keyboardType,
    this.obscureText = false,
    this.onChanged,
    this.maxLength,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.label),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          onChanged: onChanged,
          maxLength: maxLength,
          maxLines: maxLines,
          style: GoogleFonts.poppins(fontSize: 14, color: AppColors.foreground),
          decoration: authInputDecoration(icon: icon, suffix: suffix, topAligned: maxLines > 1),
        ),
      ],
    );
  }
}

/// Dekorasi kotak isian TSX `Field` (juga dipakai dropdown kategori).
InputDecoration authInputDecoration({IconData? icon, Widget? suffix, bool topAligned = false}) {
  return InputDecoration(
    counterText: '',
    isDense: true,
    // px-3 (12) + ikon 16 + gap 8; py-3 (12) vertikal.
    // topAligned: isian multiline → ikon rata atas (mt-1 + py-3 = 16).
    prefixIcon: icon == null
        ? null
        : topAligned
            ? Column(children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 16, 8, 0),
                  child: Icon(icon, size: 16, color: AppColors.muted),
                ),
              ])
            : Padding(
                padding: const EdgeInsets.only(left: 12, right: 8),
                child: Icon(icon, size: 16, color: AppColors.muted),
              ),
    prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
    suffixIcon: suffix == null
        ? null
        : Padding(padding: const EdgeInsets.only(right: 12), child: suffix),
    suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
    contentPadding: EdgeInsets.fromLTRB(icon == null ? 12 : 0, 12, suffix == null ? 12 : 8, 12),
  );
}

/// Ikon mata 16px muted untuk suffix kolom password.
class AuthEyeToggle extends StatelessWidget {
  final bool visible;
  final VoidCallback onTap;
  const AuthEyeToggle({super.key, required this.visible, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Icon(
        visible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
        size: 16,
        color: AppColors.muted,
      ),
    );
  }
}
