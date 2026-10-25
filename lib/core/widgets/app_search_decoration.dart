import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

/// Dekorasi kolom pencarian sesuai referensi TSX (katalog & daftar kreator):
/// radius 12 + border 1px (dari tema), ikon cari 16px muted, teks/hint 13px.
/// Isi `onChanged` tetap diatur oleh layar pemakainya.
InputDecoration appSearchDecoration(String hint) => InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.poppins(fontSize: 13, color: AppColors.muted),
      // px-3 (12) + ikon 16 + gap 8 → teks mulai di x = 36.
      prefixIcon: const Padding(
        padding: EdgeInsets.only(left: 12, right: 8),
        child: Icon(Icons.search, size: 16, color: AppColors.muted),
      ),
      prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
      isDense: true,
      // py-2 + py-1 pada input = 12 vertikal.
      contentPadding: const EdgeInsets.fromLTRB(0, 12, 12, 12),
    );

/// Gaya teks yang diketik di kolom pencarian (13px, foreground).
TextStyle get appSearchTextStyle =>
    GoogleFonts.poppins(fontSize: 13, color: AppColors.foreground);
