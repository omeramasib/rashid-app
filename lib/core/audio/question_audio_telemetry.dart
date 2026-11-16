import 'package:firebase_performance/firebase_performance.dart';

import '../../features/simulation/domain/entities/question_audio.dart';

/// One custom trace per question activation.
///
/// Implementations must not receive question text, audio, or credentials.
/// A failure inside telemetry must not escape to playback.
abstract class QuestionAudioTelemetry {
  void activationStarted();

  void ready({
    required QuestionAudioSource source,
    required int timeToReadyMs,
    required int httpMs,
    required int cacheWriteMs,
    required int prepareMs,
    required int bytes,
  });

  void failed({required String category, required int elapsedMs});

  void cancelled({required int elapsedMs});
}

class NoopQuestionAudioTelemetry implements QuestionAudioTelemetry {
  const NoopQuestionAudioTelemetry();

  @override
  void activationStarted() {}

  @override
  void ready({
    required QuestionAudioSource source,
    required int timeToReadyMs,
    required int httpMs,
    required int cacheWriteMs,
    required int prepareMs,
    required int bytes,
  }) {}

  @override
  void failed({required String category, required int elapsedMs}) {}

  @override
  void cancelled({required int elapsedMs}) {}
}

/// Narrow trace surface so tests do not construct a Firebase [Trace].
abstract class QuestionAudioTrace {
  Future<void> start();

  Future<void> stop();

  void setMetric(String name, int value);

  void putAttribute(String name, String value);
}

class _FirebaseQuestionAudioTrace implements QuestionAudioTrace {
  _FirebaseQuestionAudioTrace(this._trace);

  final Trace _trace;

  @override
  Future<void> start() => _trace.start();

  @override
  Future<void> stop() => _trace.stop();

  @override
  void setMetric(String name, int value) => _trace.setMetric(name, value);

  @override
  void putAttribute(String name, String value) =>
      _trace.putAttribute(name, value);
}

class FirebaseQuestionAudioTelemetry implements QuestionAudioTelemetry {
  FirebaseQuestionAudioTelemetry({QuestionAudioTrace Function()? createTrace})
      : _createTrace = createTrace ??
            (() => _FirebaseQuestionAudioTrace(
                  FirebasePerformance.instance.newTrace('question_audio_ready'),
                ));

  final QuestionAudioTrace Function() _createTrace;
  QuestionAudioTrace? _trace;
  Future<void>? _started;

  @override
  void activationStarted() {
    _finish(result: 'cancelled', elapsedMs: 0);
    try {
      final trace = _createTrace();
      _trace = trace;
      _started = trace.start();
    } catch (_) {
      _trace = null;
      _started = null;
    }
  }

  @override
  void ready({
    required QuestionAudioSource source,
    required int timeToReadyMs,
    required int httpMs,
    required int cacheWriteMs,
    required int prepareMs,
    required int bytes,
  }) {
    final hit = source == QuestionAudioSource.cache ||
        source == QuestionAudioSource.prefetch;
    _finish(
      result: 'success',
      elapsedMs: timeToReadyMs,
      attributes: {
        'audio_source': source.name,
        'audio_cache_hit': hit ? 'true' : 'false',
      },
      metrics: {
        'audio_http_request_ms': httpMs,
        'audio_cache_write_ms': cacheWriteMs,
        'audio_player_prepare_ms': prepareMs,
        'time_to_audio_ready_ms': timeToReadyMs,
        'audio_bytes': bytes,
      },
    );
  }

  @override
  void failed({required String category, required int elapsedMs}) {
    _finish(
      result: 'failure',
      elapsedMs: elapsedMs,
      attributes: {'failure_category': category},
      metrics: {'time_to_audio_ready_ms': elapsedMs},
    );
  }

  @override
  void cancelled({required int elapsedMs}) {
    _finish(
      result: 'cancelled',
      elapsedMs: elapsedMs,
      metrics: {'time_to_audio_ready_ms': elapsedMs},
    );
  }

  void _finish({
    required String result,
    required int elapsedMs,
    Map<String, String> attributes = const {},
    Map<String, int> metrics = const {},
  }) {
    final trace = _trace;
    final started = _started;
    _trace = null;
    _started = null;
    if (trace == null) return;
    Future<void>(() async {
      try {
        await started;
        trace.putAttribute('result', result);
        attributes.forEach(trace.putAttribute);
        trace.setMetric('time_to_audio_ready_ms', _metric(elapsedMs));
        metrics.forEach((name, value) {
          trace.setMetric(name, _metric(value));
        });
        await trace.stop();
      } catch (_) {}
    });
  }

  int _metric(int value) => value < 0 ? 0 : value;
}
