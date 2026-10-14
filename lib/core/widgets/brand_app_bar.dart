import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../routing/route_names.dart';

/// Brand-flavored AppBar used by AppScaffold on every screen.
///
/// Trailing actions:
///   1. Search icon → pushes `/pencarian` (global search). Always shown.
///   2. Bell icon → pushes `/notifikasi`. Shows unread-count badge when
///      [NotificationsProvider] has unread items. **Hidden for guests**
///      (notifikasi butuh login).
/// Plus any extra actions the calling screen wants to append.
///
/// This guarantees the global search entry point is reachable from every
/// screen that uses [AppScaffold] (i.e. basically all of them), matching
/// the 3-layer search architecture on the website.
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
    return AppBar(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.foreground,
      elevation: 0,
      leading: leading ?? (canPop ? const BackButton() : null),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(
              'assets/images/logos/logo_sesuatu.jpg',
              width: 36,
              height: 36,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primary, AppColors.primaryLight],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.brush,
                    size: 18, color: AppColors.onPrimary),
              ),
            ),
          ),
          const SizedBox(width: 10),
          if (title != null)
            Flexible(
              child: Text(
                title!,
                style: GoogleFonts.baloo2(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.foreground,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Sesuatu',
                  style: GoogleFonts.baloo2(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.foreground,
                    height: 1.1,
                  ),
                ),
                Text(
                  'DariKota Malang',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                    height: 1.1,
                  ),
                ),
              ],
            ),
        ],
      ),
      actions: [
        IconButton(
          tooltip: 'Cari',
          icon: const Icon(Icons.search, color: AppColors.foreground),
          onPressed: () => context.push(RouteNames.pencarian),
        ),
        if (actions != null) ...actions!,
      ],
    );
  }
}
