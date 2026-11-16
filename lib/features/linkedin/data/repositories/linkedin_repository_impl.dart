import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/linkedin_connection_status.dart';
import '../../domain/entities/linkedin_mark_deleted_result.dart';
import '../../domain/entities/linkedin_oauth_start.dart';
import '../../domain/entities/linkedin_publish_result.dart';
import '../../domain/entities/linkedin_share_preview.dart';
import '../../domain/repositories/linkedin_repository.dart';
import '../datasources/linkedin_remote_datasource.dart';

class LinkedInRepositoryImpl implements LinkedInRepository {
  final LinkedInRemoteDataSource remoteDataSource;

  LinkedInRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, LinkedInConnectionStatus>> getStatus() async {
    try {
      return Right(await remoteDataSource.getStatus());
    } on AppException catch (error) {
      return Left(_mapException(error));
    } catch (error) {
      return Left(ServerFailure(error.toString()));
    }
  }

  @override
  Future<Either<Failure, LinkedInOAuthStart>> startOAuth(
    String simulationId,
  ) async {
    try {
      return Right(await remoteDataSource.startOAuth(simulationId));
    } on AppException catch (error) {
      return Left(_mapException(error));
    } catch (error) {
      return Left(ServerFailure(error.toString()));
    }
  }

  @override
  Future<Either<Failure, LinkedInSharePreview>> previewShare(
    String simulationId,
  ) async {
    try {
      return Right(await remoteDataSource.previewShare(simulationId));
    } on AppException catch (error) {
      return Left(_mapException(error));
    } catch (error) {
      return Left(ServerFailure(error.toString()));
    }
  }

  @override
  Future<Either<Failure, LinkedInPublishResult>> publish({
    required String previewId,
    required String simulationId,
    required String contentSha256,
  }) async {
    try {
      return Right(await remoteDataSource.publish(
        previewId: previewId,
        simulationId: simulationId,
        contentSha256: contentSha256,
      ));
    } on AppException catch (error) {
      return Left(_mapException(error));
    } catch (error) {
      return Left(ServerFailure(error.toString()));
    }
  }

  @override
  Future<Either<Failure, LinkedInMarkDeletedResult>> markDeleted({
    required String shareId,
  }) async {
    try {
      return Right(await remoteDataSource.markDeleted(shareId: shareId));
    } on AppException catch (error) {
      return Left(_mapException(error));
    } catch (error) {
      return Left(ServerFailure(error.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> disconnect() async {
    try {
      await remoteDataSource.disconnect();
      return const Right(null);
    } on AppException catch (error) {
      return Left(_mapException(error));
    } catch (error) {
      return Left(ServerFailure(error.toString()));
    }
  }

  Failure _mapException(AppException error) {
    if (error is UserNotFoundException) {
      return UserNotFoundFailure(error.message);
    }
    if (error is BadRequestException) return BadRequestFailure(error.message);
    if (error is UnauthorizedException) {
      return UnauthorizedFailure(error.message);
    }
    if (error is ForbiddenException) return ForbiddenFailure(error.message);
    if (error is NotFoundException) return NotFoundFailure(error.message);
    if (error is ConflictException) {
      return ConflictFailure(
        error.message,
        code: error.code,
        postUrl: error.postUrl,
        shareId: error.shareId,
      );
    }
    if (error is ValidationException) return ValidationFailure(error.message);
    if (error is GoneException) return GoneFailure(error.message);
    if (error is NetworkException) return NetworkFailure(error.message);
    if (error is UpstreamException) return UpstreamFailure(error.message);
    if (error is ServiceUnavailableException) {
      return ServiceUnavailableFailure(error.message);
    }
    return ServerFailure(error.message);
  }
}
