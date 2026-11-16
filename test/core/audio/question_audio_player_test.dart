import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:rashed_app/core/audio/question_audio_player.dart';

void main() {
  test('releases the session before speech and reactivates it to resume',
      () async {
    final log = <String>[];
    final engine = _FakeEngine(log);
    final session = _FakeSession(log);
    final player = CoordinatedQuestionAudioPlayer(
      engine: engine,
      session: session,
    );

    await player.suspendForCapture();
    await player.play(stillCurrent: () => true);

    expect(log, ['pause', 'release', 'activate', 'play']);
  });

  test('a play that loses the question does not start audio', () async {
    final log = <String>[];
    final session = _FakeSession(log);
    final engine = _FakeEngine(log);
    final player = CoordinatedQuestionAudioPlayer(
      engine: engine,
      session: session,
    );
    var current = true;
    session.activateGate = Completer<void>();

    final playing = player.play(stillCurrent: () => current);
    await Future<void>.delayed(Duration.zero);
    current = false;
    final suspending = player.suspendForCapture();
    session.activateGate!.complete();
    await playing;
    await suspending;

    expect(engine.playCalls, 0);
    expect(log, contains('activate'));
    expect(
      log.indexOf('activate'),
      lessThan(log.indexOf('release')),
    );
    expect(log, isNot(contains('play')));
  });
}

class _FakeEngine implements QuestionAudioEngine {
  _FakeEngine(this.log);

  final List<String> log;
  int playCalls = 0;

  @override
  Stream<QuestionAudioPlayerSignal> get signals => const Stream.empty();

  @override
  Future<void> load(String url) async {}

  @override
  Future<void> play() async {
    playCalls++;
    log.add('play');
  }

  @override
  Future<void> pause() async => log.add('pause');

  @override
  Future<void> stop() async => log.add('stop');

  @override
  Future<void> seekToStart() async {}

  @override
  Future<void> dispose() async {}
}

class _FakeSession implements InterviewAudioSession {
  _FakeSession(this.log);

  final List<String> log;
  Completer<void>? activateGate;

  @override
  Future<void> activateForPlayback() async {
    final gate = activateGate;
    activateGate = null;
    if (gate != null) await gate.future;
    log.add('activate');
  }

  @override
  Future<void> releaseForCapture() async => log.add('release');
}
