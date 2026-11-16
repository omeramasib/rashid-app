import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rashed_app/core/error/failures.dart';
import 'package:rashed_app/features/simulation/domain/entities/interview_question.dart';
import 'package:rashed_app/features/simulation/domain/entities/question_audio.dart';
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

  test('polls with backoff and stops once audio is ready', () {
    fakeAsync((async) {
      var attempt = 0;
      final api = ScriptedQuestionAudioApi((id) async {
        attempt++;
        if (attempt == 1) {
          return Right(statusAudio(id, QuestionAudioStatus.pending));
        }
        if (attempt == 2) {
          return Right(statusAudio(id, QuestionAudioStatus.processing));
        }
        return Right(readyQuestionAudio(id));
      });
      final player = FakeQuestionAudioPlayer();
      final cubit = QuestionAudioCubit(
        getQuestionAudio: api,
        player: player,
        now: () =>
            DateTime.fromMillisecondsSinceEpoch(async.elapsed.inMilliseconds),
      );

      cubit.showQuestion(first, deferUntilPlay: false);
      async.flushMicrotasks();
      expect(cubit.state.backend, QuestionAudioStatus.pending);
      expect(api.calls, ['q-1']);

      async.elapse(const Duration(milliseconds: 999));
      async.flushMicrotasks();
      expect(api.calls, ['q-1']);

      async.elapse(const Duration(milliseconds: 1));
      async.flushMicrotasks();
      expect(cubit.state.backend, QuestionAudioStatus.processing);

      async.elapse(const Duration(seconds: 2));
      async.flushMicrotasks();
      expect(cubit.state.backend, QuestionAudioStatus.ready);
      expect(cubit.state.playback, QuestionPlaybackStatus.ready);
      expect(api.calls.length, 3);
      expect(cubit.state.props.join(), isNot(contains('question.wav')));

      async.elapse(const Duration(seconds: 30));
      expect(api.calls.length, 3);
      cubit.close();
      async.flushMicrotasks();
    });
  });

  test('stops automatic polling at the window and retry starts it again', () {
    fakeAsync((async) {
      final api = ScriptedQuestionAudioApi(
        (id) async => Right(statusAudio(id, QuestionAudioStatus.pending)),
      );
      final cubit = QuestionAudioCubit(
        getQuestionAudio: api,
        player: FakeQuestionAudioPlayer(),
        now: () =>
            DateTime.fromMillisecondsSinceEpoch(async.elapsed.inMilliseconds),
      );
      cubit.showQuestion(first, deferUntilPlay: false);
      async.flushMicrotasks();
      async.elapse(const Duration(seconds: 60));
      async.flushMicrotasks();

      expect(cubit.state.issue, QuestionAudioIssue.timedOut);
      expect(cubit.state.backend, QuestionAudioStatus.pending);
      final stalled = api.calls.length;
      expect(stalled, 11);

      async.elapse(const Duration(seconds: 30));
      expect(api.calls.length, stalled);

      cubit.retry();
      async.flushMicrotasks();
      expect(cubit.state.issue, QuestionAudioIssue.none);
      expect(api.calls.length, stalled + 1);
      cubit.close();
      async.flushMicrotasks();
    });
  });

  test('retries a temporary outage three times and then waits for the user',
      () {
    fakeAsync((async) {
      final api = ScriptedQuestionAudioApi(
        (_) async => const Left(
          ServiceUnavailableFailure(
            'Question audio is temporarily unavailable',
          ),
        ),
      );
      final cubit = QuestionAudioCubit(
        getQuestionAudio: api,
        player: FakeQuestionAudioPlayer(),
        now: () =>
            DateTime.fromMillisecondsSinceEpoch(async.elapsed.inMilliseconds),
      );
      cubit.showQuestion(first, deferUntilPlay: false);
      async.elapse(const Duration(seconds: 14));
      async.flushMicrotasks();

      expect(api.calls.length, 4);
      expect(cubit.state.issue, QuestionAudioIssue.temporary);
      expect(cubit.state.backend, isNot(QuestionAudioStatus.failed));

      async.elapse(const Duration(seconds: 20));
      expect(api.calls.length, 4);
      cubit.close();
      async.flushMicrotasks();
    });
  });

  test('an unrecoverable 401 is not stored as an audio failure', () {
    fakeAsync((async) {
      final api = ScriptedQuestionAudioApi(
        (_) async =>
            const Left(UnauthorizedFailure('Could not validate credentials')),
      );
      final cubit = QuestionAudioCubit(
        getQuestionAudio: api,
        player: FakeQuestionAudioPlayer(),
        now: () =>
            DateTime.fromMillisecondsSinceEpoch(async.elapsed.inMilliseconds),
      );
      cubit.showQuestion(first, deferUntilPlay: false);
      async.flushMicrotasks();

      expect(cubit.state.issue, QuestionAudioIssue.sessionExpired);
      expect(cubit.state.issue, isNot(QuestionAudioIssue.unavailable));
      expect(cubit.state.backend, isNot(QuestionAudioStatus.failed));

      cubit.retry();
      async.elapse(const Duration(seconds: 30));
      async.flushMicrotasks();
      expect(api.calls, ['q-1']);
      cubit.close();
      async.flushMicrotasks();
    });
  });

  test('a missing question stops polling', () {
    fakeAsync((async) {
      final api = ScriptedQuestionAudioApi(
        (_) async => const Left(NotFoundFailure('Question not found')),
      );
      final cubit = QuestionAudioCubit(
        getQuestionAudio: api,
        player: FakeQuestionAudioPlayer(),
        now: () =>
            DateTime.fromMillisecondsSinceEpoch(async.elapsed.inMilliseconds),
      );
      cubit.showQuestion(first, deferUntilPlay: false);
      async.flushMicrotasks();
      async.elapse(const Duration(seconds: 10));
      expect(cubit.state.issue, QuestionAudioIssue.unavailable);
      expect(api.calls, ['q-1']);
      cubit.close();
      async.flushMicrotasks();
    });
  });

  test('ignores a stale response and does not play the previous question',
      () async {
    final firstResponse = Completer<Either<Failure, QuestionAudio>>();
    final secondResponse = Completer<Either<Failure, QuestionAudio>>();
    final api = ScriptedQuestionAudioApi(
      (id) => id == 'q-1' ? firstResponse.future : secondResponse.future,
    );
    final player = FakeQuestionAudioPlayer();
    final cubit = QuestionAudioCubit(
      getQuestionAudio: api,
      player: player,
    );
    addTearDown(cubit.close);

    cubit.showQuestion(first, deferUntilPlay: false);
    cubit.showQuestion(second, deferUntilPlay: false);
    secondResponse.complete(Right(
      readyQuestionAudio('q-2', url: 'https://example.test/second.wav'),
    ));
    await tick();
    firstResponse.complete(Right(
      readyQuestionAudio('q-1', url: 'https://example.test/first.wav'),
    ));
    await tick();

    expect(cubit.state.questionId, 'q-2');
    expect(cubit.state.backend, QuestionAudioStatus.ready);
    await cubit.play();
    await tick();
    expect(player.loads, ['https://example.test/second.wav']);
    expect(player.playCalls, 1);
    expect(api.cancels, greaterThan(0));
  });

  test('a second show of the same question does not send another request',
      () async {
    final api = ScriptedQuestionAudioApi(
      (id) async => Right(readyQuestionAudio(id)),
    );
    final cubit = QuestionAudioCubit(
      getQuestionAudio: api,
      player: FakeQuestionAudioPlayer(),
    );
    addTearDown(cubit.close);

    cubit.showQuestion(first, deferUntilPlay: false);
    cubit.showQuestion(first, deferUntilPlay: false);
    await tick();
    expect(api.calls, ['q-1']);
  });

  test('an answered question waits for play before requesting audio', () async {
    final api = ScriptedQuestionAudioApi(
      (id) async => Right(readyQuestionAudio(id)),
    );
    final player = FakeQuestionAudioPlayer();
    final cubit = QuestionAudioCubit(
      getQuestionAudio: api,
      player: player,
    );
    addTearDown(cubit.close);

    cubit.showQuestion(first, deferUntilPlay: true);
    await tick();
    expect(api.calls, isEmpty);
    expect(cubit.state.deferred, isTrue);

    await cubit.play();
    await tick();
    expect(api.calls, ['q-1']);
    expect(player.playCalls, 1);
  });

  test('refreshes an expired signed url before replay', () async {
    var clock = DateTime.utc(2026);
    var issued = 0;
    final api = ScriptedQuestionAudioApi((id) async {
      issued++;
      return Right(readyQuestionAudio(
        id,
        url: 'https://example.test/$issued.wav',
        expiresInSeconds: 300,
      ));
    });
    final player = FakeQuestionAudioPlayer();
    final cubit = QuestionAudioCubit(
      getQuestionAudio: api,
      player: player,
      now: () => clock,
    );
    addTearDown(cubit.close);

    cubit.showQuestion(first, deferUntilPlay: false);
    await tick();
    await cubit.play();
    await tick();
    expect(player.loads, ['https://example.test/1.wav']);

    clock = clock.add(const Duration(seconds: 271));
    await cubit.replay();
    await tick();
    expect(api.calls.length, 2);
    expect(player.loads, [
      'https://example.test/1.wav',
      'https://example.test/2.wav',
    ]);
    expect(player.seekCalls, 1);
  });

  test('reloads the url once when playback fails to start', () async {
    final api = ScriptedQuestionAudioApi(
      (id) async => Right(readyQuestionAudio(id)),
    );
    final player = FakeQuestionAudioPlayer()..failLoads = 1;
    final cubit = QuestionAudioCubit(
      getQuestionAudio: api,
      player: player,
    );
    addTearDown(cubit.close);

    cubit.showQuestion(first, deferUntilPlay: false);
    await tick();
    await cubit.play();
    await tick();

    expect(api.calls.length, 2);
    expect(player.loads, ['https://example.test/question.wav']);
    expect(player.playCalls, 1);
    expect(cubit.state.playback, QuestionPlaybackStatus.playing);
  });

  test('a second playback failure stays an error', () async {
    final api = ScriptedQuestionAudioApi(
      (id) async => Right(readyQuestionAudio(id)),
    );
    final player = FakeQuestionAudioPlayer()..failLoads = 5;
    final cubit = QuestionAudioCubit(
      getQuestionAudio: api,
      player: player,
    );
    addTearDown(cubit.close);

    cubit.showQuestion(first, deferUntilPlay: false);
    await tick();
    await cubit.play();
    await tick();

    expect(cubit.state.playback, QuestionPlaybackStatus.error);
    expect(api.calls.length, 2);
    expect(player.playCalls, 0);
  });

  test('recording blocks playback and playback can resume after it', () async {
    final api = ScriptedQuestionAudioApi(
      (id) async => Right(readyQuestionAudio(id)),
    );
    final player = FakeQuestionAudioPlayer();
    final cubit = QuestionAudioCubit(
      getQuestionAudio: api,
      player: player,
    );
    addTearDown(cubit.close);

    cubit.showQuestion(first, deferUntilPlay: false);
    await tick();
    await cubit.play();
    await tick();
    expect(player.playCalls, 1);

    await cubit.suspendForRecording();
    expect(player.suspendCalls, 1);
    expect(cubit.state.playback, QuestionPlaybackStatus.paused);

    await cubit.play();
    expect(player.playCalls, 1);

    cubit.recordingEnded();
    await cubit.resume();
    await tick();
    expect(player.playCalls, 2);
    expect(player.loads, ['https://example.test/question.wav']);
  });

  test('backgrounding pauses playback', () async {
    final foreground = FakeForeground();
    final api = ScriptedQuestionAudioApi(
      (id) async => Right(readyQuestionAudio(id)),
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
    await tick();
    foreground.setResumed(false);
    await tick();

    expect(player.pauseCalls, 1);
    expect(cubit.state.playback, QuestionPlaybackStatus.paused);
  });

  test('does not start playback that was loading when the question changes',
      () async {
    final api = ScriptedQuestionAudioApi(
      (id) async => Right(readyQuestionAudio(
        id,
        url: 'https://example.test/$id.wav',
      )),
    );
    final player = FakeQuestionAudioPlayer();
    final cubit = QuestionAudioCubit(
      getQuestionAudio: api,
      player: player,
    );
    addTearDown(cubit.close);

    cubit.showQuestion(first, deferUntilPlay: false);
    await tick();
    player.loadGate = Completer<void>();
    final playing = cubit.play();
    await tick();
    cubit.showQuestion(second, deferUntilPlay: false);
    player.loadGate!.complete();
    await playing;
    await tick();

    expect(cubit.state.questionId, 'q-2');
    expect(player.playCalls, 0);
  });

  test('close cancels polling and disposes the player', () {
    fakeAsync((async) {
      final api = ScriptedQuestionAudioApi(
        (id) async => Right(statusAudio(id, QuestionAudioStatus.pending)),
      );
      final player = FakeQuestionAudioPlayer();
      final cubit = QuestionAudioCubit(
        getQuestionAudio: api,
        player: player,
        now: () =>
            DateTime.fromMillisecondsSinceEpoch(async.elapsed.inMilliseconds),
      );
      cubit.showQuestion(first, deferUntilPlay: false);
      async.flushMicrotasks();
      final calls = api.calls.length;
      cubit.close();
      async.flushMicrotasks();
      async.elapse(const Duration(seconds: 30));

      expect(player.disposed, isTrue);
      expect(api.cancels, greaterThan(0));
      expect(api.calls.length, calls);
    });
  });

  test('disabled and failed hints do not request audio until retry', () async {
    final api = ScriptedQuestionAudioApi(
      (id) async => Right(readyQuestionAudio(id)),
    );
    final cubit = QuestionAudioCubit(
      getQuestionAudio: api,
      player: FakeQuestionAudioPlayer(),
    );
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

    cubit.showQuestion(
      const InterviewQuestion(
        id: 'q-bad',
        questionText: 'Still readable',
        audio: QuestionAudioHint(status: QuestionAudioStatus.failed),
      ),
      deferUntilPlay: false,
    );
    await tick();
    expect(api.calls, isEmpty);
    expect(cubit.state.issue, QuestionAudioIssue.unavailable);

    cubit.retry();
    await tick();
    expect(api.calls, ['q-bad']);
  });
}
