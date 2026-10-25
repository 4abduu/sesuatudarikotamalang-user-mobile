import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

class SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;
  final bool fullWidth;

  /// Warna border (default terracotta). Mis. moss untuk tombol WhatsApp.
  final Color borderColor;

  /// Varian ringkas: teks Poppins 13 semibold, padding vertikal 12, jarak
  /// ikon 6 (tombol WhatsApp/Shopee di detail produk pada TSX).
  final bool compact;

  /// Override opsional untuk tombol Baloo 2 bold dengan padding vertikal 12
  /// (mis. "Batal" / "Buat Ulang" pada referensi TSX form cerita).
  final double? verticalPadding;
  final double? fontSize;
  const SecondaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.fullWidth = true,
    this.borderColor = AppColors.primary,
    this.compact = false,
    this.verticalPadding,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: fullWidth ? double.infinity : null,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: fontSize != null ? borderColor : AppColors.foreground,
          side: BorderSide(color: borderColor, width: 1.5),
          backgroundColor: fontSize != null ? AppColors.surface : null,
          padding: EdgeInsets.symmetric(
            vertical: verticalPadding ?? (compact ? 12 : 14),
            horizontal: (verticalPadding != null && !fullWidth) ? 16 : 0,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
          textStyle: fontSize != null
              ? GoogleFonts.baloo2(fontSize: fontSize, fontWeight: FontWeight.w700)
              : (compact ? GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600) : null),
        ),
        child: Row(mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center, children: [
          if (icon != null) ...[icon!, SizedBox(width: compact ? 6 : 8)],
          Text(label),
        ]),
      ),
    );
  }
}
