import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? description;
  final Widget? action;
  const EmptyState({super.key, required this.icon, required this.title, this.description, this.action});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      const SizedBox(height: 48),
      Container(width: 56, height: 56, decoration: const BoxDecoration(color: AppColors.surfaceAlt, shape: BoxShape.circle), child: Icon(icon, size: 28, color: AppColors.muted)),
      const SizedBox(height: 12),
      Text(title, style: GoogleFonts.baloo2(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.foreground)),
      if (description != null) ...[const SizedBox(height: 4), Padding(padding: const EdgeInsets.symmetric(horizontal: 32), child: Text(description!, textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 13, color: AppColors.muted)))],
      if (action != null) ...[const SizedBox(height: 16), action!],
      const SizedBox(height: 48),
    ]);
  }
}
