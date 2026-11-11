/// Analytics hook for speech input.
///
/// Implementations must never receive transcripts, audio, or user ids.
abstract class SpeechInputTelemetry {
  void started({required String language});

  void completed({required String language, required int durationSeconds});

  void cancelled({required String language, required int durationSeconds});

  void failed({required String language, required String errorCategory});
}

class NoopSpeechInputTelemetry implements SpeechInputTelemetry {
  const NoopSpeechInputTelemetry();

  @override
  void started({required String language}) {}

  @override
  void completed({required String language, required int durationSeconds}) {}

  @override
  void cancelled({required String language, required int durationSeconds}) {}

  @override
  void failed({required String language, required String errorCategory}) {}
}
