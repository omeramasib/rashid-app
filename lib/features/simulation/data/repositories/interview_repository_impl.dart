import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/interview_start_response.dart';
import '../../domain/entities/interview_report.dart';
import '../../domain/entities/interview_simulation_history.dart';
import '../../domain/repositories/interview_repository.dart';
import '../datasources/interview_remote_datasource.dart';

class InterviewRepositoryImpl implements InterviewRepository {
  final InterviewRemoteDataSource remoteDataSource;

  InterviewRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, InterviewStartResponse>> startByJob({
    required String jobField,
    required String interviewType,
    required String difficulty,
    required String language,
    required String simulationType,
    required int numQuestions,
  }) async {
    try {
      final response = await remoteDataSource.startByJob(
        jobField: jobField,
        interviewType: interviewType,
        difficulty: difficulty,
        language: language,
        simulationType: simulationType,
        numQuestions: numQuestions,
      );
      return Right(response);
    } on AppException catch (e) {
      return Left(_mapExceptionToFailure(e));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, InterviewStartResponse>> startByJobDescription({
    required String jobDescription,
    required String interviewType,
    required String difficulty,
    required String language,
    required String simulationType,
    required int numQuestions,
  }) async {
    try {
      final response = await remoteDataSource.startByJobDescription(
        jobDescription: jobDescription,
        interviewType: interviewType,
        difficulty: difficulty,
        language: language,
        simulationType: simulationType,
        numQuestions: numQuestions,
      );
      return Right(response);
    } on AppException catch (e) {
      return Left(_mapExceptionToFailure(e));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> submitAnswer({
    required String questionId,
    required bool skipped,
    String? answerText,
  }) async {
    try {
      await remoteDataSource.submitAnswer(
        questionId: questionId,
        skipped: skipped,
        answerText: answerText,
      );
      return const Right(null);
    } on AppException catch (e) {
      return Left(_mapExceptionToFailure(e));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> finishInterview(String simulationId) async {
    try {
      await remoteDataSource.finishInterview(simulationId);
      return const Right(null);
    } on AppException catch (e) {
      return Left(_mapExceptionToFailure(e));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, InterviewReport>> getReport(
      String simulationId) async {
    try {
      final response = await remoteDataSource.getReport(simulationId);
      return Right(response);
    } on AppException catch (e) {
      return Left(_mapExceptionToFailure(e));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<InterviewSimulationHistory>>>
      getSimulationsHistory() async {
    try {
      final response = await remoteDataSource.getSimulationsHistory();
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
