import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/answer_evaluation.dart';
import '../../domain/entities/interview_finish_result.dart';
import '../../domain/entities/interview_report.dart';
import '../../domain/entities/interview_simulation_history.dart';
import '../../domain/entities/interview_start_response.dart';
import '../../domain/entities/simulation_history_count.dart';
import '../../domain/failures/interview_start_failure.dart';
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
    String? cvId,
  }) {
    return _start(() => remoteDataSource.startByJob(
          jobField: jobField,
          interviewType: interviewType,
          difficulty: difficulty,
          language: language,
          simulationType: simulationType,
          numQuestions: numQuestions,
          cvId: cvId,
        ));
  }

  @override
  Future<Either<Failure, InterviewStartResponse>> startByJobDescription({
    required String jobDescription,
    required String interviewType,
    required String difficulty,
    required String language,
    required String simulationType,
    required int numQuestions,
    String? cvId,
  }) {
    return _start(() => remoteDataSource.startByJobDescription(
          jobDescription: jobDescription,
          interviewType: interviewType,
          difficulty: difficulty,
          language: language,
          simulationType: simulationType,
          numQuestions: numQuestions,
          cvId: cvId,
        ));
  }

  @override
  Future<Either<Failure, InterviewStartResponse>> retryGeneration(
    String simulationId,
  ) {
    return _start(() => remoteDataSource.retryGeneration(simulationId));
  }

  Future<Either<Failure, InterviewStartResponse>> _start(
    Future<InterviewStartResponse> Function() call,
  ) async {
    try {
      return Right(await call());
    } on InterviewStartException catch (error) {
      return Left(InterviewStartFailure(
        _mapExceptionToFailure(error.cause),
        simulationId: error.simulationId,
      ));
    } on AppException catch (error) {
      return Left(_mapExceptionToFailure(error));
    } catch (error) {
      return Left(ServerFailure(error.toString()));
    }
  }

  @override
  Future<Either<Failure, AnswerEvaluation>> submitAnswer({
    required String questionId,
    required bool skipped,
    String? answerText,
  }) async {
    try {
      final response = await remoteDataSource.submitAnswer(
        questionId: questionId,
        skipped: skipped,
        answerText: answerText,
      );
      return Right(response);
    } on AppException catch (error) {
      return Left(_mapExceptionToFailure(error));
    } catch (error) {
      return Left(ServerFailure(error.toString()));
    }
  }

  @override
  Future<Either<Failure, InterviewFinishResult>> finishInterview(
    String simulationId,
  ) async {
    try {
      final response = await remoteDataSource.finishInterview(simulationId);
      return Right(response);
    } on AppException catch (error) {
      return Left(_mapExceptionToFailure(error));
    } catch (error) {
      return Left(ServerFailure(error.toString()));
    }
  }

  @override
  Future<Either<Failure, InterviewReport>> getReport(
    String simulationId,
  ) async {
    try {
      final response = await remoteDataSource.getReport(simulationId);
      return Right(response);
    } on AppException catch (error) {
      return Left(_mapExceptionToFailure(error));
    } catch (error) {
      return Left(ServerFailure(error.toString()));
    }
  }

  @override
  Future<Either<Failure, SimulationHistoryCount>>
      getSimulationHistoryCount() async {
    try {
      final response = await remoteDataSource.getSimulationHistoryCount();
      return Right(response);
    } on AppException catch (error) {
      return Left(_mapExceptionToFailure(error));
    } catch (error) {
      return Left(ServerFailure(error.toString()));
    }
  }

  @override
  Future<Either<Failure, List<InterviewSimulationHistory>>>
      getSimulationsHistory() async {
    try {
      final response = await remoteDataSource.getSimulationsHistory();
      return Right(response);
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
