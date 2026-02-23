import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/share_result.dart';

abstract class HomeRepository {
  Future<Either<Failure, ShareResult>> shareLastInterviewResult(
      String? caption);
}
