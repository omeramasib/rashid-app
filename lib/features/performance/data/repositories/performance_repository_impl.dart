import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/performance_summary.dart';
import '../../domain/repositories/performance_repository.dart';
import '../datasources/performance_remote_datasource.dart';

class PerformanceRepositoryImpl implements PerformanceRepository {
  final PerformanceRemoteDataSource remoteDataSource;

  PerformanceRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, PerformanceSummary>> getSummary() async {
    try {
      final summary = await remoteDataSource.getSummary();
      return Right(summary);
    } on AppException catch (error) {
      return Left(_mapExceptionToFailure(error));
    } catch (error) {
      return Left(ServerFailure(error.toString()));
    }
  }

  Failure _mapExceptionToFailure(AppException error) {
    if (error is RequestTimeoutException) {
      return RequestTimeoutFailure(error.message);
    }
    if (error is GatewayTimeoutException) {
      return GatewayTimeoutFailure(error.message);
    }
    if (error is UserNotFoundException) {
      return UserNotFoundFailure(error.message);
    }
    if (error is BadRequestException) return BadRequestFailure(error.message);
    if (error is UnauthorizedException) {
      return UnauthorizedFailure(error.message);
    }
    if (error is ForbiddenException) return ForbiddenFailure(error.message);
    if (error is NotFoundException) return NotFoundFailure(error.message);
    if (error is ConflictException) return ConflictFailure(error.message);
    if (error is ValidationException) return ValidationFailure(error.message);
    if (error is RateLimitException) return RateLimitFailure(error.message);
    if (error is PayloadTooLargeException) {
      return PayloadTooLargeFailure(error.message);
    }
    if (error is ServiceUnavailableException) {
      return ServiceUnavailableFailure(error.message);
    }
    if (error is UpstreamException) return UpstreamFailure(error.message);
    if (error is RequestCancelledException) {
      return RequestCancelledFailure(error.message);
    }
    if (error is NetworkException) return NetworkFailure(error.message);
    return ServerFailure(error.message);
  }
}
