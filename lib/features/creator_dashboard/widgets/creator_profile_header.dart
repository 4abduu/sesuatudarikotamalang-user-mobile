import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/creator_avatar.dart';
import '../../../data/models/creator_model.dart';

/// Kepala dasbor kreator: avatar toko (ketuk untuk membuka Profil Toko),
/// sapaan, dan bio. Menggantikan dua baris `Text` "Halo, ...!" dan bio pada
/// `creator_dashboard_screen.dart`.
class CreatorProfileHeader extends StatelessWidget {
  final CreatorModel? artisan;
  final String fallbackName;
  final VoidCallback onEdit;

  const CreatorProfileHeader({
    super.key,
    required this.artisan,
    required this.fallbackName,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final displayName = artisan?.name ?? fallbackName;
    final bio = artisan?.bio ?? '';
    final subtitle = bio.isNotEmpty ? bio : (artisan?.name ?? 'Kreator Mitra Kota Malang');
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: onEdit,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              CreatorAvatar(avatarUrl: artisan?.avatarUrl, name: displayName, size: 64),
              Positioned(
                right: -2,
                bottom: -2,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.background, width: 2),
                  ),
                  child: const Icon(Icons.photo_camera, size: 12, color: AppColors.onPrimary),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Halo, $displayName!',
                style: AppTextStyles.h1.copyWith(fontSize: 26),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                subtitle,
                style: AppTextStyles.bodyMuted,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
