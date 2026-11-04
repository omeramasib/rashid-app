import '../../domain/entities/interview_finish_result.dart';
import 'interview_json.dart';

class InterviewFinishResultModel extends InterviewFinishResult {
  const InterviewFinishResultModel({
    required super.simulationId,
    super.score,
    super.performanceStatus,
    super.totalQuestions,
    super.answeredQuestions,
    super.skippedQuestions,
    super.unansweredQuestions,
    super.status,
    super.reportStatus,
    super.reportSummary,
  });

  factory InterviewFinishResultModel.fromJson(Map<String, dynamic> json) {
    return InterviewFinishResultModel(
      simulationId: requiredString(json['simulation_id']),
      score: optionalInt(json['score']),
      performanceStatus: optionalString(json['performance_status']),
      totalQuestions: optionalInt(json['total_questions']),
      answeredQuestions: optionalInt(json['answered_questions']),
      skippedQuestions: optionalInt(json['skipped_questions']),
      unansweredQuestions: optionalInt(json['unanswered_questions']),
      status: optionalString(json['status']),
      reportStatus: optionalString(json['report_status']),
      reportSummary: optionalString(json['report_summary']),
    );
  }
}
