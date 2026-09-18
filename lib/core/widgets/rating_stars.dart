import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class RatingStars extends StatelessWidget {
  final double value;
  final double size;
  final bool showValue;
  const RatingStars({super.key, required this.value, this.size = 14, this.showValue = false});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      ...List.generate(5, (i) {
        final filled = i < value.round();
        return Icon(Icons.star, size: size, color: filled ? AppColors.mustard : AppColors.border);
      }),
      if (showValue) ...[
        const SizedBox(width: 4),
        Text(value.toStringAsFixed(1), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.foreground)),
      ],
    ]);
  }
}
