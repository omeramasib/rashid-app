import '../../domain/entities/interview_start_response.dart';
import 'interview_question_model.dart';

class InterviewStartResponseModel extends InterviewStartResponse {
  const InterviewStartResponseModel({
    required super.simulationId,
    required super.interviewSettingId,
    required super.questions,
  });

  factory InterviewStartResponseModel.fromJson(Map<String, dynamic> json) {
    return InterviewStartResponseModel(
      simulationId: json['simulation_id'] ?? '',
      interviewSettingId: json['interview_setting_id'] ?? '',
      questions: (json['questions'] as List<dynamic>?)
              ?.map((e) =>
                  InterviewQuestionModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'simulation_id': simulationId,
      'interview_setting_id': interviewSettingId,
      'questions':
          questions.map((q) => (q as InterviewQuestionModel).toJson()).toList(),
    };
  }
}
