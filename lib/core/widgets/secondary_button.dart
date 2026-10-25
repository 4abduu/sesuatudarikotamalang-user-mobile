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
  const SecondaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.fullWidth = true,
    this.borderColor = AppColors.primary,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: fullWidth ? double.infinity : null,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.foreground,
          side: BorderSide(color: borderColor, width: 1.5),
          padding: EdgeInsets.symmetric(vertical: compact ? 12 : 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
          textStyle: compact ? GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600) : null,
        ),
        child: Row(mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center, children: [
          if (icon != null) ...[icon!, SizedBox(width: compact ? 6 : 8)],
          Text(label),
        ]),
      ),
    );
  }
}
