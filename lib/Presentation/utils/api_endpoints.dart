class ApiEndpoints {
  static String baseUrl = "https://develop.fnrcoerp.com/";
  static String secondUrl = "${baseUrl}api/";
  static String employeesUrl = "${baseUrl}api/employee";
  String loginUrl = "$employeesUrl/login";
  String forgotPasswordUrl = "${secondUrl}auth/forgot-password";
  String verifyOtpUrl = "${secondUrl}auth/verify-code";
  String resetPasswordUrl = "${secondUrl}auth/reset-password";

  // Menu
  String faqsUrl = "${secondUrl}faqs";
  String surveyUrl = "${secondUrl}surveys";
  String surveyDetailsUrl = "${secondUrl}surveys/view";
  String storeSurveyAnswersUrl = "${secondUrl}surveys/store-answers";

  // Others
  String pollUrl = "${secondUrl}poll";
  String pollDetailsUrl = "${secondUrl}poll/view";
  String tutorialUrl = "${secondUrl}tutorial";

  // Home
  String contentUrl = "${secondUrl}content";
  String announcementUrl = "${secondUrl}announcement";
  String uiWidgetsUrl = "${secondUrl}ui-widget";


  // Ticket
  String ticketUrl = "${secondUrl}ticket";
}
