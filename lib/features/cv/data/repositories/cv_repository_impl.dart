import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/cv.dart';
import '../../domain/entities/cv_analysis_result.dart';
import '../../domain/repositories/cv_repository.dart';
import '../datasources/cv_remote_datasource.dart';

class CvRepositoryImpl implements CvRepository {
  final CvRemoteDataSource remoteDataSource;

  CvRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, Cv>> uploadCv(String filePath, String fileName) async {
    try {
      final cv = await remoteDataSource.uploadCv(filePath, fileName);
      return Right(cv);
    } on AppException catch (e) {
      return Left(_mapExceptionToFailure(e));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, CvAnalysisResult>> analyzeCv(String cvId) async {
    try {
      final result = await remoteDataSource.analyzeCv(cvId);
      return Right(result);
    } on AppException catch (e) {
      return Left(_mapExceptionToFailure(e));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateSkills(List<String> skills) async {
    try {
      await remoteDataSource.updateSkills(skills);
      return const Right(null);
    } on AppException catch (e) {
      return Left(_mapExceptionToFailure(e));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteSkill(String skill) async {
    try {
      await remoteDataSource.deleteSkill(skill);
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
