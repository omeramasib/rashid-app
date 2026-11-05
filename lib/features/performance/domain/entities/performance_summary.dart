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
  final int? bestScore;
  final List<RecentInterview> recentInterviews;

  const PerformanceSummary({
    this.totalSimulations,
    this.averageScore,
    this.bestScore,
    this.recentInterviews = const [],
  });

  @override
  List<Object?> get props => [
        totalSimulations,
        averageScore,
        bestScore,
        recentInterviews,
      ];
}
