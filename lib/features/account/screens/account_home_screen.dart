import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/craft_cards.dart';
import '../../../data/models/user_model.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../shared/app_scaffold.dart';

/// Account home screen — entry point of the "Akun" tab.
///
/// For guests: shows a friendly login prompt with an icon, message,
/// and a "Masuk" button → `/login`.
///
/// For logged-in users: shows a profile header (avatar circle with
/// initials or photo, name, email, role badge) followed by a menu
/// list of custom cards (NOT ListTile):
///   - Riwayat Pesanan → /akun/pesanan
///   - Ulasan Saya → /akun/ulasan
///   - Status Pengajuan Kreator → /akun/pengajuan
///   - If creator: Dashboard Kreator → /dashboard-kreator
///     Else: Jadi Kreator → /daftar-kreator
///   - Pengaturan Akun → /akun/pengaturan
/// Plus a destructive "Keluar" button at the bottom.
class AccountHomeScreen extends StatelessWidget {
  const AccountHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return AppScaffold(
      title: 'Akun',
      body: auth.isAuthenticated ? const _LoggedInBody() : const _GuestBody(),
    );
  }
}

class _GuestBody extends StatelessWidget {
  const _GuestBody();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock_outline, size: 36, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            Text('Masuk untuk lanjut', style: AppTextStyles.h2, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              'Belum punya akun? Yuk masuk dulu untuk lihat riwayat pesanan, ulasan, dan status pengajuan kreatormu.',
              style: AppTextStyles.bodyMuted,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => context.push('/login'),
                icon: const Icon(Icons.login, size: 18),
                label: const Text('Masuk'),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => context.go('/'),
              child: const Text('Lanjut sebagai tamu', style: TextStyle(fontSize: 12, color: AppColors.muted)),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoggedInBody extends StatelessWidget {
  const _LoggedInBody();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user!;
    final isCreator = auth.isCreator;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ProfileHeader(
            name: user.name,
            email: user.email,
            role: user.role,
            avatarUrl: user.avatarUrl,
          ),
          const SizedBox(height: 20),
          MenuCard(
            icon: Icons.receipt_long_outlined,
            title: 'Riwayat Pesanan',
            subtitle: 'Lihat dan lacak pesananmu',
            onTap: () => context.push('/akun/pesanan'),
          ),
          const SizedBox(height: 10),
          MenuCard(
            icon: Icons.star_outline,
            title: 'Ulasan Saya',
            subtitle: 'Kelola ulasan yang kamu berikan',
            onTap: () => context.push('/akun/ulasan'),
          ),
          const SizedBox(height: 10),
          MenuCard(
            icon: Icons.assignment_outlined,
            title: 'Status Pengajuan Kreator',
            subtitle: 'Cek progres pengajuan konsinyasi',
            onTap: () => context.push('/akun/pengajuan'),
          ),
          const SizedBox(height: 10),
          if (isCreator)
            MenuCard(
              icon: Icons.dashboard_outlined,
              title: 'Dashboard Kreator',
              subtitle: 'Kelola produk & ceritamu',
              iconColor: AppColors.moss,
              onTap: () => context.push('/dashboard-kreator'),
            )
          else
            MenuCard(
              icon: Icons.store_mall_directory_outlined,
              title: 'Jadi Kreator',
              subtitle: 'Konsinyasikan karyamu di Kayutangan',
              iconColor: AppColors.moss,
              onTap: () => context.push('/daftar-kreator'),
            ),
          const SizedBox(height: 10),
          MenuCard(
            icon: Icons.settings_outlined,
            title: 'Pengaturan Akun',
            subtitle: 'Profil, email, dan password',
            onTap: () => context.push('/akun/pengaturan'),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                await auth.logout();
                if (context.mounted) context.go('/');
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.destructive,
                side: const BorderSide(color: AppColors.destructive, width: 1.5),
              ),
              icon: const Icon(Icons.logout, size: 18),
              label: const Text('Keluar'),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final String name;
  final String email;
  final Role role;
  final String? avatarUrl;
  const _ProfileHeader({required this.name, required this.email, required this.role, this.avatarUrl});

  @override
  Widget build(BuildContext context) {
    final initials = name.split(' ').where((w) => w.isNotEmpty).map((w) => w[0]).take(2).join().toUpperCase();
    final hasAvatar = avatarUrl != null && avatarUrl!.isNotEmpty;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryLight],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppShadows.sticker,
      ),
      child: Row(children: [
        CircleAvatar(
          radius: 32,
          backgroundColor: AppColors.onPrimary,
          backgroundImage: hasAvatar ? FileImage(File(avatarUrl!)) : null,
          child: !hasAvatar
            ? Text(initials.isEmpty ? '?' : initials, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.primary, fontFamily: 'Baloo 2'))
            : null,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: AppTextStyles.h3.copyWith(color: AppColors.onPrimary)),
              const SizedBox(height: 2),
              Text(email, style: AppTextStyles.caption.copyWith(color: AppColors.onPrimary.withValues(alpha: 0.85))),
              const SizedBox(height: 8),
              _RoleBadge(role: role),
            ],
          ),
        ),
      ]),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final Role role;
  const _RoleBadge({required this.role});

  @override
  Widget build(BuildContext context) {
    final label = switch (role) {
      Role.creator => 'Kreator',
      Role.buyer => 'Pembeli',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.onPrimary.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.onPrimary.withValues(alpha: 0.4), width: 1),
      ),
      child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.onPrimary)),
    );
  }
}
