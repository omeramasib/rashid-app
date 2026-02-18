class ApiEndpoints {
  static const String baseUrl = "http://127.0.0.1:8000";

  // Auth endpoints
  static const String loginEmailUrl = "$baseUrl/auth/login/email";
  static const String registerEmailUrl = "$baseUrl/auth/register/email";
  static const String loginLinkedInUrl = "$baseUrl/auth/login/linkedin";
  static const String registerLinkedInUrl = "$baseUrl/auth/register/linkedin";
  static const String forgotPasswordUrl = "$baseUrl/auth/forgot-password";
  static const String resetPasswordUrl = "$baseUrl/auth/reset-password";
  static const String changePasswordUrl = "$baseUrl/auth/change-password";
  static const String logoutUrl = "$baseUrl/auth/logout";
  static const String currentUserUrl = "$baseUrl/auth/me";
}
