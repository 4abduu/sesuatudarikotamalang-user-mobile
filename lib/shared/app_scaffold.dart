import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/widgets/brand_app_bar.dart';
import 'bottom_nav_bar.dart';

class AppScaffold extends StatelessWidget {
  final String? title;
  final Widget body;
  final Widget? floatingActionButton;
  final bool showBottomNav;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showSearchAction;
  const AppScaffold({
    super.key,
    this.title,
    required this.body,
    this.floatingActionButton,
    this.showBottomNav = true,
    this.actions,
    this.leading,
    this.showSearchAction = true,
  });

  @override
  Widget build(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;
    final shouldShowBottomNav = showBottomNav && _isPrimaryNavigationPath(path);
    return Scaffold(
      appBar: BrandAppBar(
        title: title,
        leading: leading,
        actions: actions,
        showSearchAction: showSearchAction,
      ),
      body: body,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: shouldShowBottomNav ? const BottomNavBar() : null,
    );
  }

  /// Bottom navigation hanya untuk halaman utama/list. Detail, form, auth,
  /// checkout, dan subhalaman akun/dashboard memakai tombol kembali agar fokus
  /// pengguna tidak terpecah dan tidak terlihat seperti berpindah tab.
  bool _isPrimaryNavigationPath(String path) {
    if (path == '/' || path == '/katalog' || path == '/kreator' || path == '/akun') {
      return true;
    }
    if (path == '/pencarian') return false;
    const hiddenPrefixes = [
      '/produk/',
      '/kreator/',
      '/reservasi',
      '/login',
      '/register',
      '/lupa-password',
      '/daftar-kreator',
      '/dashboard-kreator',
      '/akun/',
      '/tentang',
    ];
    return !hiddenPrefixes.any(path.startsWith);
  }
}
