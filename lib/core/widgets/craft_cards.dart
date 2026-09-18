import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_shadows.dart';
import '../theme/app_text_styles.dart';

/// A small statistic card with a circular icon, big value, and label.
/// Used in dashboards (creator dashboard, account home stats).
class StatChipCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color? iconColor;
  const StatChipCard({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final fg = iconColor ?? AppColors.primary;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(color: fg.withValues(alpha: 0.12), shape: BoxShape.circle),
            child: Icon(icon, color: fg, size: 18),
          ),
          const SizedBox(height: 8),
          Text(value, style: AppTextStyles.h3),
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.muted)),
        ],
      ),
    );
  }
}

/// A menu tile built as a custom card (NOT ListTile) with icon, title,
/// optional subtitle, and a trailing chevron. Tap navigates via [onTap].
/// Shadowed with [AppShadows.soft].
class MenuCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Color? iconColor;
  final Widget? trailing;
  const MenuCard({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.iconColor,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final fg = iconColor ?? AppColors.primary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppShadows.soft,
          ),
          child: Row(children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: fg.withValues(alpha: 0.12), shape: BoxShape.circle),
              child: Icon(icon, color: fg, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, style: AppTextStyles.label),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!, style: AppTextStyles.caption),
                  ],
                ],
              ),
            ),
            if (trailing != null) trailing! else const Icon(Icons.chevron_right, color: AppColors.muted, size: 20),
          ]),
        ),
      ),
    );
  }
}

/// A section card with an eyebrow label, title, optional trailing widget,
/// and a child body. Used to group related content blocks on screens
/// (account home, dashboard, etc.).
class SectionCard extends StatelessWidget {
  final String? eyebrow;
  final String title;
  final Widget? trailing;
  final Widget child;
  final EdgeInsets padding;
  const SectionCard({
    super.key,
    this.eyebrow,
    required this.title,
    this.trailing,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (eyebrow != null) Text(eyebrow!.toUpperCase(), style: AppTextStyles.eyebrow),
                  Text(title, style: AppTextStyles.h3),
                ],
              ),
              if (trailing != null) trailing!,
            ],
          ),
          child,
        ],
      ),
    );
  }
}
