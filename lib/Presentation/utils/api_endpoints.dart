class ApiEndpoints {
  static String baseUrl = "http://10.0.2.2:8000";
  static String secondUrl = "${baseUrl}api/";
  String loginUrl = "$baseUrl/auth/login";
  String registerUrl = "$baseUrl/auth/signup";
  String forgotPasswordUrl = "${secondUrl}auth/forgot-password";
  String verifyOtpUrl = "${secondUrl}auth/verify-code";
  String resetPasswordUrl = "${secondUrl}auth/reset-password";
}