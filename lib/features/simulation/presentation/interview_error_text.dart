import 'package:flutter/widgets.dart';

import '../../../app_localizations.dart';
import '../../../core/error/failures.dart';
import '../domain/failures/interview_start_failure.dart';

String interviewErrorText(BuildContext context, Failure failure) {
  final cause = failure is InterviewStartFailure ? failure.cause : failure;
  final known = AppLocalizations.message(context, cause.message);
  if (known != cause.message) return known;
  final key = _fallbackKey(cause);
  if (key != null) {
    final translated = AppLocalizations.tr(context, key);
    if (translated.isNotEmpty) return translated;
  }
  if (cause.message.isNotEmpty) return cause.message;
  return AppLocalizations.tr(context, 'err_unknown');
}

/// The backend closed the session. Finishing again is safe.
bool interviewSessionClosed(Failure failure) {
  final cause = failure is InterviewStartFailure ? failure.cause : failure;
  if (cause is! ConflictFailure) return false;
  final message = cause.message.toLowerCase();
  return message.contains('not accepting answers') ||
      message.contains('cannot be finished');
}

String? performanceBandLabel(BuildContext context, String? status) {
  switch (status) {
    case 'excellent':
      return AppLocalizations.tr(context, 'rating_excellent');
    case 'average':
      return AppLocalizations.tr(context, 'rating_average');
    case 'poor':
      return AppLocalizations.tr(context, 'rating_poor');
    default:
      return status;
  }
}

String? _fallbackKey(Failure failure) {
  if (failure is RequestTimeoutFailure || failure is GatewayTimeoutFailure) {
    return 'err_timeout';
  }
  if (failure is NetworkFailure) return 'err_offline';
  if (failure is UnauthorizedFailure || failure is ForbiddenFailure) {
    return 'interview_err_unauthorized';
  }
  if (failure is NotFoundFailure) return 'interview_err_not_found';
  if (failure is ConflictFailure) return 'interview_err_conflict';
  if (failure is BadRequestFailure || failure is ValidationFailure) {
    return 'interview_err_invalid';
  }
  if (failure is RateLimitFailure) return 'interview_err_quota';
  if (failure is UpstreamFailure || failure is ServiceUnavailableFailure) {
    return 'interview_err_provider';
  }
  return null;
}
