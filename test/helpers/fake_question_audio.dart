import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:rashed_app/core/audio/question_audio_player.dart';
import 'package:rashed_app/core/audio/question_audio_telemetry.dart';
import 'package:rashed_app/core/error/failures.dart';
import 'package:rashed_app/features/simulation/domain/entities/interview_question.dart';
import 'package:rashed_app/features/simulation/domain/entities/question_audio.dart';
import 'package:rashed_app/features/simulation/domain/repositories/interview_repository.dart';
import 'package:rashed_app/features/simulation/domain/usecases/get_question_audio_usecase.dart';
import 'package:rashed_app/features/simulation/presentation/cubit/question_audio_cubit.dart';

class ScriptedQuestionAudioApi implements GetQuestionAudioUseCase {
  ScriptedQuestionAudioApi(this.handler);

  final Future<Either<Failure, QuestionAudioFile>> Function(
    GetQuestionAudioParams params,
  ) handler;
  final calls = <String>[];
  final prefetches = <String>[];
  final evicted = <String>[];
  int cancels = 0;
  int discards = 0;

  @override
  InterviewRepository get repository => throw UnimplementedError();

  @override
  Future<Either<Failure, QuestionAudioFile>> call(
    GetQuestionAudioParams params,
  ) {
    calls.add(params.question.id);
    if (params.prefetch) prefetches.add(params.question.id);
    return handler(params);
  }

  @override
  Future<void> evict(InterviewQuestion question) async {
    evicted.add(question.id);
  }

  @override
  void cancel() => cancels++;

  @override
  Future<void> discard() async {
    discards++;
    cancel();
  }
}

class FakeQuestionAudioPlayer implements QuestionAudioPlayer {
  final loads = <String>[];
  int playCalls = 0;
  int pauseCalls = 0;
  int suspendCalls = 0;
  int stopCalls = 0;
  int seekCalls = 0;
  int failLoads = 0;
  bool disposed = false;
  Completer<void>? loadGate;
  final _signals = StreamController<QuestionAudioPlayerSignal>.broadcast();

  @override
  Stream<QuestionAudioPlayerSignal> get signals => _signals.stream;

  void emit(QuestionAudioPlayerSignal signal) => _signals.add(signal);

  @override
  Future<void> load(String filePath) async {
    final gate = loadGate;
    if (gate != null) await gate.future;
    if (failLoads > 0) {
      failLoads--;
      throw StateError('unplayable');
    }
    loads.add(filePath);
  }

  @override
  Future<void> play({required bool Function() stillCurrent}) async {
    if (!stillCurrent()) return;
    playCalls++;
    _signals.add(QuestionAudioPlayerSignal.started);
  }

  @override
  Future<void> pause() async {
    pauseCalls++;
    _signals.add(QuestionAudioPlayerSignal.paused);
  }

  @override
  Future<void> suspendForCapture() async {
    suspendCalls++;
  }

  @override
  Future<void> stop() async {
    stopCalls++;
  }

  @override
  Future<void> seekToStart() async {
    seekCalls++;
  }

  @override
  Future<void> dispose() async {
    disposed = true;
    await _signals.close();
  }
}

class RecordingQuestionAudioTelemetry implements QuestionAudioTelemetry {
  final events = <String>[];
  int open = 0;
  QuestionAudioSource? lastSource;
  int? lastHttpMs;
  int? lastPrepareMs;
  int? lastBytes;
  int? lastReadyMs;
  bool throwOnReady = false;

  @override
  void activationStarted() {
    open++;
    events.add('begin');
  }

  @override
  void ready({
    required QuestionAudioSource source,
    required int timeToReadyMs,
    required int httpMs,
    required int cacheWriteMs,
    required int prepareMs,
    required int bytes,
  }) {
    if (throwOnReady) throw StateError('telemetry down');
    open--;
    lastSource = source;
    lastHttpMs = httpMs;
    lastPrepareMs = prepareMs;
    lastBytes = bytes;
    lastReadyMs = timeToReadyMs;
    events.add('ready:${source.name}');
  }

  @override
  void failed({required String category, required int elapsedMs}) {
    open--;
    events.add('failed:$category');
  }

  @override
  void cancelled({required int elapsedMs}) {
    open--;
    events.add('cancelled');
  }
}

QuestionAudioFile readyQuestionAudio(
  String questionId, {
  QuestionAudioSource source = QuestionAudioSource.cold,
  String? path,
  int httpMs = 40,
  int bytes = 128,
}) {
  return QuestionAudioFile(
    questionId: questionId,
    filePath: path ?? '/tmp/$questionId.wav',
    bytes: bytes,
    source: source,
    httpMs: httpMs,
    cacheWriteMs: source == QuestionAudioSource.cache ? 0 : 5,
  );
}

/// Resolves immediately so existing screens can render without a download.
QuestionAudioCubit idleQuestionAudioCubit() {
  return QuestionAudioCubit(
    getQuestionAudio: ScriptedQuestionAudioApi(
      (params) async => Right(readyQuestionAudio(params.question.id)),
    ),
    player: FakeQuestionAudioPlayer(),
  );
}
