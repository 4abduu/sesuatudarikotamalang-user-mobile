import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';

/// Chip status produk di "Produk Saya". Nilai `displayStatus` berasal dari backend:
/// menunggu, aktif, ditolak, ditarik, disembunyikan.
class ProductStatusBadge extends StatelessWidget {
  final String displayStatus;
  const ProductStatusBadge({super.key, required this.displayStatus});

  static String labelFor(String status) {
    switch (status) {
      case 'menunggu':
        return 'Menunggu persetujuan';
      case 'ditolak':
        return 'Ditolak';
      case 'ditarik':
        return 'Ditarik: tidak laku 6 bulan';
      case 'disembunyikan':
        return 'Disembunyikan admin';
      default:
        return 'Aktif';
    }
  }

  static Color colorFor(String status) {
    switch (status) {
      case 'menunggu':
        return AppColors.mustard;
      case 'ditolak':
      case 'disembunyikan':
        return AppColors.destructive;
      case 'ditarik':
        return AppColors.muted;
      default:
        return AppColors.moss;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = colorFor(displayStatus);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        labelFor(displayStatus),
        style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}

