import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/linkedin_account.dart';
import '../../domain/repositories/linkedin_repository.dart';
import '../datasources/linkedin_remote_datasource.dart';

class LinkedInRepositoryImpl implements LinkedInRepository {
  final LinkedInRemoteDataSource remoteDataSource;

  LinkedInRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, LinkedInAccount>> connectLinkedIn(
      String linkedinAccessToken) async {
    try {
      final account =
          await remoteDataSource.connectLinkedIn(linkedinAccessToken);
      return Right(account);
    } on AppException catch (e) {
      return Left(_mapExceptionToFailure(e));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> disconnectLinkedIn() async {
    try {
      await remoteDataSource.disconnectLinkedIn();
      return const Right(null);
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
