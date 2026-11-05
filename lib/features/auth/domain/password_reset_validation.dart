class PasswordResetValidation {
  static final RegExp _email = RegExp(
    r'^[^\s@]+@(?:[A-Za-z0-9](?:[A-Za-z0-9-]*[A-Za-z0-9])?\.)+[A-Za-z]{2,}$',
  );
  static final RegExp _otp = RegExp(r'^[0-9]{6}$');

  static bool isValidEmail(String value) => _email.hasMatch(value.trim());
  static bool isValidOtp(String value) => _otp.hasMatch(value);
  static bool isValidPassword(String value) => value.runes.length >= 8;
  static bool passwordsMatch(String password, String confirmation) =>
      password == confirmation;
}
