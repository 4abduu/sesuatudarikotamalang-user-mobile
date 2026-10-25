import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/password_validator.dart';

class PasswordCriteriaChecklist extends StatelessWidget {
  final String password;

  /// Bungkus dengan kotak surface (radius 12, border, padding 12) seperti TSX
  /// `PasswordCriteria` di register / lupa password.
  final bool boxed;
  const PasswordCriteriaChecklist({super.key, required this.password, this.boxed = false});

  @override
  Widget build(BuildContext context) {
    final v = validatePassword(password);
    final items = [
      ('Minimal 8 karakter', v.lengthOk),
      ('Huruf besar', v.hasUpper),
      ('Huruf kecil', v.hasLower),
      ('Angka', v.hasNumber),
    ];
    final list = Column(crossAxisAlignment: CrossAxisAlignment.start, children: items.map((i) {
      final ok = i.$2;
      final isLast = boxed && i == items.last;
      return Padding(padding: EdgeInsets.only(bottom: isLast ? 0 : 4), child: Row(children: [
        Icon(ok ? Icons.check_circle : Icons.radio_button_unchecked, size: 16, color: ok ? AppColors.moss : AppColors.muted),
        const SizedBox(width: 6),
        Text(i.$1, style: TextStyle(fontSize: 12, color: ok ? AppColors.moss : AppColors.muted)),
      ]));
    }).toList());
    if (!boxed) return list;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
      child: list,
    );
  }
}
