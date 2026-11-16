import 'package:flutter_test/flutter_test.dart';
import 'package:rashed_app/core/audio/question_audio_telemetry.dart';
import 'package:rashed_app/features/simulation/domain/entities/question_audio.dart';

void main() {
  test('traces stop on success, failure, and cancellation', () async {
    final traces = <_FakeTrace>[];
    final telemetry = FirebaseQuestionAudioTelemetry(
      createTrace: () {
        final trace = _FakeTrace();
        traces.add(trace);
        return trace;
      },
    );

    telemetry.activationStarted();
    telemetry.ready(
      source: QuestionAudioSource.cold,
      timeToReadyMs: 120,
      httpMs: 80,
      cacheWriteMs: 4,
      prepareMs: 10,
      bytes: 2048,
    );
    await Future<void>.delayed(Duration.zero);
    expect(traces.single.stopped, isTrue);
    expect(traces.single.attributes['result'], 'success');
    expect(traces.single.attributes['audio_source'], 'cold');
    expect(traces.single.attributes['audio_cache_hit'], 'false');
    expect(traces.single.metrics['audio_http_request_ms'], 80);
    expect(traces.single.metrics['time_to_audio_ready_ms'], 120);
    expect(traces.single.metrics['audio_bytes'], 2048);

    telemetry.activationStarted();
    telemetry.failed(category: 'rate_limit', elapsedMs: 30);
    await Future<void>.delayed(Duration.zero);
    expect(traces[1].stopped, isTrue);
    expect(traces[1].attributes['result'], 'failure');
    expect(traces[1].attributes['failure_category'], 'rate_limit');

    telemetry.activationStarted();
    telemetry.cancelled(elapsedMs: 15);
    await Future<void>.delayed(Duration.zero);
    expect(traces[2].stopped, isTrue);
    expect(traces[2].attributes['result'], 'cancelled');
    expect(traces.every((trace) => trace.stopped), isTrue);
  });

  test('a trace that throws does not escape', () async {
    final telemetry = FirebaseQuestionAudioTelemetry(
      createTrace: () => _FakeTrace()..failStop = true,
    );
    telemetry.activationStarted();
    expect(
      () => telemetry.ready(
        source: QuestionAudioSource.cache,
        timeToReadyMs: 1,
        httpMs: 0,
        cacheWriteMs: 0,
        prepareMs: 1,
        bytes: 44,
      ),
      returnsNormally,
    );
    await Future<void>.delayed(Duration.zero);
  });

  test('prefetch is recorded separately from a cold download', () async {
    final traces = <_FakeTrace>[];
    final telemetry = FirebaseQuestionAudioTelemetry(
      createTrace: () {
        final trace = _FakeTrace();
        traces.add(trace);
        return trace;
      },
    );
    telemetry.activationStarted();
    telemetry.ready(
      source: QuestionAudioSource.prefetch,
      timeToReadyMs: 6,
      httpMs: 900,
      cacheWriteMs: 3,
      prepareMs: 2,
      bytes: 1000,
    );
    await Future<void>.delayed(Duration.zero);
    expect(traces.single.attributes['audio_source'], 'prefetch');
    expect(traces.single.attributes['audio_cache_hit'], 'true');
    expect(traces.single.metrics['audio_http_request_ms'], 900);
  });
}

class _FakeTrace implements QuestionAudioTrace {
  final attributes = <String, String>{};
  final metrics = <String, int>{};
  bool started = false;
  bool stopped = false;
  bool failStop = false;

  @override
  Future<void> start() async {
    started = true;
  }

  @override
  Future<void> stop() async {
    if (failStop) throw StateError('perf down');
    stopped = true;
  }

  @override
  void putAttribute(String name, String value) {
    attributes[name] = value;
  }

  @override
  void setMetric(String name, int value) {
    metrics[name] = value;
  }
}
