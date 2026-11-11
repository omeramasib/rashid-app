import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/ads/app_foreground.dart';
import '../../../../core/speech/append_transcript.dart';
import '../../../../core/speech/microphone_permission_service.dart';
import '../../../../core/speech/speech_input_telemetry.dart';
import '../../../../core/speech/speech_locale_resolver.dart';
import '../../../../core/speech/speech_recognition_service.dart';

part 'speech_input_state.dart';

/// One voice answer can span several speech-engine sessions.
///
/// Android ends a recognition session on silence or a platform time limit.
/// That ends the current segment only. Listening restarts until the user taps
/// Done, the app backgrounds, or the engine fails repeatedly. The answer is
/// appended to the text field once, when the voice answer ends.
class SpeechInputCubit extends Cubit<SpeechInputState> {
  SpeechInputCubit({
    required SpeechRecognitionService speech,
    required MicrophonePermissionService permissions,
    AppForegroundSignal? foreground,
    SpeechInputTelemetry telemetry = const NoopSpeechInputTelemetry(),
    this.finalizeTimeout = const Duration(seconds: 3),
    this.restartDelay = const Duration(milliseconds: 400),
    this.segmentGrace = const Duration(milliseconds: 1600),
    this.maxConsecutiveFailures = 3,
    DateTime Function()? now,
  })  : _speech = speech,
        _permissions = permissions,
        _foreground = foreground ?? const AlwaysResumedForeground(),
        _telemetry = telemetry,
        _now = now ?? DateTime.now,
        super(const SpeechInputState()) {
    _foreground.addListener(_onForegroundChanged);
  }

  final SpeechRecognitionService _speech;
  final MicrophonePermissionService _permissions;
  final AppForegroundSignal _foreground;
  final SpeechInputTelemetry _telemetry;
  final DateTime Function() _now;

  /// How long [finish] waits for the last engine result.
  final Duration finalizeTimeout;

  /// Pause after a finished engine segment before opening the next one.
  final Duration restartDelay;

  /// How long to wait for a late final after the engine stops on a partial.
  ///
  /// The recognizer can report that it stopped, then deliver its final result
  /// about 1.5 seconds later. Restarting before that drops the better text
  /// and can overlap the microphone.
  final Duration segmentGrace;

  /// Recoverable engine failures tolerated before the voice answer stops.
  final int maxConsecutiveFailures;

  int _answerId = 0;
  int _engineId = 0;
  bool _starting = false;
  bool _answerOpen = false;
  bool _engineActive = false;
  bool _engineSettled = false;
  bool _closing = false;
  bool _committed = false;
  bool _engineHasSegment = false;
  bool _restartPending = false;
  int _consecutiveFailures = 0;
  String _language = 'en';
  String? _localeId;
  String? _questionId;
  final List<String> _segments = [];
  String _partial = '';
  DateTime? _startedAt;
  Timer? _finalizeTimer;
  Timer? _restartTimer;

  /// Requests permission if needed, then starts listening for [questionId].
  ///
  /// Ignored while another session is starting or running.
  Future<void> start({
    required String questionId,
    required String languageCode,
  }) async {
    if (isClosed || _starting || state.status.isActive) return;
    _starting = true;
    _clearAnswer();
    final answerId = ++_answerId;
    _questionId = questionId;
    _language = languageCode;
    _answerOpen = true;
    try {
      emit(SpeechInputState(
        status: SpeechInputStatus.requestingPermission,
        questionId: questionId,
      ));
      final permission = await _permissions.request();
      if (_left(answerId)) return;
      if (permission != MicrophonePermissionResult.granted) {
        _answerOpen = false;
        emit(SpeechInputState(
          status: permission == MicrophonePermissionResult.permanentlyDenied
              ? SpeechInputStatus.permissionPermanentlyDenied
              : SpeechInputStatus.permissionDenied,
          questionId: questionId,
        ));
        return;
      }

      emit(SpeechInputState(
        status: SpeechInputStatus.initializing,
        questionId: questionId,
      ));
      final ready = await _speech.initialize();
      _log('initialize ready=$ready language=$languageCode');
      if (_left(answerId)) return;
      if (!ready) {
        _fail(SpeechInputStatus.unavailable, null);
        return;
      }
      final reportedLocales = await _reportedLocales();
      final localeId = resolveSpeechLocale(languageCode, reportedLocales);
      _log('locales=$reportedLocales chosen=$localeId');
      if (_left(answerId)) return;
      if (localeId == null) {
        _fail(
          SpeechInputStatus.unavailable,
          SpeechErrorCategory.languageUnavailable,
        );
        return;
      }

      _localeId = localeId;
      _startedAt = _now();
      emit(SpeechInputState(
        status: SpeechInputStatus.listening,
        questionId: questionId,
      ));
      _telemetry.started(language: _language);
      await _listen(answerId);
    } catch (_) {
      if (_left(answerId)) return;
      await _safely(_speech.cancel);
      _fail(SpeechInputStatus.error, SpeechErrorCategory.unknown);
    } finally {
      _starting = false;
    }
  }

  /// Ends the voice answer. Pending restarts are cancelled, the active engine
  /// is stopped, and every completed segment is committed once.
  Future<void> finish() async {
    if (isClosed || !_answerOpen || _committed || _closing) return;
    if (state.status != SpeechInputStatus.listening &&
        state.status != SpeechInputStatus.processing) {
      return;
    }
    await _endAnswer();
  }

  /// Drops the voice answer without writing it to the text field.
  Future<void> cancel() async {
    final wasRunning = _answerOpen &&
        (state.status == SpeechInputStatus.listening ||
            state.status == SpeechInputStatus.processing);
    final wasActive = state.status.isActive || _starting || _answerOpen;
    _abandon();
    if (wasRunning) {
      _telemetry.cancelled(
        language: _language,
        durationSeconds: _elapsedSeconds(),
      );
    }
    if (!isClosed && (wasActive || state.status != SpeechInputStatus.idle)) {
      emit(const SpeechInputState());
    }
    if (wasRunning || _engineActive) await _safely(_speech.cancel);
    _engineActive = false;
  }

  /// Backgrounding stops the microphone and keeps the text captured so far.
  ///
  /// Recording does not resume when the app returns. The user starts it again.
  Future<void> interrupt() {
    if (!_answerOpen ||
        state.status == SpeechInputStatus.requestingPermission ||
        state.status == SpeechInputStatus.initializing) {
      return cancel();
    }
    if (_committed || _closing) return Future.value();
    return _endAnswer();
  }

  /// Clears a finished or failed state so its message disappears.
  void dismiss() {
    if (isClosed || state.status.isActive) return;
    if (state.status == SpeechInputStatus.idle) return;
    emit(const SpeechInputState());
  }

  /// Android 13+ can leave the locale query unfinished when on-device
  /// recognition support fails. A bounded wait keeps that from blocking
  /// the session; the preferred locale is then tried directly.
  Future<List<String>> _reportedLocales() async {
    try {
      return await _speech.localeIds().timeout(const Duration(seconds: 3));
    } on TimeoutException {
      _log('locale query timed out');
      return const [];
    } catch (error) {
      _log('locale query failed: $error');
      return const [];
    }
  }

  void _log(String message) {
    if (kDebugMode) debugPrint('speech: $message');
  }

  Future<bool> openSettings() async {
    try {
      return await _permissions.openSettings();
    } catch (_) {
      return false;
    }
  }

  Future<void> _listen(int answerId) async {
    final localeId = _localeId;
    if (localeId == null || _left(answerId) || _closing || _engineActive) {
      return;
    }
    _engineActive = true;
    _engineSettled = false;
    _engineHasSegment = false;
    _partial = '';
    _restartPending = false;
    final engineId = ++_engineId;
    try {
      if (engineId > 1) {
        await _safely(_speech.cancel);
        if (_left(answerId) || _closing) {
          _engineActive = false;
          return;
        }
      }
      await _speech.listen(
        localeId: localeId,
        callbacks: SpeechSessionCallbacks(
          onResult: (text, isFinal) =>
              _onResult(answerId, engineId, text, isFinal),
          onError: (category) => _onError(answerId, engineId, category),
          onStopped: () => _onEngineIdle(answerId, engineId),
          onDone: () => _onEngineIdle(answerId, engineId),
        ),
      );
      if (_left(answerId) || _closing) {
        _engineActive = false;
        await _safely(_speech.cancel);
      }
    } catch (_) {
      _engineActive = false;
      if (!_left(answerId) && !_closing) {
        _onError(answerId, engineId, SpeechErrorCategory.unknown);
      }
    }
  }

  void _onResult(int answerId, int engineId, String text, bool isFinal) {
    if (!_matches(answerId, engineId)) return;
    final recognized = text.trim();
    if (recognized.isEmpty) return;
    if (!isFinal) {
      if (_engineHasSegment || _partial == recognized) return;
      _partial = recognized;
      _publish();
      return;
    }
    _acceptFinal(recognized);
    _consecutiveFailures = 0;
    _publish();
    if (_closing) {
      _commitAnswer();
      return;
    }
    if (!_engineActive && !_engineSettled) {
      _engineSettled = true;
      _scheduleRestart(restartDelay);
    }
  }

  /// A final result belongs to this engine session only.
  ///
  /// A repeated final replaces that session's segment instead of adding
  /// another copy. Earlier sessions stay in [_segments].
  void _acceptFinal(String text) {
    if (_engineHasSegment) {
      if (_segments.isNotEmpty && _segments.last != text) {
        _segments[_segments.length - 1] = text;
      }
    } else {
      _segments.add(text);
      _engineHasSegment = true;
    }
    _partial = '';
  }

  /// The engine stopped on its own, or it finished delivering results.
  ///
  /// Either callback can arrive once. The voice answer keeps going unless
  /// the user already tapped Done or the app is in the background.
  void _onEngineIdle(int answerId, int engineId) {
    if (!_matches(answerId, engineId) || _engineSettled) return;
    _engineActive = false;
    if (_closing) {
      _engineSettled = true;
      _restartPending = false;
      _armFinalize();
      return;
    }
    if (_restartPending && !_engineHasSegment) return;
    if (_engineHasSegment) {
      _engineSettled = true;
      _consecutiveFailures = 0;
      _scheduleRestart(restartDelay);
      return;
    }
    _scheduleRestart(segmentGrace, countSilence: true);
  }

  void _onError(int answerId, int engineId, SpeechErrorCategory category) {
    if (!_matches(answerId, engineId) || _engineSettled) return;
    _engineActive = false;
    _engineSettled = true;
    _restartPending = false;
    _restartTimer?.cancel();
    _keepPartial();
    if (!_recoverable(category)) {
      unawaited(_safely(_speech.cancel));
      if (_hasText) {
        _commitAnswer();
        return;
      }
      if (category == SpeechErrorCategory.permission) {
        _fail(SpeechInputStatus.permissionDenied, null);
      } else if (category == SpeechErrorCategory.languageUnavailable) {
        _fail(SpeechInputStatus.unavailable, category);
      } else {
        _fail(SpeechInputStatus.error, category);
      }
      return;
    }
    _consecutiveFailures++;
    _log('recoverable error ${category.name} ($_consecutiveFailures)');
    if (_consecutiveFailures >= maxConsecutiveFailures) {
      unawaited(_safely(_speech.cancel));
      if (_hasText) {
        _commitAnswer();
      } else {
        _fail(SpeechInputStatus.error, category);
      }
      return;
    }
    _publish();
    _scheduleRestart(restartDelay);
  }

  Future<void> _endAnswer() async {
    _closing = true;
    _restartPending = false;
    _restartTimer?.cancel();
    if (!_engineActive) {
      _keepPartial();
      _commitAnswer();
      return;
    }
    _publish();
    _armFinalize();
    await _safely(_speech.stop);
    if (!_committed && _engineHasSegment) _commitAnswer();
  }

  void _scheduleRestart(Duration delay, {bool countSilence = false}) {
    _restartTimer?.cancel();
    if (_closing || !_answerOpen || isClosed) {
      _restartPending = false;
      return;
    }
    _restartPending = true;
    _restartTimer = Timer(delay, () {
      _restartPending = false;
      if (_closing || !_answerOpen || _engineActive || isClosed) return;
      _engineSettled = true;
      final silent =
          countSilence && !_engineHasSegment && _partial.trim().isEmpty;
      if (silent) {
        _consecutiveFailures++;
        if (_consecutiveFailures >= maxConsecutiveFailures) {
          _fail(SpeechInputStatus.error, SpeechErrorCategory.noSpeech);
          return;
        }
      } else if (countSilence && _hasText) {
        _consecutiveFailures = 0;
      }
      _keepPartial();
      _publish();
      unawaited(_listen(_answerId));
    });
  }

  void _armFinalize() {
    _finalizeTimer?.cancel();
    _finalizeTimer = Timer(finalizeTimeout, _commitAnswer);
  }

  void _commitAnswer() {
    if (isClosed || _committed || !_answerOpen) return;
    _committed = true;
    _answerOpen = false;
    _closing = true;
    _restartPending = false;
    _restartTimer?.cancel();
    _finalizeTimer?.cancel();
    _keepPartial();
    final text = _joined(_segments);
    final questionId = _questionId;
    if (text.isEmpty || questionId == null) {
      _fail(SpeechInputStatus.error, SpeechErrorCategory.noSpeech);
      return;
    }
    _telemetry.completed(
      language: _language,
      durationSeconds: _elapsedSeconds(),
    );
    emit(SpeechInputState(
      status: SpeechInputStatus.completed,
      questionId: questionId,
      transcript: SpeechTranscript(
        text: text,
        questionId: questionId,
        sessionId: _answerId,
      ),
    ));
  }

  void _keepPartial() {
    final text = _partial.trim();
    if (text.isEmpty || _engineHasSegment) {
      _partial = '';
      return;
    }
    _segments.add(text);
    _engineHasSegment = true;
    _partial = '';
  }

  void _publish() {
    if (!_answerOpen || _committed || isClosed) return;
    emit(SpeechInputState(
      status:
          _closing ? SpeechInputStatus.processing : SpeechInputStatus.listening,
      questionId: _questionId,
      partialText: _joined([..._segments, _partial]),
    ));
  }

  void _fail(SpeechInputStatus status, SpeechErrorCategory? category) {
    _committed = true;
    _answerOpen = false;
    _closing = true;
    _restartPending = false;
    _restartTimer?.cancel();
    _finalizeTimer?.cancel();
    if (status != SpeechInputStatus.permissionDenied) {
      _telemetry.failed(
        language: _language,
        errorCategory: (category ?? SpeechErrorCategory.unknown).name,
      );
    }
    emit(SpeechInputState(
      status: status,
      questionId: _questionId,
      error: category,
    ));
  }

  void _clearAnswer() {
    _segments.clear();
    _partial = '';
    _localeId = null;
    _closing = false;
    _committed = false;
    _engineActive = false;
    _engineSettled = false;
    _engineHasSegment = false;
    _restartPending = false;
    _consecutiveFailures = 0;
    _restartTimer?.cancel();
    _finalizeTimer?.cancel();
  }

  void _abandon() {
    _answerOpen = false;
    _closing = true;
    _committed = true;
    _answerId++;
    _engineId++;
    _restartPending = false;
    _restartTimer?.cancel();
    _finalizeTimer?.cancel();
  }

  bool get _hasText =>
      _segments.any((segment) => segment.trim().isNotEmpty) ||
      _partial.trim().isNotEmpty;

  bool _recoverable(SpeechErrorCategory category) {
    return switch (category) {
      SpeechErrorCategory.noSpeech ||
      SpeechErrorCategory.audio ||
      SpeechErrorCategory.network ||
      SpeechErrorCategory.busy ||
      SpeechErrorCategory.interrupted =>
        true,
      SpeechErrorCategory.permission ||
      SpeechErrorCategory.languageUnavailable ||
      SpeechErrorCategory.unknown =>
        false,
    };
  }

  String _joined(List<String> parts) {
    var text = '';
    for (final part in parts) {
      text = appendTranscript(text, part);
    }
    return text;
  }

  bool _matches(int answerId, int engineId) =>
      !isClosed &&
      _answerOpen &&
      answerId == _answerId &&
      engineId == _engineId;

  bool _left(int answerId) => isClosed || !_answerOpen || answerId != _answerId;

  int _elapsedSeconds() {
    final started = _startedAt;
    if (started == null) return 0;
    return _now().difference(started).inSeconds;
  }

  void _onForegroundChanged() {
    if (_foreground.isResumed || isClosed) return;
    unawaited(interrupt());
  }

  Future<void> _safely(Future<void> Function() action) async {
    try {
      await action();
    } catch (_) {}
  }

  @override
  Future<void> close() async {
    _foreground.removeListener(_onForegroundChanged);
    _abandon();
    if (_engineActive || _starting) await _safely(_speech.cancel);
    _engineActive = false;
    return super.close();
  }
}
