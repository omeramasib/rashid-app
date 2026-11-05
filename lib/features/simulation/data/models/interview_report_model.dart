import '../../domain/entities/interview_report.dart';
import 'interview_json.dart';

class InterviewReportQuestionModel extends InterviewReportQuestion {
  const InterviewReportQuestionModel({
    required super.id,
    required super.questionText,
    required super.isSkipped,
    super.answerText,
    super.evaluationScore,
    super.strengths,
    super.weaknesses,
    super.suggestedAnswer,
    super.category,
    super.position,
  });

  factory InterviewReportQuestionModel.fromJson(Map<String, dynamic> json) {
    return InterviewReportQuestionModel(
      id: requiredString(json['id']),
      questionText: requiredString(json['question_text']),
      answerText: optionalString(json['answer_text']),
      evaluationScore: optionalInt(json['evaluation_score']),
      strengths: optionalStringList(json['strengths']),
      weaknesses: optionalStringList(json['weaknesses']),
      suggestedAnswer: optionalString(json['suggested_answer']),
      isSkipped: flag(json['is_skipped']),
      category: optionalString(json['category']),
      position: optionalInt(json['position']),
    );
  }
}

class InterviewReportModel extends InterviewReport {
  const InterviewReportModel({
    required super.simulationId,
    required super.questions,
    super.score,
    super.performanceStatus,
    super.jobField,
    super.interviewType,
    super.difficulty,
    super.language,
    super.status,
    super.reportStatus,
    super.reportSummary,
    super.strengths,
    super.improvements,
    super.recommendations,
    super.date,
    super.completedAt,
    super.answeredQuestions,
    super.skippedQuestions,
    super.unansweredQuestions,
  });

  factory InterviewReportModel.fromJson(Map<String, dynamic> json) {
    final rawQuestions = json['questions'];
    final questions = rawQuestions is List
        ? rawQuestions
            .whereType<Map>()
            .map((item) => InterviewReportQuestionModel.fromJson(
                  Map<String, dynamic>.from(item),
                ))
            .toList()
        : <InterviewReportQuestionModel>[];
    return InterviewReportModel(
      simulationId: requiredString(json['simulation_id']),
      score: optionalInt(json['score']),
      performanceStatus: optionalString(json['performance_status']),
      jobField: optionalString(json['job_field']),
      interviewType: optionalString(json['interview_type']),
      difficulty: optionalString(json['difficulty']),
      language: optionalString(json['language']),
      status: optionalString(json['status']),
      reportStatus: optionalString(json['report_status']),
      reportSummary: optionalString(json['report_summary']),
      strengths: optionalStringList(json['strengths']),
      improvements: optionalStringList(json['improvements']),
      recommendations: optionalStringList(json['recommendations']),
      date: optionalString(json['date']),
      completedAt: optionalString(json['completed_at']),
      answeredQuestions: optionalInt(json['answered_questions']),
      skippedQuestions: optionalInt(json['skipped_questions']),
      unansweredQuestions: optionalInt(json['unanswered_questions']),
      questions: questions,
    );
  }
}
