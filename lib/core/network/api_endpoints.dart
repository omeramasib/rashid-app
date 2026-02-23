class ApiEndpoints {
  static const String baseUrl = 'https://rashed-backend.onrender.com';

  // Auth
  static const String loginEmail = '/auth/login/email';
  static const String registerEmail = '/auth/register/email';
  static const String loginLinkedIn = '/auth/login/linkedin';
  static const String registerLinkedIn = '/auth/register/linkedin';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';
  static const String changePassword = '/auth/change-password';
  static const String logout = '/auth/logout';
  static const String currentUser = '/auth/me';

  // LinkedIn
  static const String linkedInConnect = '/api/v1/linkedin/connect';
  static const String linkedInDisconnect = '/api/v1/linkedin/disconnect';

  // CV
  static const String cvUpload = '/api/v1/cv/upload';
  static const String cvAnalyze = '/api/v1/cv/analyze';
  static const String cvUpdateSkills = '/api/v1/cv/skills/update-skills';
  static const String cvDeleteSkill = '/api/v1/cv/skills/delete';

  // Interview
  static const String interviewStartByJob = '/api/v1/interview/start/by-job';
  static const String interviewStartByJobDesc =
      '/api/v1/interview/start/by-job-description';
  static const String interviewSubmitAnswer = '/api/v1/interview/answer/submit';
  static const String interviewFinish = '/api/v1/interview/finish';
  static const String interviewReport = '/api/v1/interview/report';
  static const String interviewHistory = '/api/v1/interview/simulations';

  // Home
  static const String shareInterviewResult =
      '/api/v1/home/share-last-interview-result';
}
