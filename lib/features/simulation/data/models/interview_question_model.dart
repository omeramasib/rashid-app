import '../../domain/entities/interview_question.dart';
import 'interview_json.dart';
import 'question_audio_model.dart';

class InterviewQuestionModel extends InterviewQuestion {
  const InterviewQuestionModel({
    required super.id,
    required super.questionText,
    super.audioUrl,
    super.category,
    super.position,
    super.audio,
  });

  factory InterviewQuestionModel.fromJson(Map<String, dynamic> json) {
    return InterviewQuestionModel(
      id: requiredString(json['id']),
      questionText: requiredString(json['question_text']),
      audioUrl: optionalString(json['audio_url']),
      category: optionalString(json['category']),
      position: optionalInt(json['position']),
      audio: questionAudioHintFromJson(json['audio']),
    );
  }

  Map<String, dynamic> toJson() {
    final hint = audio;
    return {
      'id': id,
      'question_text': questionText,
      'audio_url': audioUrl,
      'category': category,
      'position': position,
      if (hint != null)
        'audio': {
          'status': hint.status.name,
          'url': hint.url,
          'mime_type': hint.mimeType,
          'duration_ms': hint.durationMs,
        },
    };
  }
}
