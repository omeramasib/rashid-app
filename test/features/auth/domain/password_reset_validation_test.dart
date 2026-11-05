import 'package:flutter_test/flutter_test.dart';
import 'package:rashed_app/features/auth/domain/password_reset_validation.dart';

void main() {
  test('email validation accepts trimmed email and rejects malformed email',
      () {
    expect(PasswordResetValidation.isValidEmail(' user@example.com '), isTrue);
    expect(PasswordResetValidation.isValidEmail('user@'), isFalse);
    expect(PasswordResetValidation.isValidEmail('user example.com'), isFalse);
    expect(
        PasswordResetValidation.isValidEmail('user@bad..example.com'), isFalse);
  });

  test('OTP requires exactly six ASCII digits and preserves leading zeroes',
      () {
    expect(PasswordResetValidation.isValidOtp('012345'), isTrue);
    expect(PasswordResetValidation.isValidOtp('12345'), isFalse);
    expect(PasswordResetValidation.isValidOtp('1234567'), isFalse);
    expect(PasswordResetValidation.isValidOtp('١٢٣٤٥٦'), isFalse);
    expect(PasswordResetValidation.isValidOtp('12345a'), isFalse);
  });

  test('password uses eight characters and exact confirmation', () {
    expect(PasswordResetValidation.isValidPassword('1234567'), isFalse);
    expect(PasswordResetValidation.isValidPassword('12345678'), isTrue);
    expect(PasswordResetValidation.isValidPassword('😀😀😀😀'), isFalse);
    expect(PasswordResetValidation.passwordsMatch(' password', 'password'),
        isFalse);
  });
}
