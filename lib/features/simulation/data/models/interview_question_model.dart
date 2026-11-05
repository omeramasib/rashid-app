import '../../domain/entities/interview_question.dart';
import 'interview_json.dart';

class InterviewQuestionModel extends InterviewQuestion {
  const InterviewQuestionModel({
    required super.id,
    required super.questionText,
    super.audioUrl,
    super.category,
    super.position,
  });

  factory InterviewQuestionModel.fromJson(Map<String, dynamic> json) {
    return InterviewQuestionModel(
      id: requiredString(json['id']),
      questionText: requiredString(json['question_text']),
      audioUrl: optionalString(json['audio_url']),
      category: optionalString(json['category']),
      position: optionalInt(json['position']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question_text': questionText,
      'audio_url': audioUrl,
      'category': category,
      'position': position,
    };
  }
}
