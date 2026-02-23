import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/interview_repository.dart';

class FinishInterviewUseCase implements UseCase<void, FinishInterviewParams> {
  final InterviewRepository repository;

  FinishInterviewUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(FinishInterviewParams params) async {
    return await repository.finishInterview(params.simulationId);
  }
}

class FinishInterviewParams extends Equatable {
  final String simulationId;

  const FinishInterviewParams({required this.simulationId});

  @override
  List<Object> get props => [simulationId];
}
