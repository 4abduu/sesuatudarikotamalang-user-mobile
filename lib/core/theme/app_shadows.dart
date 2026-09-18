import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Centralized shadow presets used by craft cards, sticker badges,
/// elevated buttons, and feature sections across the app.
///
/// Replaces ad-hoc `BoxShadow` lists scattered across widgets with a
/// consistent, brand-aligned look. Use:
///   - [soft] for content cards (subtle, neutral)
///   - [sticker] for sticker-style accents (primary-tinted, tighter)
class AppShadows {
  AppShadows._();

  /// Soft, neutral shadow for content cards & menu tiles.
  static List<BoxShadow> get soft => [
    BoxShadow(
      color: AppColors.foreground.withValues(alpha: 0.08),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  /// Sticker-style accent shadow (primary-tinted, tighter).
  static List<BoxShadow> get sticker => [
    BoxShadow(
      color: AppColors.primary.withValues(alpha: 0.15),
      blurRadius: 8,
      offset: const Offset(0, 3),
    ),
  ];
}
