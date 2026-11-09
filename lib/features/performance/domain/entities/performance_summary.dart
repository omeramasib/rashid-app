import 'package:equatable/equatable.dart';

enum PerformanceStatus { excellent, average, poor }

class RecentInterview extends Equatable {
  final String simulationId;
  final String? jobField;
  final DateTime? completedAt;
  final int? score;
  final PerformanceStatus? performanceStatus;

  const RecentInterview({
    required this.simulationId,
    this.jobField,
    this.completedAt,
    this.score,
    this.performanceStatus,
  });

  @override
  List<Object?> get props => [
        simulationId,
        jobField,
        completedAt,
        score,
        performanceStatus,
      ];
}

class PerformanceSummary extends Equatable {
  final int? totalSimulations;
  final int? averageScore;

  /// Aggregate high score. This is not a simulation id.
  final int? bestScore;

  /// Simulation that produced [bestScore].
  ///
  /// `GET /api/v1/interview/performance/summary` does not return this today.
  /// `GET /api/v1/interview/simulations` returns `id`, `job_field`, and
  /// `created_at` only, with no score and no paging, so the best simulation
  /// cannot be derived. The best-result share stays disabled until the
  /// summary includes `best_simulation_id`. Do not substitute a recent id.
  final String? bestSimulationId;
  final List<RecentInterview> recentInterviews;

  const PerformanceSummary({
    this.totalSimulations,
    this.averageScore,
    this.bestScore,
    this.bestSimulationId,
    this.recentInterviews = const [],
  });

  @override
  List<Object?> get props => [
        totalSimulations,
        averageScore,
        bestScore,
        bestSimulationId,
        recentInterviews,
      ];
}
