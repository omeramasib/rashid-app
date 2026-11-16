import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/ads/app_foreground.dart';
import '../../../../core/audio/question_audio_player.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/interview_question.dart';
import '../../domain/entities/question_audio.dart';
import '../../domain/usecases/get_question_audio_usecase.dart';

part 'question_audio_state.dart';

/// Loads and plays speech for the one question on screen.
///
/// Interview progress and microphone capture stay in their own cubits.
/// A response is applied only when its question and request ticket are still
/// current, so navigating away cannot start the previous clip.
class QuestionAudioCubit extends Cubit<QuestionAudioState> {
  QuestionAudioCubit({
    required GetQuestionAudioUseCase getQuestionAudio,
    required QuestionAudioPlayer player,
    AppForegroundSignal? foreground,
    DateTime Function()? now,
  })  : _getQuestionAudio = getQuestionAudio,
        _player = player,
        _foreground = foreground ?? const AlwaysResumedForeground(),
        _now = now ?? DateTime.now,
        super(const QuestionAudioState()) {
    _foreground.addListener(_onForeground);
    _signals = _player.signals.listen(_onSignal);
  }

  static const pollWindow = Duration(seconds: 60);
  static const expiryMargin = Duration(seconds: 30);
  static const transientLimit = 3;
  static const pollDelays = <Duration>[
    Duration(seconds: 1),
    Duration(seconds: 2),
    Duration(seconds: 3),
    Duration(seconds: 5),
    Duration(seconds: 8),
  ];

  final GetQuestionAudioUseCase _getQuestionAudio;
  final QuestionAudioPlayer _player;
  final AppForegroundSignal _foreground;
  final DateTime Function() _now;

  late final StreamSubscription<QuestionAudioPlayerSignal> _signals;
  Timer? _timer;
  int _epoch = 0;
  int _ticket = 0;
  int _playbackEpoch = 0;
  int _armedPlayEpoch = -1;
  int _delayIndex = 0;
  int _transientAttempts = 0;
  bool _recording = false;
  bool _playWhenReady = false;
  bool _playbackRetried = false;
  bool _recovering = false;
  String? _questionId;
  String? _url;
  String? _loadedUrl;
  DateTime? _expiresAt;
  DateTime? _pollStarted;

  /// Shows [question]. Audio is requested immediately unless [deferUntilPlay].
  ///
  /// Answered questions defer so opening a review does not generate speech.
  void showQuestion(
    InterviewQuestion question, {
    required bool deferUntilPlay,
  }) {
    if (question.id.isEmpty || question.id == _questionId) return;
    _dropCurrent();
    _questionId = question.id;
    final hint = question.audio;
    if (hint?.status == QuestionAudioStatus.disabled) {
      _replace(QuestionAudioState(
        questionId: question.id,
        backend: QuestionAudioStatus.disabled,
      ));
      return;
    }
    if (deferUntilPlay) {
      final failed = hint?.status == QuestionAudioStatus.failed;
      _replace(QuestionAudioState(
        questionId: question.id,
        deferred: true,
        backend: failed ? QuestionAudioStatus.failed : null,
        issue:
            failed ? QuestionAudioIssue.unavailable : QuestionAudioIssue.none,
      ));
      return;
    }
    if (hint?.status == QuestionAudioStatus.failed) {
      _replace(QuestionAudioState(
        questionId: question.id,
        backend: QuestionAudioStatus.failed,
        issue: QuestionAudioIssue.unavailable,
      ));
      return;
    }
    _replace(QuestionAudioState(
      questionId: question.id,
      playback: QuestionPlaybackStatus.loading,
    ));
    _pollStarted = _now();
    unawaited(_fetch(_epoch));
  }

  Future<void> play() => _play(fromStart: false);

  Future<void> resume() => _play(fromStart: false);

  Future<void> replay() => _play(fromStart: true);

  /// Asks again after a timeout, a temporary outage, or a failed generation.
  void retry() {
    if (isClosed || _recording || _questionId == null) return;
    if (state.issue == QuestionAudioIssue.sessionExpired) return;
    if (state.backend == QuestionAudioStatus.disabled) return;
    final recoverable = state.issue == QuestionAudioIssue.timedOut ||
        state.issue == QuestionAudioIssue.temporary ||
        state.issue == QuestionAudioIssue.unavailable ||
        state.playback == QuestionPlaybackStatus.error ||
        state.backend == QuestionAudioStatus.failed;
    if (!recoverable) return;
    _timer?.cancel();
    _timer = null;
    _transientAttempts = 0;
    _delayIndex = 0;
    _playbackRetried = false;
    _playWhenReady = false;
    _url = null;
    _expiresAt = null;
    _loadedUrl = null;
    _pollStarted = _now();
    _replace(QuestionAudioState(
      questionId: _questionId,
      playback: QuestionPlaybackStatus.loading,
    ));
    unawaited(_fetch(_epoch));
  }

  Future<void> pause() async {
    if (isClosed) return;
    if (state.playback != QuestionPlaybackStatus.playing &&
        state.playback != QuestionPlaybackStatus.loading) {
      return;
    }
    _playbackEpoch++;
    _armedPlayEpoch = -1;
    await _player.pause();
    if (isClosed) return;
    _publish(playback: QuestionPlaybackStatus.paused);
  }

  /// Stops the clip and releases the session. Polling for this question stays.
  Future<void> stop() async {
    _playbackEpoch++;
    _armedPlayEpoch = -1;
    _playWhenReady = false;
    _loadedUrl = null;
    await _player.stop();
    if (isClosed) return;
    if (state.playback == QuestionPlaybackStatus.playing ||
        state.playback == QuestionPlaybackStatus.paused ||
        state.playback == QuestionPlaybackStatus.loading ||
        state.playback == QuestionPlaybackStatus.completed) {
      _publish(
        playback: state.backend == QuestionAudioStatus.ready
            ? QuestionPlaybackStatus.ready
            : QuestionPlaybackStatus.idle,
      );
    }
  }

  /// Stops speech immediately and keeps playback from starting until
  /// [recordingEnded]. The flag is set before the session is released so an
  /// in-flight play cannot take the microphone back.
  Future<void> suspendForRecording() async {
    if (_recording) return;
    _recording = true;
    _playbackEpoch++;
    _armedPlayEpoch = -1;
    _playWhenReady = false;
    final wasAudible = state.playback == QuestionPlaybackStatus.playing ||
        state.playback == QuestionPlaybackStatus.paused;
    await _player.suspendForCapture();
    if (isClosed) return;
    if (wasAudible) {
      _publish(playback: QuestionPlaybackStatus.paused);
    } else if (state.playback == QuestionPlaybackStatus.loading) {
      _publish(
        playback: state.backend == QuestionAudioStatus.ready
            ? QuestionPlaybackStatus.ready
            : QuestionPlaybackStatus.idle,
      );
    }
  }

  void recordingEnded() {
    _recording = false;
  }

  Future<void> _play({required bool fromStart}) async {
    if (isClosed || _recording || _questionId == null) return;
    if (state.issue == QuestionAudioIssue.sessionExpired) return;
    if (state.backend == QuestionAudioStatus.disabled) return;
    final epoch = _epoch;
    final playEpoch = ++_playbackEpoch;
    _playbackRetried = false;
    final needsAudio = state.deferred ||
        state.backend != QuestionAudioStatus.ready ||
        _url == null ||
        _urlStale;
    if (needsAudio) {
      if (state.backend == QuestionAudioStatus.pending ||
          state.backend == QuestionAudioStatus.processing) {
        _playWhenReady = true;
        return;
      }
      _playWhenReady = true;
      _pollStarted = _now();
      _delayIndex = 0;
      _transientAttempts = 0;
      _publish(
        playback: QuestionPlaybackStatus.loading,
        issue: QuestionAudioIssue.none,
        deferred: false,
      );
      await _fetch(epoch);
      return;
    }
    await _start(epoch, playEpoch, fromStart: fromStart);
  }

  Future<void> _fetch(int epoch) async {
    final questionId = _questionId;
    if (questionId == null || epoch != _epoch || isClosed) return;
    final ticket = ++_ticket;
    final result = await _getQuestionAudio(GetQuestionAudioParams(questionId));
    if (ticket != _ticket || epoch != _epoch || isClosed) return;
    result.fold(
      (failure) => _handleFailure(failure, epoch),
      (audio) => _apply(audio, epoch),
    );
  }

  void _apply(QuestionAudio audio, int epoch) {
    if (epoch != _epoch || isClosed) return;
    if (audio.questionId != _questionId) {
      _clearTimer();
      _playWhenReady = false;
      _replace(QuestionAudioState(
        questionId: _questionId,
        issue: QuestionAudioIssue.unavailable,
      ));
      return;
    }
    _transientAttempts = 0;
    switch (audio.status) {
      case QuestionAudioStatus.pending:
      case QuestionAudioStatus.processing:
        _replace(QuestionAudioState(
          questionId: _questionId,
          backend: audio.status,
          playback: QuestionPlaybackStatus.loading,
        ));
        _schedule(epoch);
      case QuestionAudioStatus.ready:
        _clearTimer();
        _remember(audio);
        final arm = _playWhenReady && !_recording;
        _replace(QuestionAudioState(
          questionId: _questionId,
          backend: QuestionAudioStatus.ready,
          playback: arm
              ? QuestionPlaybackStatus.loading
              : QuestionPlaybackStatus.ready,
        ));
        if (arm) {
          _playWhenReady = false;
          final playEpoch = ++_playbackEpoch;
          unawaited(_start(epoch, playEpoch, fromStart: false));
        } else {
          _playWhenReady = false;
        }
      case QuestionAudioStatus.failed:
        _clearTimer();
        _playWhenReady = false;
        _url = null;
        _loadedUrl = null;
        _replace(QuestionAudioState(
          questionId: _questionId,
          backend: QuestionAudioStatus.failed,
          issue: QuestionAudioIssue.unavailable,
        ));
      case QuestionAudioStatus.disabled:
        _clearTimer();
        _playWhenReady = false;
        _url = null;
        _loadedUrl = null;
        _replace(QuestionAudioState(
          questionId: _questionId,
          backend: QuestionAudioStatus.disabled,
        ));
    }
  }

  void _handleFailure(Failure failure, int epoch) {
    if (epoch != _epoch || isClosed) return;
    if (failure is RequestCancelledFailure) return;
    if (failure is UnauthorizedFailure) {
      _clearTimer();
      _playWhenReady = false;
      _url = null;
      _loadedUrl = null;
      _replace(QuestionAudioState(
        questionId: _questionId,
        issue: QuestionAudioIssue.sessionExpired,
      ));
      return;
    }
    if (_transient(failure)) {
      _transientAttempts++;
      if (_transientAttempts > transientLimit) {
        _clearTimer();
        _playWhenReady = false;
        _publish(
          playback: QuestionPlaybackStatus.idle,
          issue: QuestionAudioIssue.temporary,
        );
        return;
      }
      _publish(playback: QuestionPlaybackStatus.loading);
      _timer?.cancel();
      final attempt = _transientAttempts;
      _timer = Timer(_transientDelay(attempt), () {
        if (epoch != _epoch || isClosed) return;
        unawaited(_fetch(epoch));
      });
      return;
    }
    _clearTimer();
    _playWhenReady = false;
    _publish(
      playback: QuestionPlaybackStatus.idle,
      issue: QuestionAudioIssue.unavailable,
    );
  }

  Future<void> _start(
    int epoch,
    int playEpoch, {
    required bool fromStart,
  }) async {
    final url = _url;
    if (url == null || url.isEmpty || !_owns(epoch, playEpoch)) return;
    if (_loadedUrl != url) {
      _publish(playback: QuestionPlaybackStatus.loading);
      try {
        await _player.load(url);
      } catch (_) {
        await _onPlaybackFailure(epoch, playEpoch);
        return;
      }
      if (epoch != _epoch || isClosed) {
        if (!_recording) await _player.stop();
        return;
      }
      if (!_owns(epoch, playEpoch)) return;
      _loadedUrl = url;
    }
    if (fromStart) {
      try {
        await _player.seekToStart();
      } catch (_) {
        await _onPlaybackFailure(epoch, playEpoch);
        return;
      }
      if (!_owns(epoch, playEpoch)) return;
    }
    try {
      _armedPlayEpoch = playEpoch;
      await _player.play(stillCurrent: () => _owns(epoch, playEpoch));
    } catch (_) {
      await _onPlaybackFailure(epoch, playEpoch);
      return;
    }
    if (!_owns(epoch, playEpoch)) {
      _loadedUrl = null;
      return;
    }
    _publish(playback: QuestionPlaybackStatus.playing);
  }

  Future<void> _onPlaybackFailure(int epoch, int playEpoch) async {
    if (!_owns(epoch, playEpoch)) return;
    if (_playbackRetried || _recovering) {
      _failPlayback();
      return;
    }
    await _recover(epoch, playEpoch);
  }

  Future<void> _recover(int epoch, int playEpoch) async {
    if (_recovering || !_owns(epoch, playEpoch)) return;
    _recovering = true;
    _playbackRetried = true;
    _loadedUrl = null;
    _url = null;
    _expiresAt = null;
    try {
      await _fetch(epoch);
      if (!_owns(epoch, playEpoch)) return;
      if (state.issue == QuestionAudioIssue.sessionExpired) return;
      if (state.backend != QuestionAudioStatus.ready || _url == null) {
        if (state.backend == QuestionAudioStatus.pending ||
            state.backend == QuestionAudioStatus.processing) {
          _playWhenReady = true;
          return;
        }
        _failPlayback();
        return;
      }
      await _start(epoch, playEpoch, fromStart: false);
    } finally {
      _recovering = false;
    }
  }

  void _failPlayback() {
    _armedPlayEpoch = -1;
    _playWhenReady = false;
    _loadedUrl = null;
    unawaited(_player.stop());
    if (isClosed || state.issue == QuestionAudioIssue.sessionExpired) return;
    _publish(playback: QuestionPlaybackStatus.error);
  }

  void _schedule(int epoch) {
    _timer?.cancel();
    final started = _pollStarted ?? _now();
    _pollStarted ??= started;
    final elapsed = _now().difference(started);
    if (elapsed >= pollWindow) {
      _timeOut();
      return;
    }
    var delay = _nextDelay();
    final remaining = pollWindow - elapsed;
    if (delay > remaining) delay = remaining;
    _timer = Timer(delay, () {
      if (epoch != _epoch || isClosed) return;
      final origin = _pollStarted;
      if (origin != null && _now().difference(origin) >= pollWindow) {
        _timeOut();
        return;
      }
      unawaited(_fetch(epoch));
    });
  }

  Duration _nextDelay() {
    final index = _delayIndex;
    if (_delayIndex < pollDelays.length) _delayIndex++;
    if (index < pollDelays.length) return pollDelays[index];
    return pollDelays.last;
  }

  void _timeOut() {
    _clearTimer();
    _playWhenReady = false;
    _publish(
      playback: QuestionPlaybackStatus.idle,
      issue: QuestionAudioIssue.timedOut,
    );
  }

  void _remember(QuestionAudio audio) {
    final nextUrl = audio.audioUrl;
    if (_loadedUrl != null && _loadedUrl != nextUrl) _loadedUrl = null;
    _url = nextUrl;
    final seconds = audio.expiresInSeconds ?? 0;
    final usable =
        seconds > expiryMargin.inSeconds ? seconds - expiryMargin.inSeconds : 0;
    _expiresAt = _now().add(Duration(seconds: usable));
  }

  bool get _urlStale {
    final expires = _expiresAt;
    if (_url == null || expires == null) return true;
    return !_now().isBefore(expires);
  }

  bool _owns(int epoch, int playEpoch) =>
      !isClosed &&
      !_recording &&
      epoch == _epoch &&
      playEpoch == _playbackEpoch;

  bool _transient(Failure failure) =>
      failure is ServiceUnavailableFailure ||
      failure is NetworkFailure ||
      failure is GatewayTimeoutFailure;

  Duration _transientDelay(int attempt) {
    return switch (attempt) {
      1 => const Duration(seconds: 2),
      2 => const Duration(seconds: 4),
      _ => const Duration(seconds: 8),
    };
  }

  void _onSignal(QuestionAudioPlayerSignal signal) {
    if (isClosed || _armedPlayEpoch != _playbackEpoch) return;
    switch (signal) {
      case QuestionAudioPlayerSignal.started:
        _publish(playback: QuestionPlaybackStatus.playing);
      case QuestionAudioPlayerSignal.paused:
        if (state.playback == QuestionPlaybackStatus.playing) {
          _publish(playback: QuestionPlaybackStatus.paused);
        }
      case QuestionAudioPlayerSignal.completed:
        _armedPlayEpoch = -1;
        _publish(playback: QuestionPlaybackStatus.completed);
      case QuestionAudioPlayerSignal.failed:
        unawaited(_onPlaybackFailure(_epoch, _playbackEpoch));
    }
  }

  void _onForeground() {
    if (_foreground.isResumed || isClosed) return;
    if (state.playback == QuestionPlaybackStatus.playing) {
      unawaited(pause());
    }
  }

  void _dropCurrent() {
    _epoch++;
    _ticket++;
    _playbackEpoch++;
    _armedPlayEpoch = -1;
    _delayIndex = 0;
    _transientAttempts = 0;
    _playWhenReady = false;
    _playbackRetried = false;
    _recovering = false;
    _url = null;
    _loadedUrl = null;
    _expiresAt = null;
    _pollStarted = null;
    _clearTimer();
    _getQuestionAudio.cancel();
    unawaited(_player.stop());
  }

  void _clearTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void _replace(QuestionAudioState next) {
    if (isClosed || next == state) return;
    emit(next);
  }

  void _publish({
    QuestionPlaybackStatus? playback,
    QuestionAudioIssue? issue,
    bool? deferred,
  }) {
    _replace(state.copyWith(
      playback: playback,
      issue: issue,
      deferred: deferred,
    ));
  }

  @override
  Future<void> close() async {
    _foreground.removeListener(_onForeground);
    _epoch++;
    _ticket++;
    _playbackEpoch++;
    _armedPlayEpoch = -1;
    _clearTimer();
    _getQuestionAudio.cancel();
    await _signals.cancel();
    await _player.dispose();
    return super.close();
  }
}
