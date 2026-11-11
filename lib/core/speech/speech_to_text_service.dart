import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_to_text.dart';

import 'speech_recognition_service.dart';

class SpeechToTextService implements SpeechRecognitionService {
  SpeechToTextService({SpeechToText? speech})
      : _speech = speech ?? SpeechToText();

  static const _listenFor = Duration(minutes: 2);
  static const _pauseFor = Duration(seconds: 8);

  final SpeechToText _speech;
  SpeechSessionCallbacks? _session;

  @override
  Future<bool> initialize() async {
    // A successful initialize is remembered by the plugin. Retry only after
    // a failed attempt, so taps never start overlapping initialize calls.
    if (_speech.isAvailable) {
      _log('initialize skipped, engine already available');
      return true;
    }
    try {
      final ready = await _speech.initialize(
        onError: _onError,
        onStatus: _onStatus,
        debugLogging: kDebugMode,
        finalTimeout: const Duration(milliseconds: 1500),
        options: [SpeechToText.androidNoBluetooth],
      );
      _log('initialize result: $ready');
      return ready;
    } catch (error) {
      _log('initialize failed: $error');
      return false;
    }
  }

  @override
  Future<List<String>> localeIds() async {
    try {
      final locales = await _speech.locales();
      return [for (final locale in locales) locale.localeId];
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<void> listen({
    required String localeId,
    required SpeechSessionCallbacks callbacks,
  }) async {
    _session = callbacks;
    await _speech.listen(
      onResult: (result) {
        if (!identical(_session, callbacks)) return;
        callbacks.onResult(result.recognizedWords, result.finalResult);
      },
      listenOptions: SpeechListenOptions(
        localeId: localeId,
        listenMode: ListenMode.dictation,
        partialResults: true,
        cancelOnError: true,
        listenFor: _listenFor,
        pauseFor: _pauseFor,
      ),
    );
  }

  @override
  Future<void> stop() => _speech.stop();

  @override
  Future<void> cancel() {
    _session = null;
    return _speech.cancel();
  }

  void _onStatus(String status) {
    _log('status: $status');
    final session = _session;
    if (session == null) return;
    if (status == SpeechToText.doneStatus) {
      session.onDone();
    } else if (status == SpeechToText.notListeningStatus) {
      session.onStopped();
    }
  }

  void _onError(SpeechRecognitionError error) {
    _log('error: ${error.errorMsg} permanent: ${error.permanent}');
    _session?.onError(categorizeSpeechError(error.errorMsg));
  }

  void _log(String message) {
    if (kDebugMode) debugPrint('speech: $message');
  }
}

/// Maps Android and iOS recognizer error codes to [SpeechErrorCategory].
SpeechErrorCategory categorizeSpeechError(String code) {
  if (code == 'error_no_match' || code == 'error_speech_timeout') {
    return SpeechErrorCategory.noSpeech;
  }
  if (code == 'error_audio_error' || code == 'error_audio') {
    return SpeechErrorCategory.audio;
  }
  if (code.startsWith('error_network') ||
      code == 'error_server' ||
      code == 'error_server_disconnected' ||
      code == 'error_too_many_requests') {
    return SpeechErrorCategory.network;
  }
  if (code == 'error_busy') return SpeechErrorCategory.busy;
  if (code == 'error_permission') return SpeechErrorCategory.permission;
  if (code == 'error_language_not_supported' ||
      code == 'error_language_unavailable') {
    return SpeechErrorCategory.languageUnavailable;
  }
  if (code == 'error_client' || code == 'error_retry') {
    return SpeechErrorCategory.interrupted;
  }
  return SpeechErrorCategory.unknown;
}
