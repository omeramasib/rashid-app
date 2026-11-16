import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/answer_evaluation.dart';
import '../../domain/entities/interview_finish_result.dart';
import '../../domain/entities/interview_report.dart';
import '../../domain/entities/interview_simulation_history.dart';
import '../../domain/entities/interview_start_response.dart';
import '../../domain/entities/interview_question.dart';
import '../../domain/entities/question_audio.dart';
import '../../domain/entities/simulation_history_count.dart';
import '../../domain/failures/interview_start_failure.dart';
import '../../domain/repositories/interview_repository.dart';
import '../datasources/interview_remote_datasource.dart';
import '../datasources/question_audio_cache.dart';

class InterviewRepositoryImpl implements InterviewRepository {
  final InterviewRemoteDataSource remoteDataSource;
  final QuestionAudioCache audioCache;

  final Map<String, Future<QuestionAudioFile>> _inFlight = {};
  final Map<String, QuestionAudioSource> _origin = {};
  final Map<String, _AudioStats> _stats = {};

  InterviewRepositoryImpl({
    required this.remoteDataSource,
    required this.audioCache,
  });

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
  Future<Either<Failure, QuestionAudioFile>> getQuestionAudio(
    InterviewQuestion question, {
    bool prefetch = false,
  }) async {
    final name = _nameFor(question);
    final running = _inFlight[name];
    if (running != null) return _join(running);
    final cached = await _cached(question, name);
    if (cached != null) return Right(cached);
    final started = _inFlight[name];
    if (started != null) return _join(started);
    final future = _download(question, name, prefetch: prefetch);
    _inFlight[name] = future;
    try {
      return await _join(future);
    } finally {
      if (identical(_inFlight[name], future)) _inFlight.remove(name);
    }
  }

  @override
  Future<void> evictQuestionAudio(InterviewQuestion question) async {
    final name = _nameFor(question);
    _origin.remove(name);
    _stats.remove(name);
    await audioCache.evict(name);
  }

  @override
  void cancelQuestionAudio() => remoteDataSource.cancelQuestionAudio();

  @override
  Future<void> endQuestionAudio() async {
    cancelQuestionAudio();
    _inFlight.clear();
    _origin.clear();
    _stats.clear();
    await audioCache.clear();
  }

  String _nameFor(InterviewQuestion question) {
    return audioCache.fileName(
      questionId: question.id,
      questionText: question.questionText,
    );
  }

  Future<QuestionAudioFile?> _cached(
    InterviewQuestion question,
    String name,
  ) async {
    final path = await audioCache.validPath(name);
    if (path == null) return null;
    final origin = _origin[name];
    final stats = _stats[name];
    final prefetched = origin == QuestionAudioSource.prefetch;
    if (prefetched) _origin[name] = QuestionAudioSource.cache;
    return QuestionAudioFile(
      questionId: question.id,
      filePath: path,
      bytes: stats?.bytes ?? 0,
      source:
          prefetched ? QuestionAudioSource.prefetch : QuestionAudioSource.cache,
      httpMs: prefetched ? (stats?.httpMs ?? 0) : 0,
      cacheWriteMs: prefetched ? (stats?.cacheWriteMs ?? 0) : 0,
    );
  }

  Future<QuestionAudioFile> _download(
    InterviewQuestion question,
    String name, {
    required bool prefetch,
  }) async {
    final watch = Stopwatch()..start();
    final bytes = await remoteDataSource.downloadQuestionAudio(question.id);
    final httpMs = watch.elapsedMilliseconds;
    final cacheWriteMs = await audioCache.write(name, bytes);
    final path = await audioCache.validPath(name);
    if (path == null) throw CacheException('Invalid question audio');
    final source =
        prefetch ? QuestionAudioSource.prefetch : QuestionAudioSource.cold;
    _origin[name] = source;
    _stats[name] = _AudioStats(
      httpMs: httpMs,
      cacheWriteMs: cacheWriteMs,
      bytes: bytes.length,
    );
    return QuestionAudioFile(
      questionId: question.id,
      filePath: path,
      bytes: bytes.length,
      source: source,
      httpMs: httpMs,
      cacheWriteMs: cacheWriteMs,
    );
  }

  Future<Either<Failure, QuestionAudioFile>> _join(
    Future<QuestionAudioFile> future,
  ) async {
    try {
      return Right(await future);
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
    if (error is RateLimitException) {
      return RateLimitFailure(
        error.message,
        code: error.code,
        retryAfter: error.retryAfter,
      );
    }
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
    if (error is CacheException) return CacheFailure(error.message);
    return ServerFailure(error.message);
  }
}

class _AudioStats {
  const _AudioStats({
    required this.httpMs,
    required this.cacheWriteMs,
    required this.bytes,
  });

  final int httpMs;
  final int cacheWriteMs;
  final int bytes;
}
