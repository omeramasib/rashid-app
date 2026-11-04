import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/interview_start_response.dart';
import '../repositories/interview_repository.dart';

class RetryInterviewGenerationUseCase
    implements UseCase<InterviewStartResponse, RetryInterviewGenerationParams> {
  final InterviewRepository repository;

  RetryInterviewGenerationUseCase(this.repository);

  @override
  Future<Either<Failure, InterviewStartResponse>> call(
    RetryInterviewGenerationParams params,
  ) {
    return repository.retryGeneration(params.simulationId);
  }
}

class RetryInterviewGenerationParams extends Equatable {
  final String simulationId;

  const RetryInterviewGenerationParams({required this.simulationId});

  @override
  List<Object> get props => [simulationId];
}
