import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();
  static TextStyle get display => GoogleFonts.baloo2(fontWeight: FontWeight.w800, color: AppColors.foreground);
  static TextStyle get h1 => GoogleFonts.baloo2(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.foreground);
  static TextStyle get h2 => GoogleFonts.baloo2(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.foreground);
  static TextStyle get h3 => GoogleFonts.baloo2(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.foreground);
  static TextStyle get title => GoogleFonts.baloo2(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.foreground);
  static TextStyle get body => GoogleFonts.poppins(fontSize: 14, color: AppColors.foreground);
  static TextStyle get bodyMuted => GoogleFonts.poppins(fontSize: 14, color: AppColors.muted);
  static TextStyle get label => GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.foreground);
  static TextStyle get caption => GoogleFonts.poppins(fontSize: 12, color: AppColors.muted);
  static TextStyle get price => GoogleFonts.baloo2(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.primary);
  static TextStyle get eyebrow => GoogleFonts.baloo2(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary, letterSpacing: 1.2);
}
