import '../../domain/entities/performance_summary.dart';

int? _optionalInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return null;
}

/// Parses a completed-at value as UTC.
///
/// The backend stores naive UTC timestamps, and [DateTime.parse] would
/// otherwise treat a suffix-free value as local time.
DateTime? completedAtUtc(dynamic value) {
  if (value is! String) return null;
  final trimmed = value.trim();
  if (trimmed.isEmpty) return null;
  final parsed = DateTime.tryParse(trimmed);
  if (parsed == null) return null;
  if (parsed.isUtc) return parsed;
  return DateTime.utc(
    parsed.year,
    parsed.month,
    parsed.day,
    parsed.hour,
    parsed.minute,
    parsed.second,
    parsed.millisecond,
    parsed.microsecond,
  );
}

PerformanceStatus? _performanceStatus(dynamic value) {
  if (value is! String) return null;
  switch (value.trim()) {
    case 'excellent':
      return PerformanceStatus.excellent;
    case 'average':
      return PerformanceStatus.average;
    case 'poor':
      return PerformanceStatus.poor;
    default:
      return null;
  }
}

String? _jobField(dynamic value) {
  if (value is! String) return null;
  final trimmed = value.trim();
  if (trimmed.isEmpty) return null;
  return trimmed;
}

class RecentInterviewModel extends RecentInterview {
  const RecentInterviewModel({
    required super.simulationId,
    super.jobField,
    super.completedAt,
    super.score,
    super.performanceStatus,
  });

  static RecentInterviewModel? tryFromJson(Map<String, dynamic> json) {
    final id = json['simulation_id'];
    if (id is! String || id.trim().isEmpty) return null;
    return RecentInterviewModel(
      simulationId: id.trim(),
      jobField: _jobField(json['job_field']),
      completedAt: completedAtUtc(json['completed_at']),
      score: _optionalInt(json['score']),
      performanceStatus: _performanceStatus(json['performance_status']),
    );
  }
}

class PerformanceSummaryModel extends PerformanceSummary {
  const PerformanceSummaryModel({
    super.totalSimulations,
    super.averageScore,
    super.bestScore,
    super.recentInterviews,
  });

  factory PerformanceSummaryModel.fromJson(Map<String, dynamic> json) {
    return PerformanceSummaryModel(
      totalSimulations: _optionalInt(json['total_simulations']),
      averageScore: _optionalInt(json['average_score']),
      bestScore: _optionalInt(json['best_score']),
      recentInterviews: _recentInterviews(json['recent_interviews']),
    );
  }
}

List<RecentInterview> _recentInterviews(dynamic value) {
  if (value is! List) return const [];
  final interviews = <RecentInterviewModel>[];
  for (final item in value) {
    if (item is! Map) continue;
    final interview = RecentInterviewModel.tryFromJson(
      Map<String, dynamic>.from(item),
    );
    if (interview != null) interviews.add(interview);
  }
  return interviews;
}
