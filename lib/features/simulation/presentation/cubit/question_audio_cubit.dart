import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/ads/app_foreground.dart';
import '../../../../core/audio/question_audio_player.dart';
import '../../../../core/audio/question_audio_telemetry.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/interview_question.dart';
import '../../domain/entities/question_audio.dart';
import '../../domain/usecases/get_question_audio_usecase.dart';

part 'question_audio_state.dart';

/// Loads and plays speech for the one question on screen.
///
/// The next question may download while this one is showing, including while
/// the microphone is recording. That download never touches the player or the
/// audio session. A response is applied only when its question and ticket are
/// still current.
class QuestionAudioCubit extends Cubit<QuestionAudioState> {
  QuestionAudioCubit({
    required GetQuestionAudioUseCase getQuestionAudio,
    required QuestionAudioPlayer player,
    AppForegroundSignal? foreground,
    QuestionAudioTelemetry? telemetry,
    DateTime Function()? now,
  })  : _getQuestionAudio = getQuestionAudio,
        _player = player,
        _foreground = foreground ?? const AlwaysResumedForeground(),
        _telemetry = telemetry ?? const NoopQuestionAudioTelemetry(),
        _now = now ?? DateTime.now,
        super(const QuestionAudioState()) {
    _foreground.addListener(_onForeground);
    _signals = _player.signals.listen(_onSignal);
  }

  final GetQuestionAudioUseCase _getQuestionAudio;
  final QuestionAudioPlayer _player;
  final AppForegroundSignal _foreground;
  final QuestionAudioTelemetry _telemetry;
  final DateTime Function() _now;

  late final StreamSubscription<QuestionAudioPlayerSignal> _signals;
  Timer? _timer;
  int _epoch = 0;
  int _ticket = 0;
  int _playbackEpoch = 0;
  int _armedPlayEpoch = -1;
  bool _recording = false;
  bool _traceOpen = false;
  bool _prepared = false;
  String? _prefetchQuestionId;
  InterviewQuestion? _question;
  InterviewQuestion? _next;
  QuestionAudioFile? _file;
  final Stopwatch _watch = Stopwatch();

  /// Shows [question]. Audio is requested immediately unless [deferUntilPlay].
  ///
  /// [next] is downloaded after this question's file is ready. Answered
  /// questions defer so opening a review does not generate speech.
  void showQuestion(
    InterviewQuestion question, {
    required bool deferUntilPlay,
    InterviewQuestion? next,
  }) {
    if (question.id.isEmpty) return;
    if (question.id == _question?.id) {
      _next = next;
      if (_file != null) _maybePrefetch();
      return;
    }
    _dropCurrent();
    _question = question;
    _next = next;
    final hint = question.audio;
    if (hint?.status == QuestionAudioStatus.disabled) {
      _replace(QuestionAudioState(
        questionId: question.id,
        backend: QuestionAudioStatus.disabled,
      ));
      _maybePrefetch();
      return;
    }
    if (deferUntilPlay) {
      _replace(QuestionAudioState(
        questionId: question.id,
        deferred: true,
      ));
      return;
    }
    _replace(QuestionAudioState(
      questionId: question.id,
      playback: QuestionPlaybackStatus.loading,
    ));
    unawaited(_fetch(_epoch));
  }

  Future<void> play() => _play(fromStart: false);

  Future<void> resume() => _play(fromStart: false);

  Future<void> replay() => _play(fromStart: true);

  /// One request per tap. A 429 stays locked until `Retry-After` elapses.
  void retry() {
    if (isClosed || _recording || _question == null) return;
    if (state.issue == QuestionAudioIssue.sessionExpired) return;
    if (state.backend == QuestionAudioStatus.disabled) return;
    if (state.retryLocked) return;
    final recoverable = state.issue == QuestionAudioIssue.temporary ||
        state.issue == QuestionAudioIssue.unavailable ||
        state.issue == QuestionAudioIssue.limited ||
        state.issue == QuestionAudioIssue.timedOut ||
        state.playback == QuestionPlaybackStatus.error;
    if (!recoverable) return;
    _timer?.cancel();
    _timer = null;
    _file = null;
    _prepared = false;
    _replace(QuestionAudioState(
      questionId: _question!.id,
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

  Future<void> stop() async {
    _playbackEpoch++;
    _armedPlayEpoch = -1;
    _prepared = false;
    await _player.stop();
    if (isClosed) return;
    if (state.playback == QuestionPlaybackStatus.playing ||
        state.playback == QuestionPlaybackStatus.paused ||
        state.playback == QuestionPlaybackStatus.loading ||
        state.playback == QuestionPlaybackStatus.completed) {
      _publish(
        playback: _file == null
            ? QuestionPlaybackStatus.idle
            : QuestionPlaybackStatus.ready,
      );
    }
  }

  /// Stops speech immediately and keeps playback from starting until
  /// [recordingEnded]. Downloading the next question continues.
  Future<void> suspendForRecording() async {
    if (_recording) return;
    _recording = true;
    _playbackEpoch++;
    _armedPlayEpoch = -1;
    final wasAudible = state.playback == QuestionPlaybackStatus.playing ||
        state.playback == QuestionPlaybackStatus.paused;
    await _player.suspendForCapture();
    if (isClosed) return;
    if (wasAudible) {
      _publish(playback: QuestionPlaybackStatus.paused);
    } else if (state.playback == QuestionPlaybackStatus.loading &&
        _file == null) {
      _publish(playback: QuestionPlaybackStatus.idle);
    }
  }

  void recordingEnded() {
    _recording = false;
    final epoch = _epoch;
    if (_file != null && !_prepared && !isClosed) {
      unawaited(_prepare(epoch));
    }
  }

  Future<void> _play({required bool fromStart}) async {
    if (isClosed || _recording || _question == null) return;
    if (state.issue == QuestionAudioIssue.sessionExpired) return;
    if (state.backend == QuestionAudioStatus.disabled) return;
    if (state.retryLocked) return;
    final epoch = _epoch;
    final playEpoch = ++_playbackEpoch;
    if (_file == null) {
      _publish(
        playback: QuestionPlaybackStatus.loading,
        issue: QuestionAudioIssue.none,
        deferred: false,
        retryLocked: false,
      );
      await _fetch(epoch);
      if (!_owns(epoch, playEpoch) || _file == null || _recording) return;
    }
    if (!_prepared) {
      final prepared = await _prepare(epoch);
      if (!prepared || !_owns(epoch, playEpoch)) return;
    }
    if (fromStart) {
      try {
        await _player.seekToStart();
      } catch (_) {
        await _failPlayback(epoch);
        return;
      }
      if (!_owns(epoch, playEpoch)) return;
    }
    try {
      _armedPlayEpoch = playEpoch;
      await _player.play(stillCurrent: () => _owns(epoch, playEpoch));
    } catch (_) {
      await _failPlayback(epoch);
      return;
    }
    if (!_owns(epoch, playEpoch)) return;
    _publish(playback: QuestionPlaybackStatus.playing);
  }

  Future<void> _fetch(int epoch) async {
    final question = _question;
    if (question == null || epoch != _epoch || isClosed) return;
    final ticket = ++_ticket;
    _openTrace();
    final result = await _getQuestionAudio(GetQuestionAudioParams(question));
    if (ticket != _ticket || epoch != _epoch || isClosed) return;
    await result.fold(
      (failure) async => _handleFailure(failure, epoch),
      (audio) => _apply(audio, epoch),
    );
  }

  Future<void> _apply(QuestionAudioFile audio, int epoch) async {
    if (epoch != _epoch || isClosed) return;
    if (audio.questionId != _question?.id) {
      _closeTraceFailure('mismatch');
      _publish(
        playback: QuestionPlaybackStatus.idle,
        issue: QuestionAudioIssue.unavailable,
      );
      return;
    }
    _file = audio;
    if (_recording) {
      _replace(QuestionAudioState(
        questionId: _question!.id,
        backend: QuestionAudioStatus.ready,
        playback: QuestionPlaybackStatus.ready,
      ));
      _maybePrefetch();
      return;
    }
    await _prepare(epoch);
  }

  /// Loads the current file. Returns false when the question changed or the
  /// file could not be prepared. Does not start playback.
  Future<bool> _prepare(int epoch) async {
    final file = _file;
    if (file == null || epoch != _epoch || isClosed) return false;
    final prepare = Stopwatch()..start();
    try {
      await _player.load(file.filePath);
    } catch (_) {
      await _failPlayback(epoch);
      return false;
    }
    if (epoch != _epoch || isClosed) return false;
    _prepared = true;
    _safeTelemetry(() => _telemetry.ready(
          source: file.source,
          timeToReadyMs: _elapsedMs,
          httpMs: file.httpMs,
          cacheWriteMs: file.cacheWriteMs,
          prepareMs: prepare.elapsedMilliseconds,
          bytes: file.bytes,
        ));
    _traceOpen = false;
    _watch.stop();
    _replace(QuestionAudioState(
      questionId: _question?.id,
      backend: QuestionAudioStatus.ready,
      playback: QuestionPlaybackStatus.ready,
    ));
    _maybePrefetch();
    return true;
  }

  void _handleFailure(Failure failure, int epoch) {
    if (epoch != _epoch || isClosed) return;
    if (failure is RequestCancelledFailure) {
      _closeTraceCancelled();
      return;
    }
    _closeTraceFailure(_category(failure));
    _file = null;
    _prepared = false;
    if (failure is UnauthorizedFailure) {
      _replace(QuestionAudioState(
        questionId: _question?.id,
        issue: QuestionAudioIssue.sessionExpired,
      ));
      return;
    }
    if (failure is RateLimitFailure) {
      final wait = failure.retryAfter;
      final locked = wait != null && wait > Duration.zero;
      _replace(QuestionAudioState(
        questionId: _question?.id,
        issue: QuestionAudioIssue.limited,
        retryLocked: locked,
      ));
      if (locked) {
        _timer?.cancel();
        _timer = Timer(wait, () {
          if (epoch != _epoch || isClosed) return;
          if (state.issue != QuestionAudioIssue.limited) return;
          _publish(retryLocked: false);
        });
      }
      return;
    }
    final temporary = failure is ServiceUnavailableFailure ||
        failure is NetworkFailure ||
        failure is GatewayTimeoutFailure ||
        failure is RequestTimeoutFailure;
    _publish(
      playback: QuestionPlaybackStatus.idle,
      issue: temporary
          ? QuestionAudioIssue.temporary
          : QuestionAudioIssue.unavailable,
      retryLocked: false,
    );
  }

  Future<void> _failPlayback(int epoch) async {
    if (epoch != _epoch || isClosed) return;
    _armedPlayEpoch = -1;
    _prepared = false;
    final question = _question;
    if (question != null) {
      try {
        await _getQuestionAudio.evict(question);
      } catch (_) {}
    }
    _file = null;
    _closeTraceFailure('playback');
    unawaited(_player.stop());
    if (isClosed || state.issue == QuestionAudioIssue.sessionExpired) return;
    _publish(playback: QuestionPlaybackStatus.error);
  }

  void _maybePrefetch() {
    final next = _next;
    if (next == null || next.id.isEmpty || isClosed) return;
    if (next.audio?.status == QuestionAudioStatus.disabled) return;
    if (_prefetchQuestionId == next.id) return;
    _prefetchQuestionId = next.id;
    unawaited(_prefetch(next));
  }

  Future<void> _prefetch(InterviewQuestion next) async {
    try {
      await _getQuestionAudio(
        GetQuestionAudioParams(next, prefetch: true),
      );
    } catch (_) {
    } finally {
      if (isClosed || _prefetchQuestionId != next.id) return;
      final upcoming = _next;
      if (upcoming != null && upcoming.id != next.id) {
        _prefetchQuestionId = null;
        _maybePrefetch();
      }
    }
  }

  void _openTrace() {
    if (_traceOpen) return;
    _watch
      ..reset()
      ..start();
    _traceOpen = true;
    _safeTelemetry(_telemetry.activationStarted);
  }

  void _closeTraceFailure(String category) {
    if (!_traceOpen) return;
    final elapsed = _elapsedMs;
    _traceOpen = false;
    _watch.stop();
    _safeTelemetry(() => _telemetry.failed(
          category: category,
          elapsedMs: elapsed,
        ));
  }

  void _closeTraceCancelled() {
    if (!_traceOpen) return;
    final elapsed = _elapsedMs;
    _traceOpen = false;
    _watch.stop();
    _safeTelemetry(() => _telemetry.cancelled(elapsedMs: elapsed));
  }

  int get _elapsedMs => _watch.elapsedMilliseconds;

  void _safeTelemetry(void Function() report) {
    try {
      report();
    } catch (_) {}
  }

  String _category(Failure failure) {
    if (failure is RateLimitFailure) return 'rate_limit';
    if (failure is UnauthorizedFailure) return 'unauthorized';
    if (failure is NotFoundFailure) return 'not_found';
    if (failure is ValidationFailure) return 'invalid';
    if (failure is UpstreamFailure) return 'invalid_audio';
    if (failure is GatewayTimeoutFailure || failure is RequestTimeoutFailure) {
      return 'timeout';
    }
    if (failure is NetworkFailure) return 'network';
    if (failure is ServiceUnavailableFailure) return 'unavailable';
    if (failure is CacheFailure) return 'cache';
    return 'server';
  }

  bool _owns(int epoch, int playEpoch) =>
      !isClosed &&
      !_recording &&
      epoch == _epoch &&
      playEpoch == _playbackEpoch;

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
        unawaited(_failPlayback(_epoch));
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
    _file = null;
    _prepared = false;
    _prefetchQuestionId = null;
    _clearTimer();
    _closeTraceCancelled();
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
    bool? retryLocked,
  }) {
    _replace(state.copyWith(
      playback: playback,
      issue: issue,
      deferred: deferred,
      retryLocked: retryLocked,
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
    _closeTraceCancelled();
    await _signals.cancel();
    await _player.dispose();
    try {
      await _getQuestionAudio.discard();
    } catch (_) {}
    return super.close();
  }
}
