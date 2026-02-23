import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/share_result.dart';
import '../../domain/repositories/home_repository.dart';
import '../datasources/home_remote_datasource.dart';

class HomeRepositoryImpl implements HomeRepository {
  final HomeRemoteDataSource remoteDataSource;

  HomeRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, ShareResult>> shareLastInterviewResult(
      String? caption) async {
    try {
      final response = await remoteDataSource.shareLastInterviewResult(caption);
      return Right(response);
    } on AppException catch (e) {
      return Left(_mapExceptionToFailure(e));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  Failure _mapExceptionToFailure(AppException e) {
    if (e is UserNotFoundException) return UserNotFoundFailure(e.message);
    if (e is BadRequestException) return BadRequestFailure(e.message);
    if (e is UnauthorizedException) return UnauthorizedFailure(e.message);
    if (e is ForbiddenException) return ForbiddenFailure(e.message);
    if (e is NotFoundException) return NotFoundFailure(e.message);
    if (e is NetworkException) return NetworkFailure(e.message);
    if (e is UpstreamException) return UpstreamFailure(e.message);
    return ServerFailure(e.message);
  }
}
