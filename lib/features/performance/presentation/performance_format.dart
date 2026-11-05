import 'package:intl/intl.dart';

import '../domain/entities/performance_summary.dart';

String performanceCountText(int? count, String placeholder) {
  if (count == null) return placeholder;
  return '$count';
}

String performanceScoreText(int? score, String placeholder) {
  if (score == null) return placeholder;
  return '$score%';
}

String recentInterviewTitle(String? jobField, String mockTitle) {
  final trimmed = jobField?.trim();
  if (trimmed == null || trimmed.isEmpty) return mockTitle;
  return trimmed;
}

String? performanceStatusLabel(
  PerformanceStatus? status,
  String Function(String key) translate,
) {
  switch (status) {
    case PerformanceStatus.excellent:
      return translate('rating_excellent');
    case PerformanceStatus.average:
      return translate('rating_average');
    case PerformanceStatus.poor:
      return translate('performance_status_poor');
    case null:
      return null;
  }
}

/// Formats a UTC [completedAt] in the device timezone.
///
/// Returns null when the timestamp or locale data cannot be formatted.
String? formatCompletedAt(DateTime? completedAt, String languageCode) {
  if (completedAt == null) return null;
  try {
    return DateFormat('d MMMM y', languageCode).format(completedAt.toLocal());
  } catch (_) {
    return null;
  }
}
