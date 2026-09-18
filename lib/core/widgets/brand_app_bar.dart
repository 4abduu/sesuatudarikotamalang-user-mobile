import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../routing/route_names.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/notifications/providers/notifications_provider.dart';

/// Brand-flavored AppBar used by AppScaffold on every screen.
///
/// Always shows two trailing actions:
///   1. A search icon → pushes `/pencarian` (global search).
///   2. A bell icon → pushes `/notifikasi`. Shows a small unread-count
///      badge when [NotificationsProvider] has unread items.
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
    final auth = context.watch<AuthProvider>();
    final notifications = context.watch<NotificationsProvider>();
    final unread = auth.isAuthenticated ? notifications.unreadCount : 0;
    return AppBar(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.foreground,
      elevation: 0,
      leading: leading ?? (canPop ? const BackButton() : null),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primary, AppColors.primaryLight],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.brush, size: 16, color: AppColors.onPrimary),
          ),
          if (title != null) ...[
            const SizedBox(width: 8),
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
            ),
          ],
        ],
      ),
      actions: [
        IconButton(
          tooltip: 'Cari',
          icon: const Icon(Icons.search, color: AppColors.foreground),
          onPressed: () => context.push(RouteNames.pencarian),
        ),
        IconButton(
          tooltip: 'Notifikasi',
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.notifications_none, color: AppColors.foreground),
              if (unread > 0)
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: AppColors.destructive,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: AppColors.background, width: 1.5),
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      unread > 9 ? '9+' : '$unread',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.onPrimary),
                    ),
                  ),
                ),
            ],
          ),
          onPressed: () => context.push(RouteNames.notifications),
        ),
        if (actions != null) ...actions!,
      ],
    );
  }
}
