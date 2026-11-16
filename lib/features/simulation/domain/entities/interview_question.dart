import 'package:equatable/equatable.dart';

import 'question_audio.dart';

class InterviewQuestion extends Equatable {
  final String id;
  final String questionText;
  final String? audioUrl;
  final String? category;
  final int? position;
  final QuestionAudioHint? audio;

  const InterviewQuestion({
    required this.id,
    required this.questionText,
    this.audioUrl,
    this.category,
    this.position,
    this.audio,
  });

  @override
  List<Object?> get props =>
      [id, questionText, audioUrl, category, position, audio];
}
