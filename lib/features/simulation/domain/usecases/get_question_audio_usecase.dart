import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/interview_question.dart';
import '../entities/question_audio.dart';
import '../repositories/interview_repository.dart';

class GetQuestionAudioUseCase
    implements UseCase<QuestionAudioFile, GetQuestionAudioParams> {
  GetQuestionAudioUseCase(this.repository);

  final InterviewRepository repository;

  @override
  Future<Either<Failure, QuestionAudioFile>> call(
    GetQuestionAudioParams params,
  ) {
    return repository.getQuestionAudio(
      params.question,
      prefetch: params.prefetch,
    );
  }

  Future<void> evict(InterviewQuestion question) {
    return repository.evictQuestionAudio(question);
  }

  /// Drops in-flight audio requests. Cached files stay until [discard].
  void cancel() => repository.cancelQuestionAudio();

  Future<void> discard() => repository.endQuestionAudio();
}

class GetQuestionAudioParams extends Equatable {
  const GetQuestionAudioParams(this.question, {this.prefetch = false});

  final InterviewQuestion question;
  final bool prefetch;

  @override
  List<Object> get props => [question, prefetch];
}
