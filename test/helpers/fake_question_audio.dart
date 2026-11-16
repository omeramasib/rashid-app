import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:rashed_app/core/audio/question_audio_player.dart';
import 'package:rashed_app/core/error/failures.dart';
import 'package:rashed_app/features/simulation/domain/entities/question_audio.dart';
import 'package:rashed_app/features/simulation/domain/repositories/interview_repository.dart';
import 'package:rashed_app/features/simulation/domain/usecases/get_question_audio_usecase.dart';
import 'package:rashed_app/features/simulation/presentation/cubit/question_audio_cubit.dart';

class ScriptedQuestionAudioApi implements GetQuestionAudioUseCase {
  ScriptedQuestionAudioApi(this.handler);

  final Future<Either<Failure, QuestionAudio>> Function(String questionId)
      handler;
  final calls = <String>[];
  int cancels = 0;

  @override
  InterviewRepository get repository => throw UnimplementedError();

  @override
  Future<Either<Failure, QuestionAudio>> call(GetQuestionAudioParams params) {
    calls.add(params.questionId);
    return handler(params.questionId);
  }

  @override
  void cancel() => cancels++;
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
  Future<void> load(String url) async {
    final gate = loadGate;
    if (gate != null) await gate.future;
    if (failLoads > 0) {
      failLoads--;
      throw StateError('unplayable');
    }
    loads.add(url);
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

QuestionAudio readyQuestionAudio(
  String questionId, {
  String url = 'https://example.test/question.wav',
  int expiresInSeconds = 300,
}) {
  return QuestionAudio(
    questionId: questionId,
    status: QuestionAudioStatus.ready,
    audioUrl: url,
    mimeType: 'audio/wav',
    durationMs: 3280,
    expiresInSeconds: expiresInSeconds,
  );
}

QuestionAudio statusAudio(String questionId, QuestionAudioStatus status) {
  return QuestionAudio(questionId: questionId, status: status);
}

/// Resolves immediately so existing screens can render without polling.
QuestionAudioCubit idleQuestionAudioCubit() {
  return QuestionAudioCubit(
    getQuestionAudio: ScriptedQuestionAudioApi(
      (questionId) async => Right(readyQuestionAudio(questionId)),
    ),
    player: FakeQuestionAudioPlayer(),
  );
}
