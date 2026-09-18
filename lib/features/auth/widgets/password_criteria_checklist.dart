import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/password_validator.dart';

class PasswordCriteriaChecklist extends StatelessWidget {
  final String password;
  const PasswordCriteriaChecklist({super.key, required this.password});

  @override
  Widget build(BuildContext context) {
    final v = validatePassword(password);
    final items = [
      ('Minimal 8 karakter', v.lengthOk),
      ('Huruf besar', v.hasUpper),
      ('Huruf kecil', v.hasLower),
      ('Angka', v.hasNumber),
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: items.map((i) {
      final ok = i.$2;
      return Padding(padding: const EdgeInsets.only(bottom: 4), child: Row(children: [
        Icon(ok ? Icons.check_circle : Icons.radio_button_unchecked, size: 16, color: ok ? AppColors.moss : AppColors.muted),
        const SizedBox(width: 6),
        Text(i.$1, style: TextStyle(fontSize: 12, color: ok ? AppColors.moss : AppColors.muted)),
      ]));
    }).toList());
  }
}
