import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../routing/route_names.dart';

/// Brand-flavored AppBar used by AppScaffold on every screen.
///
/// Visual mengikuti `_frame.tsx` (BrandAppBar): tinggi 56, border bawah tipis,
/// logo 32px + teks "Sesuatu / DariKota Malang", lalu (jika ada) pemisah "·"
/// dan judul halaman, ikon cari 20px di kanan.
///
/// Trailing actions:
///   1. Search icon → pushes `/pencarian` (global search). Always shown.
/// Plus any extra actions the calling screen wants to append.
class BrandAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Widget? leading;
  final List<Widget>? actions;

  const BrandAppBar({
    super.key,
    this.title,
    this.leading,
    this.actions,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final canPop = ModalRoute.of(context)?.canPop ?? false;
    final hasLeading = leading != null || canPop;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(
          bottom: BorderSide(color: AppColors.border.withValues(alpha: 0.6)),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.foreground.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.foreground,
        elevation: 0,
        scrolledUnderElevation: 0,
        // px-3 (12) di TSX; dengan tombol back: 12 + ikon 20 + gap 8 = 40.
        titleSpacing: hasLeading ? 0 : 12,
        leadingWidth: hasLeading ? 40 : null,
        // Tombol back kustom dari layar (IconButton) ikut diseragamkan: ikon 20px.
        leading: (leading != null
                ? IconButtonTheme(
                    data: IconButtonThemeData(
                      style: IconButton.styleFrom(iconSize: 20, padding: EdgeInsets.zero),
                    ),
                    child: leading!,
                  )
                : null) ??
            (canPop
                ? BackButton(
                    style: ButtonStyle(
                      iconSize: WidgetStateProperty.all(20),
                      padding: WidgetStateProperty.all(EdgeInsets.zero),
                    ),
                  )
                : null),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Logo 32px, radius 10, bayangan terracotta lembut.
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  'assets/images/logos/logo_sesuatu.jpg',
                  width: 32,
                  height: 32,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.primary, AppColors.primaryLight],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.brush,
                        size: 16, color: AppColors.onPrimary),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Teks brand selalu tampil (bukan diganti judul).
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Sesuatu',
                  style: GoogleFonts.baloo2(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.foreground,
                    height: 1.0,
                  ),
                ),
                Text(
                  'DariKota Malang',
                  style: GoogleFonts.baloo2(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                    height: 1.0,
                  ),
                ),
              ],
            ),
            if (title != null) ...[
              const SizedBox(width: 8),
              Text(
                '·',
                style: TextStyle(
                  color: AppColors.muted.withValues(alpha: 0.4),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  title!,
                  style: GoogleFonts.baloo2(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.foreground,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Cari',
            iconSize: 20,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            icon: Icon(
              Icons.search,
              color: AppColors.foreground.withValues(alpha: 0.7),
            ),
            onPressed: () => context.push(RouteNames.pencarian),
          ),
          if (actions != null) ...actions!,
          const SizedBox(width: 12),
        ],
      ),
    );
  }
}
