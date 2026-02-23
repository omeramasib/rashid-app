import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/interview_repository.dart';

class SubmitAnswerUseCase implements UseCase<void, SubmitAnswerParams> {
  final InterviewRepository repository;

  SubmitAnswerUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(SubmitAnswerParams params) async {
    return await repository.submitAnswer(
      questionId: params.questionId,
      skipped: params.skipped,
      answerText: params.answerText,
    );
  }
}

class SubmitAnswerParams extends Equatable {
  final String questionId;
  final bool skipped;
  final String? answerText;

  const SubmitAnswerParams({
    required this.questionId,
    required this.skipped,
    this.answerText,
  });

  @override
  List<Object?> get props => [questionId, skipped, answerText];
}
