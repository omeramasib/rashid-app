import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';

import 'question_audio_player.dart';

/// Remote WAV playback through [just_audio].
///
/// [play] returns when playback has started. Completion is a signal.
class JustAudioQuestionEngine implements QuestionAudioEngine {
  JustAudioQuestionEngine({AudioPlayer? player})
      : _player = player ?? AudioPlayer() {
    _stateSubscription = _player.playerStateStream.listen(
      _onState,
      onError: (Object _, StackTrace __) =>
          _add(QuestionAudioPlayerSignal.failed),
    );
  }

  final AudioPlayer _player;
  final _signals = StreamController<QuestionAudioPlayerSignal>.broadcast();
  StreamSubscription<PlayerState>? _stateSubscription;

  @override
  Stream<QuestionAudioPlayerSignal> get signals => _signals.stream;

  @override
  Future<void> load(String url) async {
    await _player.setUrl(url);
  }

  @override
  Future<void> play() async {
    final started = _player.play();
    unawaited(started.then(
      (_) {},
      onError: (Object _, StackTrace __) =>
          _add(QuestionAudioPlayerSignal.failed),
    ));
  }

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() => _player.stop();

  @override
  Future<void> seekToStart() => _player.seek(Duration.zero);

  @override
  Future<void> dispose() async {
    await _stateSubscription?.cancel();
    _stateSubscription = null;
    await _player.dispose();
    if (!_signals.isClosed) await _signals.close();
  }

  void _onState(PlayerState state) {
    if (state.processingState == ProcessingState.completed) {
      _add(QuestionAudioPlayerSignal.completed);
      return;
    }
    if (state.playing) {
      _add(QuestionAudioPlayerSignal.started);
      return;
    }
    if (state.processingState == ProcessingState.ready) {
      _add(QuestionAudioPlayerSignal.paused);
    }
  }

  void _add(QuestionAudioPlayerSignal signal) {
    if (_signals.isClosed) return;
    _signals.add(signal);
  }
}

/// Restores a speech playback session after `speech_to_text` has used the mic.
class PluginInterviewAudioSession implements InterviewAudioSession {
  AudioSession? _session;

  @override
  Future<void> activateForPlayback() async {
    final session = _session ??= await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.speech());
    await session.setActive(true);
  }

  @override
  Future<void> releaseForCapture() async {
    final session = _session;
    if (session == null) return;
    try {
      await session.setActive(false);
    } catch (_) {}
  }
}
