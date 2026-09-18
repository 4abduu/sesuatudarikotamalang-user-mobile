import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class BottomNavBar extends StatelessWidget {
  const BottomNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    int currentIndex = 0;
    if (location.startsWith('/katalog')) {
      currentIndex = 1;
    } else if (location.startsWith('/kreator')) {
      currentIndex = 2;
    } else if (location.startsWith('/notifikasi')) {
      currentIndex = 3;
    } else if (location.startsWith('/akun') || location.startsWith('/login')) {
      currentIndex = 4;
    }

    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (i) {
        switch (i) {
          case 0: context.go('/'); break;
          case 1: context.go('/katalog'); break;
          case 2: context.go('/kreator'); break;
          case 3: context.go('/notifikasi'); break;
          case 4: context.go('/akun'); break;
        }
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Beranda'),
        BottomNavigationBarItem(icon: Icon(Icons.grid_view_outlined), activeIcon: Icon(Icons.grid_view), label: 'Katalog'),
        BottomNavigationBarItem(icon: Icon(Icons.palette_outlined), activeIcon: Icon(Icons.palette), label: 'Kreator'),
        BottomNavigationBarItem(icon: Icon(Icons.notifications_outlined), activeIcon: Icon(Icons.notifications), label: 'Notif'),
        BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Akun'),
      ],
    );
  }
}
