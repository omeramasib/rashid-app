import 'dart:async';

/// Playback notifications. The URL is never part of a signal.
enum QuestionAudioPlayerSignal { started, paused, completed, failed }

/// Remote question speech. One instance serves the active interview.
abstract class QuestionAudioPlayer {
  Stream<QuestionAudioPlayerSignal> get signals;

  Future<void> load(String filePath);

  /// Starts or resumes playback.
  ///
  /// [stillCurrent] is checked around session activation so a question change
  /// or microphone capture cannot be overwritten by this call.
  Future<void> play({required bool Function() stillCurrent});

  Future<void> pause();

  /// Pauses speech and releases the audio session for the microphone.
  Future<void> suspendForCapture();

  Future<void> stop();

  Future<void> seekToStart();

  Future<void> dispose();
}

/// Output device used for question speech.
abstract class QuestionAudioEngine {
  Stream<QuestionAudioPlayerSignal> get signals;

  Future<void> load(String filePath);

  Future<void> play();

  Future<void> pause();

  Future<void> stop();

  Future<void> seekToStart();

  Future<void> dispose();
}

/// Shared iOS/Android audio session used by playback and speech recognition.
abstract class InterviewAudioSession {
  Future<void> activateForPlayback();

  Future<void> releaseForCapture();
}

/// Plays question speech without letting a stale call reclaim the microphone.
///
/// Session changes are serialized. Speech recognition waits until playback has
/// released the session, and a playback call that lost the race does not
/// activate it again.
class CoordinatedQuestionAudioPlayer implements QuestionAudioPlayer {
  CoordinatedQuestionAudioPlayer({
    required QuestionAudioEngine engine,
    required InterviewAudioSession session,
  })  : _engine = engine,
        _session = session;

  final QuestionAudioEngine _engine;
  final InterviewAudioSession _session;
  Future<void> _chain = Future<void>.value();

  @override
  Stream<QuestionAudioPlayerSignal> get signals => _engine.signals;

  @override
  Future<void> load(String filePath) {
    return _lock(() => _engine.load(filePath));
  }

  @override
  Future<void> play({required bool Function() stillCurrent}) {
    return _lock(() async {
      if (!stillCurrent()) return;
      await _session.activateForPlayback();
      if (!stillCurrent()) return;
      await _engine.play();
      if (!stillCurrent()) await _engine.pause();
    });
  }

  @override
  Future<void> pause() {
    return _lock(() => _engine.pause());
  }

  @override
  Future<void> suspendForCapture() {
    return _lock(() async {
      try {
        await _engine.pause();
      } catch (_) {}
      await _session.releaseForCapture();
    });
  }

  @override
  Future<void> stop() {
    return _lock(() async {
      try {
        await _engine.stop();
      } catch (_) {}
      await _session.releaseForCapture();
    });
  }

  @override
  Future<void> seekToStart() {
    return _lock(() => _engine.seekToStart());
  }

  @override
  Future<void> dispose() {
    return _lock(() async {
      await _engine.dispose();
      await _session.releaseForCapture();
    });
  }

  Future<void> _lock(Future<void> Function() action) {
    final result = _chain.then((_) => action());
    _chain = result.then((_) {}, onError: (_) {});
    return result;
  }
}
