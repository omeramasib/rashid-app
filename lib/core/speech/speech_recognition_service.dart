/// Sanitized reasons a recognition session can fail.
///
/// Raw plugin messages never leave the service.
enum SpeechErrorCategory {
  noSpeech,
  audio,
  network,
  busy,
  permission,
  languageUnavailable,
  interrupted,
  unknown,
}

typedef SpeechResultCallback = void Function(String text, bool isFinal);

/// Callbacks for one listen session.
///
/// [onStopped] fires when the engine stops capturing audio on its own or after
/// [SpeechRecognitionService.stop]. A final result may still follow.
/// [onDone] fires after the engine has delivered every result.
class SpeechSessionCallbacks {
  const SpeechSessionCallbacks({
    required this.onResult,
    required this.onError,
    required this.onStopped,
    required this.onDone,
  });

  final SpeechResultCallback onResult;
  final void Function(SpeechErrorCategory category) onError;
  final void Function() onStopped;
  final void Function() onDone;
}

/// On-device speech recognition. Permissions are handled separately by
/// `MicrophonePermissionService` and must be granted before [initialize].
abstract class SpeechRecognitionService {
  /// Returns false when the device has no usable recognizer.
  Future<bool> initialize();

  /// Locale ids the recognizer reports, for example `en_US` or `ar-SA`.
  Future<List<String>> localeIds();

  /// Starts one session. Callbacks from earlier sessions are dropped.
  Future<void> listen({
    required String localeId,
    required SpeechSessionCallbacks callbacks,
  });

  /// Stops capturing audio and asks the engine for a final result.
  Future<void> stop();

  /// Stops capturing audio and discards pending results.
  Future<void> cancel();
}
