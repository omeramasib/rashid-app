import 'package:equatable/equatable.dart';

class InterviewReportQuestion extends Equatable {
  final String id;
  final String questionText;
  final String? answerText;
  final int? evaluationScore;
  final List<String>? strengths;
  final List<String>? weaknesses;
  final String? suggestedAnswer;
  final bool isSkipped;
  final String? category;
  final int? position;

  const InterviewReportQuestion({
    required this.id,
    required this.questionText,
    required this.isSkipped,
    this.answerText,
    this.evaluationScore,
    this.strengths,
    this.weaknesses,
    this.suggestedAnswer,
    this.category,
    this.position,
  });

  @override
  List<Object?> get props => [
        id,
        questionText,
        answerText,
        evaluationScore,
        strengths,
        weaknesses,
        suggestedAnswer,
        isSkipped,
        category,
        position,
      ];
}

class InterviewReport extends Equatable {
  final String simulationId;
  final int? score;
  final String? performanceStatus;
  final String? jobField;
  final String? interviewType;
  final String? difficulty;
  final String? language;
  final String? status;
  final String? reportStatus;
  final String? reportSummary;
  final List<String>? strengths;
  final List<String>? improvements;
  final List<String>? recommendations;
  final String? date;
  final String? completedAt;
  final int? answeredQuestions;
  final int? skippedQuestions;
  final int? unansweredQuestions;
  final List<InterviewReportQuestion> questions;

  const InterviewReport({
    required this.simulationId,
    required this.questions,
    this.score,
    this.performanceStatus,
    this.jobField,
    this.interviewType,
    this.difficulty,
    this.language,
    this.status,
    this.reportStatus,
    this.reportSummary,
    this.strengths,
    this.improvements,
    this.recommendations,
    this.date,
    this.completedAt,
    this.answeredQuestions,
    this.skippedQuestions,
    this.unansweredQuestions,
  });

  @override
  List<Object?> get props => [
        simulationId,
        score,
        performanceStatus,
        jobField,
        interviewType,
        difficulty,
        language,
        status,
        reportStatus,
        reportSummary,
        strengths,
        improvements,
        recommendations,
        date,
        completedAt,
        answeredQuestions,
        skippedQuestions,
        unansweredQuestions,
        questions,
      ];
}
