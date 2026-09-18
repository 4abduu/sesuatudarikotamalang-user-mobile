class PasswordValidation {
  final bool lengthOk;
  final bool hasUpper;
  final bool hasLower;
  final bool hasNumber;
  const PasswordValidation({
    required this.lengthOk,
    required this.hasUpper,
    required this.hasLower,
    required this.hasNumber,
  });
  bool get isValid => lengthOk && hasUpper && hasLower && hasNumber;
}

PasswordValidation validatePassword(String pw) {
  return PasswordValidation(
    lengthOk: pw.length >= 8,
    hasUpper: pw.contains(RegExp(r'[A-Z]')),
    hasLower: pw.contains(RegExp(r'[a-z]')),
    hasNumber: pw.contains(RegExp(r'[0-9]')),
  );
}
