import 'package:equatable/equatable.dart';

class AnswerEvaluation extends Equatable {
  final String questionId;
  final int? score;
  final List<String>? strengths;
  final List<String>? weaknesses;
  final String? suggestedAnswer;
  final bool skipped;

  const AnswerEvaluation({
    required this.questionId,
    required this.skipped,
    this.score,
    this.strengths,
    this.weaknesses,
    this.suggestedAnswer,
  });

  @override
  List<Object?> get props =>
      [questionId, score, strengths, weaknesses, suggestedAnswer, skipped];
}
