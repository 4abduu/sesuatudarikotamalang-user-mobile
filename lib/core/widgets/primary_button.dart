import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../theme/app_shadows.dart';

/// Tombol utama: pil terracotta, teks Baloo 2 14px bold, bayangan sticker
/// (sesuai tombol utama di referensi TSX). Bayangan hanya tampil saat aktif.
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;
  final bool fullWidth;
  final bool loading;

  /// Warna latar opsional (default terracotta). Mis. moss untuk "Buat Draft" AI.
  final Color? color;

  /// Override opsional untuk tombol ringkas (Baloo 2 13 bold, padding vertikal
  /// 10) seperti "Simpan Nama" / "Buka Dashboard Kreator" pada referensi TSX.
  /// Saat [verticalPadding] diisi dan [fullWidth] false, padding horizontal 16.
  final double? verticalPadding;
  final double? fontSize;

  /// Tampilkan bayangan sticker saat aktif (default true).
  final bool showShadow;
  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.fullWidth = true,
    this.loading = false,
    this.color,
    this.verticalPadding,
    this.fontSize,
    this.showShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    return SizedBox(
      width: fullWidth ? double.infinity : null,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          boxShadow: (enabled && showShadow)
              ? (color == null
                  ? AppShadows.sticker
                  : [BoxShadow(color: color!.withValues(alpha: 0.15), blurRadius: 8, offset: const Offset(0, 3))])
              : null,
        ),
        child: ElevatedButton(
          onPressed: loading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: color ?? AppColors.primary, foregroundColor: AppColors.onPrimary,
            padding: EdgeInsets.symmetric(
              vertical: verticalPadding ?? 14,
              horizontal: (verticalPadding != null && !fullWidth) ? 16 : 0,
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
            elevation: 0,
            textStyle: GoogleFonts.baloo2(fontSize: fontSize ?? 14, fontWeight: FontWeight.w700),
          ),
          child: loading
            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.onPrimary))
            : Row(mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center, children: [
                if (icon != null) ...[icon!, const SizedBox(width: 8)],
                Text(label),
              ]),
        ),
      ),
    );
  }
}
