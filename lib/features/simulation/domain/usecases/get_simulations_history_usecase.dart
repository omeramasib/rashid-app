import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/interview_simulation_history.dart';
import '../repositories/interview_repository.dart';

class GetSimulationsHistoryUseCase
    implements UseCase<List<InterviewSimulationHistory>, NoParams> {
  final InterviewRepository repository;

  GetSimulationsHistoryUseCase(this.repository);

  @override
  Future<Either<Failure, List<InterviewSimulationHistory>>> call(
      NoParams params) async {
    return await repository.getSimulationsHistory();
  }
}
