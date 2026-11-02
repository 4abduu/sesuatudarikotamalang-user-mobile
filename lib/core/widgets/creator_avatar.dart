import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

/// Avatar toko/kreator: foto bila ada, selain itu inisial di atas gradien
/// terracotta (sama dengan tampilan kartu kreator sebelumnya).
///
/// [avatarUrl] adalah foto EFEKTIF dari API (foto toko, atau foto akun pemilik
/// bila toko belum punya foto sendiri). Gambar gagal dimuat → jatuh ke inisial.
class CreatorAvatar extends StatelessWidget {
  final String? avatarUrl;
  final String name;
  final double size;
  final bool isOfficial;

  const CreatorAvatar({
    super.key,
    required this.avatarUrl,
    required this.name,
    this.size = 48,
    this.isOfficial = false,
  });

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    return parts.take(2).map((w) => w.substring(0, 1)).join().toUpperCase();
  }

  Widget _fallback() {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryLight],
        ),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: isOfficial
          ? Icon(Icons.verified, size: size * 0.5, color: AppColors.onPrimary)
          : Text(
              _initials,
              style: GoogleFonts.baloo2(
                fontSize: size * 0.3,
                fontWeight: FontWeight.w700,
                color: AppColors.onPrimary,
              ),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final url = avatarUrl;
    if (url == null || url.isEmpty) return _fallback();
    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: Image.network(
          url,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _fallback(),
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return Container(
              color: AppColors.surfaceAlt,
              alignment: Alignment.center,
              child: SizedBox(
                width: size * 0.3,
                height: size * 0.3,
                child: const CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
              ),
            );
          },
        ),
      ),
    );
  }
}
