class ApiEndpoints {
  static String baseUrl = "https://develop.fnrcoerp.com/";
  static String secondUrl = "${baseUrl}api/";
  String loginUrl = "$baseUrl/auth/login";
  String registerUrl = "$baseUrl/auth/signup";
  String forgotPasswordUrl = "${secondUrl}auth/forgot-password";
  String verifyOtpUrl = "${secondUrl}auth/verify-code";
  String resetPasswordUrl = "${secondUrl}auth/reset-password";
}
