import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class RatingStars extends StatelessWidget {
  final double value;
  final double size;
  final bool showValue;
  const RatingStars({super.key, required this.value, this.size = 14, this.showValue = false});

  @override
  Widget build(BuildContext context) {
    final rating = value.clamp(0.0, 5.0).toDouble();
    return Row(mainAxisSize: MainAxisSize.min, children: [
      ...List.generate(5, (i) {
        final fill = (rating - i).clamp(0.0, 1.0).toDouble();
        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            children: [
              Icon(Icons.star, size: size, color: AppColors.border),
              if (fill > 0)
                ClipRect(
                  child: SizedBox(
                    width: size * fill,
                    height: size,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Icon(Icons.star, size: size, color: AppColors.mustard),
                    ),
                  ),
                ),
            ],
          ),
        );
      }),
      if (showValue) ...[
        const SizedBox(width: 4),
        Text(value.toStringAsFixed(1), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.foreground.withValues(alpha: 0.8))),
      ],
    ]);
  }
}
