import '../../domain/entities/interview_question.dart';

class InterviewQuestionModel extends InterviewQuestion {
  const InterviewQuestionModel({
    required super.id,
    required super.questionText,
    super.audioUrl,
  });

  factory InterviewQuestionModel.fromJson(Map<String, dynamic> json) {
    return InterviewQuestionModel(
      id: json['id'] ?? '',
      questionText: json['question_text'] ?? '',
      audioUrl: json['audio_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question_text': questionText,
      'audio_url': audioUrl,
    };
  }
}
