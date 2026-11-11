import 'entities/performance_summary.dart';

/// Latest scored interview the home card can share.
///
/// Scored means a simulation id and a numeric score. When several scored
/// interviews are present, every one needs `completed_at`; otherwise the
/// latest result is ambiguous and nothing is selected. A single scored
/// interview is the latest result in the returned window.
RecentInterview? latestShareableInterview(
    Iterable<RecentInterview> interviews) {
  final eligible = <RecentInterview>[];
  for (final interview in interviews) {
    if (interview.simulationId.trim().isEmpty || interview.score == null) {
      continue;
    }
    eligible.add(interview);
  }
  if (eligible.isEmpty) return null;
  if (eligible.length == 1) return eligible.single;
  if (eligible.any((interview) => interview.completedAt == null)) return null;

  var latest = eligible.first;
  for (final interview in eligible.skip(1)) {
    final completedAt = interview.completedAt;
    final current = latest.completedAt;
    if (completedAt == null || current == null) return null;
    if (completedAt.isAfter(current)) latest = interview;
  }
  return latest;
}

/// Simulation that produced the best score.
///
/// Only [PerformanceSummary.bestSimulationId] is accepted. Matching
/// [PerformanceSummary.bestScore] against [PerformanceSummary.recentInterviews]
/// is not reliable: several interviews can share a score, and the best
/// interview may be outside that window. Interview history cannot fill the
/// gap because it has no score.
String? bestShareableSimulationId(PerformanceSummary summary) {
  final id = summary.bestSimulationId?.trim();
  if (id == null || id.isEmpty) return null;
  return id;
}
