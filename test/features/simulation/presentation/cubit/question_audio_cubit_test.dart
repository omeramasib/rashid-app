import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rashed_app/core/error/failures.dart';
import 'package:rashed_app/features/simulation/domain/entities/interview_question.dart';
import 'package:rashed_app/features/simulation/domain/entities/question_audio.dart';
import 'package:rashed_app/features/simulation/domain/usecases/get_question_audio_usecase.dart';
import 'package:rashed_app/features/simulation/presentation/cubit/question_audio_cubit.dart';

import '../../../../helpers/fake_question_audio.dart';
import '../../../../helpers/fake_speech.dart';

void main() {
  const first = InterviewQuestion(
    id: 'q-1',
    questionText: 'Tell me about yourself.',
    position: 1,
  );
  const second = InterviewQuestion(
    id: 'q-2',
    questionText: 'How do you handle feedback?',
    position: 2,
  );

  Future<void> tick() => Future<void>.delayed(Duration.zero);

  QuestionAudioCubit build({
    required ScriptedQuestionAudioApi api,
    required FakeQuestionAudioPlayer player,
    RecordingQuestionAudioTelemetry? telemetry,
  }) {
    return QuestionAudioCubit(
      getQuestionAudio: api,
      player: player,
      telemetry: telemetry,
    );
  }

  test('prepares a file and plays, pauses, and replays it', () async {
    final api = ScriptedQuestionAudioApi(
      (params) async => Right(readyQuestionAudio(params.question.id)),
    );
    final player = FakeQuestionAudioPlayer();
    final cubit = build(api: api, player: player);
    addTearDown(cubit.close);

    cubit.showQuestion(first, deferUntilPlay: false);
    await tick();
    expect(cubit.state.playback, QuestionPlaybackStatus.ready);
    expect(player.loads, ['/tmp/q-1.wav']);
    expect(player.playCalls, 0);

    await cubit.play();
    expect(cubit.state.playback, QuestionPlaybackStatus.playing);
    await cubit.pause();
    expect(cubit.state.playback, QuestionPlaybackStatus.paused);
    await cubit.resume();
    expect(player.playCalls, 2);
    await cubit.replay();
    expect(player.seekCalls, 1);
    expect(api.calls, ['q-1']);
  });

  test('a playback failure evicts the file and does not download again',
      () async {
    final api = ScriptedQuestionAudioApi(
      (params) async => Right(readyQuestionAudio(params.question.id)),
    );
    final player = FakeQuestionAudioPlayer()..failLoads = 1;
    final cubit = build(api: api, player: player);
    addTearDown(cubit.close);

    cubit.showQuestion(first, deferUntilPlay: false);
    await tick();

    expect(cubit.state.playback, QuestionPlaybackStatus.error);
    expect(api.calls, ['q-1']);
    expect(api.evicted, ['q-1']);
    expect(player.playCalls, 0);
  });

  test('a temporary outage waits for a manual retry', () {
    fakeAsync((async) {
      final api = ScriptedQuestionAudioApi(
        (_) async => const Left(
          ServiceUnavailableFailure(
              'Question audio is temporarily unavailable'),
        ),
      );
      final cubit = build(api: api, player: FakeQuestionAudioPlayer());
      cubit.showQuestion(first, deferUntilPlay: false);
      async.flushMicrotasks();
      async.elapse(const Duration(seconds: 30));

      expect(api.calls, ['q-1']);
      expect(cubit.state.issue, QuestionAudioIssue.temporary);
      cubit.retry();
      async.flushMicrotasks();
      expect(api.calls, ['q-1', 'q-1']);
      cubit.close();
      async.flushMicrotasks();
    });
  });

  test('a 429 is not retried until Retry-After elapses', () {
    fakeAsync((async) {
      final api = ScriptedQuestionAudioApi(
        (_) async => const Left(
          RateLimitFailure(
            'AI spending limit reached',
            code: 'spending_limit',
            retryAfter: Duration(seconds: 5),
          ),
        ),
      );
      final cubit = build(
        api: api,
        player: FakeQuestionAudioPlayer(),
        telemetry: RecordingQuestionAudioTelemetry(),
      );
      cubit.showQuestion(first, deferUntilPlay: false);
      async.flushMicrotasks();

      expect(cubit.state.issue, QuestionAudioIssue.limited);
      expect(cubit.state.retryLocked, isTrue);
      cubit.retry();
      async.elapse(const Duration(seconds: 4));
      async.flushMicrotasks();
      expect(api.calls, ['q-1']);

      async.elapse(const Duration(seconds: 1));
      expect(cubit.state.retryLocked, isFalse);
      cubit.retry();
      async.flushMicrotasks();
      expect(api.calls, ['q-1', 'q-1']);
      cubit.close();
      async.flushMicrotasks();
    });
  });

  test('an unrecoverable 401 is not stored as an audio failure', () async {
    final api = ScriptedQuestionAudioApi(
      (_) async =>
          const Left(UnauthorizedFailure('Could not validate credentials')),
    );
    final cubit = build(api: api, player: FakeQuestionAudioPlayer());
    addTearDown(cubit.close);

    cubit.showQuestion(first, deferUntilPlay: false);
    await tick();
    cubit.retry();
    await tick();

    expect(cubit.state.issue, QuestionAudioIssue.sessionExpired);
    expect(api.calls, ['q-1']);
  });

  test('ignores a stale response and does not play the previous question',
      () async {
    final firstResponse = Completer<Either<Failure, QuestionAudioFile>>();
    final secondResponse = Completer<Either<Failure, QuestionAudioFile>>();
    final api = ScriptedQuestionAudioApi(
      (params) => params.question.id == 'q-1'
          ? firstResponse.future
          : secondResponse.future,
    );
    final player = FakeQuestionAudioPlayer();
    final cubit = build(api: api, player: player);
    addTearDown(cubit.close);

    cubit.showQuestion(first, deferUntilPlay: false);
    cubit.showQuestion(second, deferUntilPlay: false);
    secondResponse.complete(Right(
      readyQuestionAudio('q-2', path: '/tmp/q-2.wav'),
    ));
    await tick();
    firstResponse.complete(Right(
      readyQuestionAudio('q-1', path: '/tmp/q-1.wav'),
    ));
    await tick();

    expect(cubit.state.questionId, 'q-2');
    expect(player.loads, ['/tmp/q-2.wav']);
    await cubit.play();
    expect(player.playCalls, 1);
    expect(api.cancels, 0);
  });

  test('recording does not block prefetch and does not prepare the next file',
      () async {
    final current = Completer<Either<Failure, QuestionAudioFile>>();
    final api = ScriptedQuestionAudioApi((params) async {
      if (params.question.id == 'q-1') return current.future;
      return Right(readyQuestionAudio('q-2', path: '/tmp/q-2.wav'));
    });
    final player = FakeQuestionAudioPlayer();
    final cubit = build(api: api, player: player);
    addTearDown(cubit.close);

    cubit.showQuestion(first, deferUntilPlay: false, next: second);
    await cubit.suspendForRecording();
    current.complete(Right(readyQuestionAudio('q-1')));
    await tick();
    await tick();

    expect(player.loads, isEmpty);
    expect(player.playCalls, 0);
    expect(api.prefetches, ['q-2']);
    cubit.recordingEnded();
    await tick();
    expect(player.loads, ['/tmp/q-1.wav']);
    expect(player.playCalls, 0);
  });

  test('a prefetched question is requested again with the prefetch source',
      () async {
    final api = ScriptedQuestionAudioApi((params) async {
      return Right(readyQuestionAudio(
        params.question.id,
        source: params.question.id == 'q-2'
            ? QuestionAudioSource.prefetch
            : QuestionAudioSource.cold,
      ));
    });
    final telemetry = RecordingQuestionAudioTelemetry();
    final player = FakeQuestionAudioPlayer();
    final cubit = build(api: api, player: player, telemetry: telemetry);
    addTearDown(cubit.close);

    cubit.showQuestion(first, deferUntilPlay: false, next: second);
    await tick();
    await tick();
    expect(api.prefetches, ['q-2']);
    expect(telemetry.lastSource, QuestionAudioSource.cold);
    expect(telemetry.open, 0);

    cubit.showQuestion(second, deferUntilPlay: false);
    await tick();
    expect(player.loads, ['/tmp/q-1.wav', '/tmp/q-2.wav']);
    expect(telemetry.lastSource, QuestionAudioSource.prefetch);
    expect(telemetry.events, [
      'begin',
      'ready:cold',
      'begin',
      'ready:prefetch',
    ]);
  });

  test('telemetry failure does not stop playback preparation', () async {
    final telemetry = RecordingQuestionAudioTelemetry()..throwOnReady = true;
    final api = ScriptedQuestionAudioApi(
      (params) async => Right(readyQuestionAudio(params.question.id)),
    );
    final player = FakeQuestionAudioPlayer();
    final cubit = build(api: api, player: player, telemetry: telemetry);
    addTearDown(cubit.close);

    cubit.showQuestion(first, deferUntilPlay: false);
    await tick();

    expect(cubit.state.playback, QuestionPlaybackStatus.ready);
    expect(player.loads, ['/tmp/q-1.wav']);
  });

  test('an answered question waits for play before requesting audio', () async {
    final api = ScriptedQuestionAudioApi(
      (params) async => Right(readyQuestionAudio(params.question.id)),
    );
    final player = FakeQuestionAudioPlayer();
    final cubit = build(api: api, player: player);
    addTearDown(cubit.close);

    cubit.showQuestion(first, deferUntilPlay: true);
    await tick();
    expect(api.calls, isEmpty);

    await cubit.play();
    await tick();
    expect(api.calls, ['q-1']);
    expect(player.playCalls, 1);
  });

  test('recording blocks playback and playback can resume after it', () async {
    final api = ScriptedQuestionAudioApi(
      (params) async => Right(readyQuestionAudio(params.question.id)),
    );
    final player = FakeQuestionAudioPlayer();
    final cubit = build(api: api, player: player);
    addTearDown(cubit.close);

    cubit.showQuestion(first, deferUntilPlay: false);
    await tick();
    await cubit.play();
    await cubit.suspendForRecording();
    await cubit.play();
    expect(player.playCalls, 1);

    cubit.recordingEnded();
    await cubit.resume();
    expect(player.playCalls, 2);
    expect(player.loads, ['/tmp/q-1.wav']);
  });

  test('backgrounding pauses playback', () async {
    final foreground = FakeForeground();
    final api = ScriptedQuestionAudioApi(
      (params) async => Right(readyQuestionAudio(params.question.id)),
    );
    final player = FakeQuestionAudioPlayer();
    final cubit = QuestionAudioCubit(
      getQuestionAudio: api,
      player: player,
      foreground: foreground,
    );
    addTearDown(cubit.close);

    cubit.showQuestion(first, deferUntilPlay: false);
    await tick();
    await cubit.play();
    foreground.setResumed(false);
    await tick();

    expect(player.pauseCalls, 1);
    expect(cubit.state.playback, QuestionPlaybackStatus.paused);
  });

  test('does not start playback that was loading when the question changes',
      () async {
    final api = ScriptedQuestionAudioApi(
      (params) async => Right(readyQuestionAudio(params.question.id)),
    );
    final player = FakeQuestionAudioPlayer();
    final cubit = build(api: api, player: player);
    addTearDown(cubit.close);

    player.loadGate = Completer<void>();
    cubit.showQuestion(first, deferUntilPlay: false);
    await tick();
    cubit.showQuestion(second, deferUntilPlay: false);
    player.loadGate!.complete();
    await tick();
    await tick();

    expect(cubit.state.questionId, 'q-2');
    expect(player.playCalls, 0);
    expect(player.loads, contains('/tmp/q-2.wav'));
  });

  test('close disposes the player and discards cached audio', () async {
    final api = ScriptedQuestionAudioApi(
      (params) async => Right(readyQuestionAudio(params.question.id)),
    );
    final player = FakeQuestionAudioPlayer();
    final cubit = build(api: api, player: player);
    cubit.showQuestion(first, deferUntilPlay: false);
    await tick();
    await cubit.close();

    expect(player.disposed, isTrue);
    expect(api.discards, 1);
  });

  test('disabled speech makes no request', () async {
    final api = ScriptedQuestionAudioApi(
      (params) async => Right(readyQuestionAudio(params.question.id)),
    );
    final cubit = build(api: api, player: FakeQuestionAudioPlayer());
    addTearDown(cubit.close);

    cubit.showQuestion(
      const InterviewQuestion(
        id: 'q-off',
        questionText: 'Text only',
        audio: QuestionAudioHint(status: QuestionAudioStatus.disabled),
      ),
      deferUntilPlay: false,
    );
    await tick();

    expect(api.calls, isEmpty);
    expect(cubit.state.backend, QuestionAudioStatus.disabled);
  });
}
