import '../../domain/entities/interview_report.dart';

class InterviewReportModel extends InterviewReport {
  const InterviewReportModel({
    required super.score,
    required super.strengths,
    required super.weaknesses,
    super.overallFeedback,
  });

  factory InterviewReportModel.fromJson(Map<String, dynamic> json) {
    return InterviewReportModel(
      score: json['score'] ?? 0,
      strengths: List<String>.from(json['strengths'] ?? []),
      weaknesses: List<String>.from(json['weaknesses'] ?? []),
      overallFeedback: json['overall_feedback'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'score': score,
      'strengths': strengths,
      'weaknesses': weaknesses,
      'overall_feedback': overallFeedback,
    };
  }
}
