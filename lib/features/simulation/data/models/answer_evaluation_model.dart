import '../../domain/entities/answer_evaluation.dart';
import 'interview_json.dart';

class AnswerEvaluationModel extends AnswerEvaluation {
  const AnswerEvaluationModel({
    required super.questionId,
    required super.skipped,
    super.score,
    super.strengths,
    super.weaknesses,
    super.suggestedAnswer,
  });

  factory AnswerEvaluationModel.fromJson(Map<String, dynamic> json) {
    return AnswerEvaluationModel(
      questionId: requiredString(json['question_id']),
      score: optionalInt(json['score']),
      strengths: optionalStringList(json['strengths']),
      weaknesses: optionalStringList(json['weaknesses']),
      suggestedAnswer: optionalString(json['suggested_answer']),
      skipped: flag(json['skipped']),
    );
  }
}
