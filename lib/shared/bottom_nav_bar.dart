import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
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

    // Logika tap TIDAK diubah — hanya dipindah dari BottomNavigationBar.onTap
    // ke closure ini supaya tampilan bisa dibuat custom (sesuai _frame.tsx).
    void onTap(int i) {
      final tab = tabs[i];
      if (tab.id == 'masuk') {
        // Guest menekan "Masuk" → buka login dengan next = lokasi asal.
        final next = location.isEmpty || location == '/login' ? '/' : location;
        context.push('/login?next=$next');
        return;
      }
      context.go(tab.route);
    }

    // Visual: border atas tipis, latar surface, px 4 / pt 6 / pb 8.
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.border.withValues(alpha: 0.6)),
        ),
      ),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: 8),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 6, 4, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              for (var i = 0; i < tabs.length; i++)
                Expanded(
                  child: _NavItem(
                    tab: tabs[i],
                    // activeIndex < 0 (layar login) → tidak ada tab terpilih.
                    active: i == activeIndex,
                    onTap: () => onTap(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Satu item tab: lingkaran 32px (tinted primary 10% saat aktif) berisi ikon
/// 20px, lalu label Poppins 11px medium.
class _NavItem extends StatelessWidget {
  final _TabDef tab;
  final bool active;
  final VoidCallback onTap;
  const _NavItem({required this.tab, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.primary : AppColors.muted;
    return Semantics(
      button: true,
      selected: active,
      label: tab.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: active
                      ? AppColors.primary.withValues(alpha: 0.10)
                      : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: Icon(active ? tab.activeIcon : tab.icon, size: 20, color: color),
              ),
              const SizedBox(height: 2),
              Text(
                tab.label,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
