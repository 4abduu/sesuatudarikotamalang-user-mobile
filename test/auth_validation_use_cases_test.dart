import 'package:flutter_test/flutter_test.dart';
import 'package:sesuatu_darikota_malang/domain/auth/auth_validation_use_cases.dart';

void main() {
  test('login validation rejects empty credentials without calling a repository', () {
    final validate = ValidateLoginUseCase();

    expect(validate('', 'password'), isNotNull);
    expect(validate('user@example.com', ''), isNotNull);
    expect(validate('user@example.com', 'password'), isNull);
  });

  test('register validation enforces matching strong password', () {
    final validate = ValidateRegisterUseCase();

    expect(validate('', 'user@example.com', 'Rahasia1!', 'Rahasia1!'), isNotNull);
    expect(validate('User', 'user@example.com', 'lemah', 'lemah'), isNotNull);
    expect(validate('User', 'user@example.com', 'Rahasia1!', 'berbeda'), isNotNull);
    expect(validate('User', 'user@example.com', 'Rahasia1!', 'Rahasia1!'), isNull);
  });
}
