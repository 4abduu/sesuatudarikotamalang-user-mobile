import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../data/models/notification_model.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/notifications/providers/notifications_provider.dart';
import '../../../shared/app_scaffold.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (!auth.isAuthenticated) {
      return AppScaffold(title: 'Notifikasi', body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.lock, size: 48, color: AppColors.muted),
        const SizedBox(height: 12),
        Text('Masuk untuk melihat notifikasi', style: AppTextStyles.h3),
        const SizedBox(height: 16),
        ElevatedButton(onPressed: () => context.push('/login'), child: const Text('Masuk')),
      ])));
    }
    final provider = context.watch<NotificationsProvider>();
    final items = provider.notifications;
    return AppScaffold(
      title: 'Notifikasi',
      actions: [
        if (provider.unreadCount > 0)
          TextButton(
            onPressed: () => provider.markAllRead(),
            child: const Text('Tandai dibaca', style: TextStyle(fontSize: 12)),
          ),
      ],
      body: items.isEmpty
        ? const EmptyState(icon: Icons.notifications_none, title: 'Belum ada notifikasi')
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (_, i) {
              final n = items[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _NotificationCard(
                  notification: n,
                  onTap: () => provider.markRead(n.id),
                ),
              );
            },
          ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;
  const _NotificationCard({required this.notification, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final n = notification;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: n.read ? null : Border.all(color: AppColors.primary.withValues(alpha: 0.25), width: 1),
            boxShadow: AppShadows.soft,
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: _typeColor(n.type).withValues(alpha: 0.12), shape: BoxShape.circle),
              child: Icon(_typeIcon(n.type), color: _typeColor(n.type), size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(child: Text(n.title, style: AppTextStyles.label.copyWith(fontWeight: n.read ? FontWeight.w500 : FontWeight.w700))),
                    Text(n.date, style: AppTextStyles.caption),
                  ]),
                  const SizedBox(height: 2),
                  Text(n.body, style: GoogleFonts.poppins(fontSize: 12, color: AppColors.muted), maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            if (!n.read) ...[
              const SizedBox(width: 8),
              Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
            ],
          ]),
        ),
      ),
    );
  }

  IconData _typeIcon(NotificationType t) {
    switch (t) {
      case NotificationType.order: return Icons.shopping_bag_outlined;
      case NotificationType.review: return Icons.star_outline;
      case NotificationType.creator: return Icons.palette_outlined;
      case NotificationType.system: return Icons.notifications_outlined;
    }
  }

  Color _typeColor(NotificationType t) {
    switch (t) {
      case NotificationType.order: return AppColors.primary;
      case NotificationType.review: return AppColors.mustard;
      case NotificationType.creator: return AppColors.moss;
      case NotificationType.system: return AppColors.muted;
    }
  }
}
