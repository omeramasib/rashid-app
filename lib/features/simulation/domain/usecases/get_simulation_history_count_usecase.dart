import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/simulation_history_count.dart';
import '../repositories/interview_repository.dart';

class GetSimulationHistoryCountUseCase
    implements UseCase<SimulationHistoryCount, NoParams> {
  final InterviewRepository repository;

  GetSimulationHistoryCountUseCase(this.repository);

  @override
  Future<Either<Failure, SimulationHistoryCount>> call(NoParams params) {
    return repository.getSimulationHistoryCount();
  }
}
