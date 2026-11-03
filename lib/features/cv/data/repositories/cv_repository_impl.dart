import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/cv.dart';
import '../../domain/entities/cv_analysis_result.dart';
import '../../domain/repositories/cv_repository.dart';
import '../datasources/cv_remote_datasource.dart';

class CvRepositoryImpl implements CvRepository {
  final CvRemoteDataSource remoteDataSource;
  CancelToken? _uploadToken;
  CancelToken? _analyzeToken;

  CvRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, Cv>> uploadCv({
    required Uint8List bytes,
    required String fileName,
    required void Function(int sent, int total) onProgress,
  }) async {
    final token = CancelToken();
    _uploadToken = token;
    try {
      final cv = await remoteDataSource.uploadCv(
        bytes: bytes,
        fileName: fileName,
        cancelToken: token,
        onProgress: onProgress,
      );
      return Right(cv);
    } on AppException catch (e) {
      return Left(_mapExceptionToFailure(e));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    } finally {
      if (identical(_uploadToken, token)) _uploadToken = null;
    }
  }

  @override
  void cancelUpload() {
    final token = _uploadToken;
    if (token != null && !token.isCancelled) {
      token.cancel('client');
    }
  }

  @override
  Future<Either<Failure, CvAnalysisResult>> analyzeCv(String cvId) async {
    final token = CancelToken();
    _analyzeToken = token;
    try {
      final result = await remoteDataSource.analyzeCv(
        cvId,
        cancelToken: token,
      );
      return Right(result);
    } on AppException catch (e) {
      return Left(_mapExceptionToFailure(e));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    } finally {
      if (identical(_analyzeToken, token)) _analyzeToken = null;
    }
  }

  @override
  void cancelAnalysis() {
    final token = _analyzeToken;
    if (token != null && !token.isCancelled) {
      token.cancel('client');
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
    if (e is RequestCancelledException) {
      return RequestCancelledFailure(e.message);
    }
    if (e is RequestTimeoutException) return RequestTimeoutFailure(e.message);
    if (e is UserNotFoundException) return UserNotFoundFailure(e.message);
    if (e is BadRequestException) return BadRequestFailure(e.message);
    if (e is UnauthorizedException) return UnauthorizedFailure(e.message);
    if (e is ForbiddenException) return ForbiddenFailure(e.message);
    if (e is NotFoundException) return NotFoundFailure(e.message);
    if (e is ConflictException) return ConflictFailure(e.message);
    if (e is PayloadTooLargeException) return PayloadTooLargeFailure(e.message);
    if (e is ValidationException) return ValidationFailure(e.message);
    if (e is RateLimitException) return RateLimitFailure(e.message);
    if (e is ServiceUnavailableException) {
      return ServiceUnavailableFailure(e.message);
    }
    if (e is GatewayTimeoutException) return GatewayTimeoutFailure(e.message);
    if (e is NetworkException) return NetworkFailure(e.message);
    if (e is UpstreamException) return UpstreamFailure(e.message);
    if (e is CacheException) return CacheFailure(e.message);
    return ServerFailure(e.message);
  }
}
