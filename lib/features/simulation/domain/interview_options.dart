/// Values accepted by the interview start schemas. Audio is rejected.
abstract final class InterviewOptions {
  static const simulationType = 'text';
  static const types = [
    'technical',
    'behavioral',
    'life_skills',
    'comprehensive'
  ];
  static const difficulties = ['easy', 'medium', 'hard'];
  static const languages = ['English', 'Arabic'];
  static const minQuestions = 1;
  static const maxQuestions = 10;
  static const defaultQuestions = 5;
  static const minJobFieldLength = 2;
  static const maxJobFieldLength = 150;
  static const minJobDescriptionLength = 20;
  static const maxJobDescriptionLength = 8000;
  static const maxAnswerLength = 5000;
}

enum InterviewStartMode { byJob, byJobDescription }

/// Matches the backend, which collapses whitespace before it checks length.
String collapseInterviewWhitespace(String value) {
  return value.split(RegExp(r'\s+')).where((part) => part.isNotEmpty).join(' ');
}
