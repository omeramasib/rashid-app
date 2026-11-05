import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/interview_finish_result.dart';
import '../repositories/interview_repository.dart';

class FinishInterviewUseCase
    implements UseCase<InterviewFinishResult, FinishInterviewParams> {
  final InterviewRepository repository;

  FinishInterviewUseCase(this.repository);

  @override
  Future<Either<Failure, InterviewFinishResult>> call(
    FinishInterviewParams params,
  ) {
    return repository.finishInterview(params.simulationId);
  }
}

class FinishInterviewParams extends Equatable {
  final String simulationId;

  const FinishInterviewParams({required this.simulationId});

  @override
  List<Object> get props => [simulationId];
}
