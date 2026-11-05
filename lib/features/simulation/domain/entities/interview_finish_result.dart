import 'package:equatable/equatable.dart';

class InterviewFinishResult extends Equatable {
  final String simulationId;
  final int? score;
  final String? performanceStatus;
  final int? totalQuestions;
  final int? answeredQuestions;
  final int? skippedQuestions;
  final int? unansweredQuestions;
  final String? status;
  final String? reportStatus;
  final String? reportSummary;

  const InterviewFinishResult({
    required this.simulationId,
    this.score,
    this.performanceStatus,
    this.totalQuestions,
    this.answeredQuestions,
    this.skippedQuestions,
    this.unansweredQuestions,
    this.status,
    this.reportStatus,
    this.reportSummary,
  });

  @override
  List<Object?> get props => [
        simulationId,
        score,
        performanceStatus,
        totalQuestions,
        answeredQuestions,
        skippedQuestions,
        unansweredQuestions,
        status,
        reportStatus,
        reportSummary,
      ];
}
