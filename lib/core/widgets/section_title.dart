import 'package:flutter/material.dart';
import '../theme/app_text_styles.dart';

class SectionTitle extends StatelessWidget {
  final String? eyebrow;
  final String title;
  final bool centered;
  const SectionTitle({super.key, this.eyebrow, required this.title, this.centered = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: centered ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        if (eyebrow != null) Text(eyebrow!.toUpperCase(), style: AppTextStyles.eyebrow),
        if (eyebrow != null) const SizedBox(height: 4),
        Text(title, style: AppTextStyles.h2),
      ],
    );
  }
}
