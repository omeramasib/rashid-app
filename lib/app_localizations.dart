import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppLocalizations {
  final Locale? locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      AppLocalizationsDelegate();

  late Map<String, String> _localizedString;

  Future<bool> loadJsonLanguage() async {
    final jsonString = await rootBundle.loadString(
      'assets/lang/${locale!.languageCode}.json',
    );
    Map<String, dynamic> jsonMap = json.decode(jsonString);
    _localizedString = jsonMap.map((key, value) {
      return MapEntry(key, value.toString());
    });
    return true;
  }

  String translate(String key, [Map<String, String>? args]) {
    var value = _localizedString[key] ?? '';
    if (value.isEmpty || args == null) return value;
    for (final entry in args.entries) {
      value = value.replaceAll('{${entry.key}}', entry.value);
    }
    return value;
  }

  static String tr(
    BuildContext context,
    String key, [
    Map<String, String>? args,
  ]) {
    return of(context)?.translate(key, args) ?? '';
  }

  /// Translates known hardcoded fallback messages. Server-provided text is kept.
  static String message(BuildContext context, String raw) {
    final key = _knownMessages[raw];
    if (key == null) return raw;
    final translated = tr(context, key);
    return translated.isEmpty ? raw : translated;
  }

  static const Map<String, String> _knownMessages = {
    'LinkedIn authentication failed': 'err_linkedin_auth_failed',
    'LinkedIn authentication not configured. Please set up Clerk.':
        'err_linkedin_not_configured',
    'Unexpected CV profile response': 'err_unexpected_cv_profile',
    'Your skills could not be refreshed': 'err_skills_refresh_failed',
    'Unexpected upload response': 'err_unexpected_upload',
    'Unexpected analysis response': 'err_unexpected_analysis',
    'Request cancelled': 'err_request_cancelled',
    'Unknown error': 'err_unknown',
    'Could not read the saved CV': 'err_cv_read',
    'Could not save the CV on this device': 'err_cv_save',
    'Connection timed out': 'err_timeout',
    'No internet connection': 'err_offline',
    'Password reset request failed': 'reset_server_error',
    'CV not found': 'interview_err_cv_missing',
    'answer_text is required when not skipping':
        'interview_err_answer_required',
    'answer_text is too long': 'interview_err_answer_long',
    'This question has already been evaluated':
        'interview_err_already_evaluated',
    'This answer is already being evaluated': 'interview_err_evaluating',
    'An evaluated question cannot be skipped': 'interview_err_cannot_skip',
    'Interview is not accepting answers': 'interview_err_not_accepting',
    'Interview cannot be finished': 'interview_err_cannot_finish',
    'Interview generation cannot be retried': 'interview_err_cannot_retry',
    'Simulation not found': 'interview_err_simulation_missing',
    'Question not found': 'interview_err_question_missing',
    'Interview AI provider timed out': 'interview_err_provider_timeout',
    'Interview AI provider quota is exhausted': 'interview_err_provider_quota',
    'Interview AI provider is temporarily unavailable':
        'interview_err_provider',
    'Interview AI provider is not configured': 'interview_err_provider',
    'Interview AI provider is unavailable': 'interview_err_provider',
    'Interview AI provider returned an incomplete result':
        'interview_err_provider_invalid',
    'Interview AI provider returned an invalid result':
        'interview_err_provider_invalid',
    'Interview answer could not be saved': 'interview_err_save_answer',
    'Interview questions could not be saved': 'interview_err_save_questions',
    'Interview AI quota exceeded': 'interview_err_quota',
    'job_field is too short': 'interview_job_field_invalid',
    'job_description is too short': 'interview_description_short',
    'job_description is too long': 'interview_description_long',
    'Audio interviews are not supported': 'interview_err_audio',
  };
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'ar'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    AppLocalizations localizations = AppLocalizations(locale);
    await localizations.loadJsonLanguage();
    return localizations;
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}
