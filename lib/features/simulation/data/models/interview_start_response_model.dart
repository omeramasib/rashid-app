import '../../domain/entities/interview_start_response.dart';
import 'interview_json.dart';
import 'interview_question_model.dart';

class InterviewStartResponseModel extends InterviewStartResponse {
  const InterviewStartResponseModel({
    required super.simulationId,
    required super.interviewSettingId,
    required super.questions,
    super.status,
    super.reportStatus,
  });

  factory InterviewStartResponseModel.fromJson(Map<String, dynamic> json) {
    final rawQuestions = json['questions'];
    final questions = rawQuestions is List
        ? rawQuestions
            .whereType<Map>()
            .map((item) => InterviewQuestionModel.fromJson(
                  Map<String, dynamic>.from(item),
                ))
            .toList()
        : <InterviewQuestionModel>[];
    return InterviewStartResponseModel(
      simulationId: requiredString(json['simulation_id']),
      interviewSettingId: requiredString(json['interview_setting_id']),
      status: optionalString(json['status']),
      reportStatus: optionalString(json['report_status']),
      questions: questions,
    );
  }
}
