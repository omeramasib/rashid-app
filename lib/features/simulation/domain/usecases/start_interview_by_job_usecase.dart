import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/interview_start_response.dart';
import '../repositories/interview_repository.dart';

class StartInterviewByJobUseCase
    implements UseCase<InterviewStartResponse, StartInterviewByJobParams> {
  final InterviewRepository repository;

  StartInterviewByJobUseCase(this.repository);

  @override
  Future<Either<Failure, InterviewStartResponse>> call(
    StartInterviewByJobParams params,
  ) {
    return repository.startByJob(
      jobField: params.jobField,
      interviewType: params.interviewType,
      difficulty: params.difficulty,
      language: params.language,
      simulationType: params.simulationType,
      numQuestions: params.numQuestions,
      cvId: params.cvId,
    );
  }
}

class StartInterviewByJobParams extends Equatable {
  final String jobField;
  final String interviewType;
  final String difficulty;
  final String language;
  final String simulationType;
  final int numQuestions;
  final String? cvId;

  const StartInterviewByJobParams({
    required this.jobField,
    required this.interviewType,
    required this.difficulty,
    required this.language,
    required this.simulationType,
    required this.numQuestions,
    this.cvId,
  });

  @override
  List<Object?> get props => [
        jobField,
        interviewType,
        difficulty,
        language,
        simulationType,
        numQuestions,
        cvId,
      ];
}
