import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/question_audio.dart';
import '../repositories/interview_repository.dart';

class GetQuestionAudioUseCase
    implements UseCase<QuestionAudio, GetQuestionAudioParams> {
  GetQuestionAudioUseCase(this.repository);

  final InterviewRepository repository;

  @override
  Future<Either<Failure, QuestionAudio>> call(GetQuestionAudioParams params) {
    return repository.getQuestionAudio(params.questionId);
  }

  /// Drops an in-flight audio request. Signed URLs are not kept.
  void cancel() => repository.cancelQuestionAudio();
}

class GetQuestionAudioParams extends Equatable {
  const GetQuestionAudioParams(this.questionId);

  final String questionId;

  @override
  List<Object> get props => [questionId];
}
