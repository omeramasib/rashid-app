import 'package:equatable/equatable.dart';

class InterviewQuestion extends Equatable {
  final String id;
  final String questionText;
  final String? audioUrl;
  final String? category;
  final int? position;

  const InterviewQuestion({
    required this.id,
    required this.questionText,
    this.audioUrl,
    this.category,
    this.position,
  });

  @override
  List<Object?> get props => [id, questionText, audioUrl, category, position];
}
