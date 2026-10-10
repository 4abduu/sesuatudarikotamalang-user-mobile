import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../features/auth/providers/auth_provider.dart';

/// Tab definition — id-based (bukan indeks) supaya tidak bergeser saat
/// daftar tab berubah antara guest dan user login.
class _TabDef {
  final String id;
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String route;
  const _TabDef({
    required this.id,
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.route,
  });
}

/// Tab list untuk user yang sudah login (5 tab).
const _userTabs = <_TabDef>[
  _TabDef(id: 'beranda', icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Beranda', route: '/'),
  _TabDef(id: 'katalog', icon: Icons.grid_view_outlined, activeIcon: Icons.grid_view, label: 'Katalog', route: '/katalog'),
  _TabDef(id: 'kreator', icon: Icons.palette_outlined, activeIcon: Icons.palette, label: 'Kreator', route: '/kreator'),
  _TabDef(id: 'notifikasi', icon: Icons.notifications_outlined, activeIcon: Icons.notifications, label: 'Notif', route: '/notifikasi'),
  _TabDef(id: 'akun', icon: Icons.person_outline, activeIcon: Icons.person, label: 'Akun', route: '/akun'),
];

/// Tab list untuk guest (4 tab — "Masuk" menggantikan "Akun", "Notif" dihapus).
const _guestTabs = <_TabDef>[
  _TabDef(id: 'beranda', icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Beranda', route: '/'),
  _TabDef(id: 'katalog', icon: Icons.grid_view_outlined, activeIcon: Icons.grid_view, label: 'Katalog', route: '/katalog'),
  _TabDef(id: 'kreator', icon: Icons.palette_outlined, activeIcon: Icons.palette, label: 'Kreator', route: '/kreator'),
  _TabDef(id: 'masuk', icon: Icons.login, activeIcon: Icons.login, label: 'Masuk', route: '/login'),
];

/// Menentukan id tab yang sedang aktif dari lokasi rute saat ini.
/// Mengembalikan null jika tidak ada tab yang cocok (misalnya di layar login).
String? _activeTabId(String location, List<_TabDef> tabs) {
  // Login screen: tidak ada tab yang aktif.
  if (location.startsWith('/login') ||
      location.startsWith('/register') ||
      location.startsWith('/lupa-password')) {
    return null;
  }
  for (final t in tabs) {
    if (t.id == 'beranda') {
      if (location == '/' || location.startsWith('/produk')) return t.id;
    } else if (t.id == 'kreator') {
      if (location.startsWith('/kreator')) return t.id;
    } else if (t.id == 'masuk') {
      // Tab "Masuk" tidak pernah aktif (layar login = no selection).
      continue;
    } else if (location.startsWith(t.route)) {
      return t.id;
    }
  }
  return null;
}

class BottomNavBar extends StatelessWidget {
  const BottomNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final location = GoRouterState.of(context).uri.toString();
    final tabs = auth.isAuthenticated ? _userTabs : _guestTabs;
    final activeId = _activeTabId(location, tabs);
    final activeIndex = activeId == null ? -1 : tabs.indexWhere((t) => t.id == activeId);

    return BottomNavigationBar(
      currentIndex: activeIndex < 0 ? 0 : activeIndex,
      // Saat di layar login (activeIndex < 0), tidak ada tab yang terlihat
      // terpilih — tetap di indeks 0 tapi currentIndex dipaksa tidak match.
      onTap: (i) {
        final tab = tabs[i];
        if (tab.id == 'masuk') {
          // Guest menekan "Masuk" → buka login dengan next = lokasi asal.
          final next = location.isEmpty || location == '/login' ? '/' : location;
          context.push('/login?next=$next');
          return;
        }
        context.go(tab.route);
      },
      items: tabs
          .map((t) => BottomNavigationBarItem(
                icon: Icon(t.icon),
                activeIcon: Icon(t.activeIcon),
                label: t.label,
              ))
          .toList(),
      // Saat tidak ada tab aktif (layar login), paksa tidak ada yang
      // terlihat terpilih dengan selectedItemColor sama dengan unselectedColor.
      selectedItemColor: activeIndex < 0 ? AppColors.muted : AppColors.primary,
      unselectedItemColor: AppColors.muted,
    );
  }
}
