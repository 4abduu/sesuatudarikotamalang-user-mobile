import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class LoadMoreFooter extends StatelessWidget {
  final bool isLoading;
  final bool hasMore;
  final bool isEmpty;

  const LoadMoreFooter({
    super.key,
    required this.isLoading,
    required this.hasMore,
    this.isEmpty = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isEmpty) return const SizedBox.shrink();

    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
          ),
        ),
      );
    }

    if (!hasMore) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: Text(
            'Semua sudah ditampilkan',
            style: AppTextStyles.caption.copyWith(color: AppColors.muted),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}

