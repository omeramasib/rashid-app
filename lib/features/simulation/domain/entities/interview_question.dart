import 'package:equatable/equatable.dart';

class InterviewQuestion extends Equatable {
  final String id;
  final String questionText;
  final String? audioUrl;

  const InterviewQuestion({
    required this.id,
    required this.questionText,
    this.audioUrl,
  });

  @override
  List<Object?> get props => [id, questionText, audioUrl];
}
