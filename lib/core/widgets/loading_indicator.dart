import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

class LoadingIndicator extends StatelessWidget {
  final String? label;
  const LoadingIndicator({super.key, this.label});

  @override
  Widget build(BuildContext context) {
    return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      const CircularProgressIndicator(color: AppColors.primary),
      if (label != null) ...[const SizedBox(height: 12), Text(label!, style: GoogleFonts.poppins(fontSize: 13, color: AppColors.muted))],
    ]));
  }
}
