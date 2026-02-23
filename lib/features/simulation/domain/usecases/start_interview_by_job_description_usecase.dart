import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/interview_start_response.dart';
import '../repositories/interview_repository.dart';

class StartInterviewByJobDescriptionUseCase
    implements
        UseCase<InterviewStartResponse, StartInterviewByJobDescriptionParams> {
  final InterviewRepository repository;

  StartInterviewByJobDescriptionUseCase(this.repository);

  @override
  Future<Either<Failure, InterviewStartResponse>> call(
      StartInterviewByJobDescriptionParams params) async {
    return await repository.startByJobDescription(
      jobDescription: params.jobDescription,
      interviewType: params.interviewType,
      difficulty: params.difficulty,
      language: params.language,
      simulationType: params.simulationType,
      numQuestions: params.numQuestions,
    );
  }
}

class StartInterviewByJobDescriptionParams extends Equatable {
  final String jobDescription;
  final String interviewType;
  final String difficulty;
  final String language;
  final String simulationType;
  final int numQuestions;

  const StartInterviewByJobDescriptionParams({
    required this.jobDescription,
    required this.interviewType,
    required this.difficulty,
    required this.language,
    required this.simulationType,
    required this.numQuestions,
  });

  @override
  List<Object> get props => [
        jobDescription,
        interviewType,
        difficulty,
        language,
        simulationType,
        numQuestions,
      ];
}
