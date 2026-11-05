import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/performance_summary.dart';

abstract class PerformanceRepository {
  Future<Either<Failure, PerformanceSummary>> getSummary();
}
