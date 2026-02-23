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
      StartInterviewByJobParams params) async {
    return await repository.startByJob(
      jobField: params.jobField,
      interviewType: params.interviewType,
      difficulty: params.difficulty,
      language: params.language,
      simulationType: params.simulationType,
      numQuestions: params.numQuestions,
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

  const StartInterviewByJobParams({
    required this.jobField,
    required this.interviewType,
    required this.difficulty,
    required this.language,
    required this.simulationType,
    required this.numQuestions,
  });

  @override
  List<Object> get props => [
        jobField,
        interviewType,
        difficulty,
        language,
        simulationType,
        numQuestions,
      ];
}
