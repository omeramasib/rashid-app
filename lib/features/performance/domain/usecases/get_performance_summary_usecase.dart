import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/performance_summary.dart';
import '../repositories/performance_repository.dart';

class GetPerformanceSummaryUseCase
    implements UseCase<PerformanceSummary, NoParams> {
  final PerformanceRepository repository;

  GetPerformanceSummaryUseCase(this.repository);

  @override
  Future<Either<Failure, PerformanceSummary>> call(NoParams params) {
    return repository.getSummary();
  }
}
