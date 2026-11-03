import '../../core/network/api_endpoints.dart' as core;

class ApiEndpoints {
  static String get baseUrl => core.ApiEndpoints.baseUrl;
  static String get secondUrl => '$baseUrl/api/';
  String loginUrl = "$baseUrl/auth/login";
  String registerUrl = "$baseUrl/auth/signup";
  String forgotPasswordUrl = "${secondUrl}auth/forgot-password";
  String verifyOtpUrl = "${secondUrl}auth/verify-code";
  String resetPasswordUrl = "${secondUrl}auth/reset-password";
}
