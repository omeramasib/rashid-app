import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rashed_app/core/speech/microphone_permission_service.dart';
import 'package:rashed_app/core/speech/speech_recognition_service.dart';
import 'package:rashed_app/features/simulation/presentation/cubit/speech_input_cubit.dart';

import '../../../../helpers/fake_speech.dart';

void main() {
  late FakeSpeechRecognitionService speech;
  late FakeMicrophonePermissionService permissions;
  late FakeForeground foreground;
  late RecordingTelemetry telemetry;
  late SpeechInputCubit cubit;

  setUp(() {
    speech = FakeSpeechRecognitionService();
    permissions = FakeMicrophonePermissionService();
    foreground = FakeForeground();
    telemetry = RecordingTelemetry();
    cubit = SpeechInputCubit(
      speech: speech,
      permissions: permissions,
      foreground: foreground,
      telemetry: telemetry,
    );
  });

  tearDown(() async {
    if (!cubit.isClosed) await cubit.close();
  });

  Future<void> startListening({String languageCode = 'en'}) async {
    await cubit.start(questionId: 'q-1', languageCode: languageCode);
    expect(cubit.state.status, SpeechInputStatus.listening);
  }

  test('does not touch permissions until start is called', () {
    expect(permissions.requestCalls, 0);
    expect(cubit.state.status, SpeechInputStatus.idle);
  });

  test('granted permission starts listening right away', () async {
    final statuses = <SpeechInputStatus>[];
    final sub = cubit.stream.listen((s) => statuses.add(s.status));
    await startListening();
    await Future<void>.delayed(Duration.zero);
    await sub.cancel();

    expect(statuses, [
      SpeechInputStatus.requestingPermission,
      SpeechInputStatus.initializing,
      SpeechInputStatus.listening,
    ]);
    expect(permissions.requestCalls, 1);
    expect(speech.initializeCalls, 1);
    expect(speech.listenCalls, 1);
    expect(telemetry.events, ['started:en']);
  });

  test('denied permission does not initialize or listen', () async {
    permissions.result = MicrophonePermissionResult.denied;
    await cubit.start(questionId: 'q-1', languageCode: 'en');

    expect(cubit.state.status, SpeechInputStatus.permissionDenied);
    expect(speech.initializeCalls, 0);
    expect(speech.listenCalls, 0);
    expect(telemetry.events, isEmpty);
  });

  test('permanently denied permission reports settings state', () async {
    permissions.result = MicrophonePermissionResult.permanentlyDenied;
    await cubit.start(questionId: 'q-1', languageCode: 'en');

    expect(cubit.state.status, SpeechInputStatus.permissionPermanentlyDenied);
    expect(speech.listenCalls, 0);
    await cubit.openSettings();
    expect(permissions.settingsCalls, 1);
  });

  test('unavailable recognizer reports unavailable', () async {
    speech.available = false;
    await cubit.start(questionId: 'q-1', languageCode: 'en');

    expect(cubit.state.status, SpeechInputStatus.unavailable);
    expect(speech.listenCalls, 0);
  });

  test('picks Arabic and English locales from the device list', () async {
    speech.locales = ['en_GB', 'ar_EG'];
    await startListening(languageCode: 'ar');
    expect(speech.lastLocaleId, 'ar_EG');
    await cubit.cancel();

    await startListening(languageCode: 'en');
    expect(speech.lastLocaleId, 'en_GB');
  });

  test('an omitted Arabic locale is still attempted, not treated as no engine',
      () async {
    speech.locales = ['en_US', 'fr_FR'];
    await cubit.start(questionId: 'q-1', languageCode: 'ar');

    expect(cubit.state.status, SpeechInputStatus.listening);
    expect(speech.lastLocaleId, 'ar_SA');
    expect(speech.listenCalls, 1);
  });

  test('the recognizer rejecting the locale is a language failure', () async {
    speech.locales = ['en_US'];
    await cubit.start(questionId: 'q-1', languageCode: 'ar');
    speech.callbacks!.onError(SpeechErrorCategory.languageUnavailable);

    expect(cubit.state.status, SpeechInputStatus.unavailable);
    expect(cubit.state.error, SpeechErrorCategory.languageUnavailable);
    expect(speech.listenCalls, 1);
  });

  test('a locale query that never returns still listens', () {
    fakeAsync((async) {
      speech.hangLocales = true;
      cubit.start(questionId: 'q-1', languageCode: 'ar');
      async.elapse(const Duration(seconds: 3));
      async.flushMicrotasks();

      expect(cubit.state.status, SpeechInputStatus.listening);
      expect(speech.lastLocaleId, 'ar_SA');
      expect(speech.initializeCalls, 1);
    });
  });

  test('a second start does not initialize again while listening', () async {
    await startListening();
    await cubit.start(questionId: 'q-1', languageCode: 'en');

    expect(speech.initializeCalls, 1);
    expect(speech.listenCalls, 1);
  });

  test('rapid taps start a single session', () async {
    final first = cubit.start(questionId: 'q-1', languageCode: 'en');
    final second = cubit.start(questionId: 'q-1', languageCode: 'en');
    await Future.wait([first, second]);
    await cubit.start(questionId: 'q-1', languageCode: 'en');

    expect(permissions.requestCalls, 1);
    expect(speech.listenCalls, 1);
  });

  test('partial results are provisional and never committed alone', () async {
    await startListening();
    speech.partial('I worked');
    speech.partial('I worked on apps');

    expect(cubit.state.partialText, 'I worked on apps');
    expect(cubit.state.transcript, isNull);
    expect(cubit.state.status, SpeechInputStatus.listening);
  });

  test('done commits the final result once', () async {
    await startListening();
    speech.partial('I worked on');
    speech.finalOnStop = 'I worked on production apps.';
    await cubit.finish();

    expect(speech.stopCalls, 1);
    expect(cubit.state.status, SpeechInputStatus.completed);
    expect(
      cubit.state.transcript,
      const SpeechTranscript(
        text: 'I worked on production apps.',
        questionId: 'q-1',
        sessionId: 1,
      ),
    );

    speech.finalResult('late duplicate');
    speech.callbacks!.onDone();
    expect(cubit.state.transcript!.text, 'I worked on production apps.');
    expect(telemetry.events, ['started:en', 'completed:en']);
  });

  test('done keeps the best partial when no final result arrives', () {
    fakeAsync((async) {
      cubit.start(questionId: 'q-1', languageCode: 'en');
      async.flushMicrotasks();
      speech.partial('best partial answer');
      cubit.finish();
      async.flushMicrotasks();
      expect(cubit.state.status, SpeechInputStatus.processing);

      async.elapse(cubit.finalizeTimeout);
      expect(cubit.state.status, SpeechInputStatus.completed);
      expect(cubit.state.transcript!.text, 'best partial answer');
    });
  });

  test('empty recognition commits nothing and reports no speech', () {
    fakeAsync((async) {
      cubit.start(questionId: 'q-1', languageCode: 'en');
      async.flushMicrotasks();
      cubit.finish();
      async.elapse(cubit.finalizeTimeout);

      expect(cubit.state.transcript, isNull);
      expect(cubit.state.status, SpeechInputStatus.error);
      expect(cubit.state.error, SpeechErrorCategory.noSpeech);
    });
  });

  test('an automatic engine stop keeps the answer open and restarts', () {
    fakeAsync((async) {
      cubit.start(questionId: 'q-1', languageCode: 'en');
      async.flushMicrotasks();
      speech.partial('silence ended this');
      speech.callbacks!.onStopped();
      expect(cubit.state.status, SpeechInputStatus.listening);
      expect(cubit.state.transcript, isNull);

      speech.finalResult('silence ended this.');
      async.elapse(cubit.restartDelay);
      async.flushMicrotasks();

      expect(speech.listenCalls, 2);
      expect(cubit.state.status, SpeechInputStatus.listening);
      expect(cubit.state.partialText, 'silence ended this.');
      expect(cubit.state.transcript, isNull);
    });
  });

  test('an automatic stop waits for a late final before reusing the mic', () {
    fakeAsync((async) {
      cubit.start(questionId: 'q-1', languageCode: 'en');
      async.flushMicrotasks();
      speech.partial('kept partial');
      speech.callbacks!.onStopped();
      speech.callbacks!.onDone();
      async.elapse(cubit.restartDelay);

      expect(speech.listenCalls, 1);
      expect(cubit.state.transcript, isNull);

      async.elapse(cubit.segmentGrace);
      async.flushMicrotasks();
      expect(speech.listenCalls, 2);
      expect(cubit.state.partialText, 'kept partial');
    });
  });

  test('a late final replaces the partial and a stale engine is ignored', () {
    fakeAsync((async) {
      cubit.start(questionId: 'q-1', languageCode: 'en');
      async.flushMicrotasks();
      final firstEngine = speech.callbacks!;
      speech.partial('hel');
      firstEngine.onStopped();
      firstEngine.onResult('hello there', true);
      async.elapse(cubit.restartDelay);
      async.flushMicrotasks();

      speech.partial('from the next engine');
      firstEngine.onResult('stale engine', true);
      cubit.finish();
      async.flushMicrotasks();
      async.elapse(cubit.finalizeTimeout);

      expect(cubit.state.transcript!.text, 'hello there from the next engine');
    });
  });

  test('repeated automatic stops with no speech end the answer', () {
    fakeAsync((async) {
      cubit.start(questionId: 'q-1', languageCode: 'en');
      async.flushMicrotasks();
      for (var attempt = 0; attempt < cubit.maxConsecutiveFailures; attempt++) {
        speech.callbacks!.onStopped();
        speech.callbacks!.onDone();
        async.elapse(cubit.segmentGrace);
        async.flushMicrotasks();
      }

      expect(cubit.state.status, SpeechInputStatus.error);
      expect(cubit.state.error, SpeechErrorCategory.noSpeech);
      expect(cubit.state.transcript, isNull);
      expect(speech.listenCalls, cubit.maxConsecutiveFailures);
      expect(telemetry.events.last, 'failed:noSpeech');
    });
  });

  test('a nonrecoverable error keeps captured text and does not restart', () {
    fakeAsync((async) {
      cubit.start(questionId: 'q-1', languageCode: 'en');
      async.flushMicrotasks();
      speech.partial('keep me');
      speech.callbacks!.onError(SpeechErrorCategory.languageUnavailable);
      async.elapse(cubit.restartDelay + cubit.segmentGrace);

      expect(cubit.state.status, SpeechInputStatus.completed);
      expect(cubit.state.transcript!.text, 'keep me');
      expect(speech.listenCalls, 1);
    });
  });

  test('background during a restart keeps the text and does not listen again',
      () {
    fakeAsync((async) {
      cubit.start(questionId: 'q-1', languageCode: 'en');
      async.flushMicrotasks();
      speech.finalResult('Saved segment.');
      speech.callbacks!.onStopped();
      foreground.setResumed(false);
      async.flushMicrotasks();
      async.elapse(cubit.restartDelay + cubit.segmentGrace);

      expect(speech.listenCalls, 1);
      expect(speech.stopCalls, 0);
      expect(cubit.state.transcript!.text, 'Saved segment.');
    });
  });

  test('segments from several engine sessions are committed once', () {
    fakeAsync((async) {
      cubit.start(questionId: 'q-1', languageCode: 'en');
      async.flushMicrotasks();
      speech.finalResult('First segment.');
      speech.callbacks!.onDone();
      async.elapse(cubit.restartDelay);
      async.flushMicrotasks();

      speech.partial('Second');
      speech.finalResult('Second segment.');
      cubit.finish();
      async.flushMicrotasks();

      expect(cubit.state.status, SpeechInputStatus.completed);
      expect(
        cubit.state.transcript!.text,
        'First segment. Second segment.',
      );
      expect(speech.listenCalls, 2);
    });
  });

  test('partial and repeated final results are stored once', () async {
    await startListening();
    speech.partial('hello');
    speech.partial('hello');
    speech.finalResult('hello');
    speech.finalResult('hello');
    await cubit.finish();

    expect(cubit.state.transcript!.text, 'hello');
  });

  test('done during a restart commits every segment and does not listen again',
      () {
    fakeAsync((async) {
      cubit.start(questionId: 'q-1', languageCode: 'en');
      async.flushMicrotasks();
      speech.finalResult('Kept segment.');
      speech.callbacks!.onStopped();
      cubit.finish();
      async.flushMicrotasks();
      async.elapse(cubit.restartDelay);

      expect(speech.listenCalls, 1);
      expect(cubit.state.transcript!.text, 'Kept segment.');
    });
  });

  test('a recoverable error restarts, and repeated failures keep captured text',
      () {
    fakeAsync((async) {
      cubit.start(questionId: 'q-1', languageCode: 'en');
      async.flushMicrotasks();
      speech.partial('kept text');
      speech.callbacks!.onError(SpeechErrorCategory.network);
      expect(cubit.state.transcript, isNull);
      expect(cubit.state.partialText, 'kept text');

      async.elapse(cubit.restartDelay);
      async.flushMicrotasks();
      expect(speech.listenCalls, 2);

      for (var attempt = 1; attempt < cubit.maxConsecutiveFailures; attempt++) {
        speech.callbacks!.onError(SpeechErrorCategory.network);
        async.elapse(cubit.restartDelay);
        async.flushMicrotasks();
      }

      expect(cubit.state.status, SpeechInputStatus.completed);
      expect(cubit.state.transcript!.text, 'kept text');
    });
  });

  test('repeated failures with no text end in a sanitized error', () {
    fakeAsync((async) {
      cubit.start(questionId: 'q-1', languageCode: 'en');
      async.flushMicrotasks();
      for (var attempt = 0; attempt < cubit.maxConsecutiveFailures; attempt++) {
        speech.callbacks!.onError(SpeechErrorCategory.audio);
        async.elapse(cubit.restartDelay);
        async.flushMicrotasks();
      }

      expect(cubit.state.status, SpeechInputStatus.error);
      expect(cubit.state.error, SpeechErrorCategory.audio);
      expect(cubit.state.transcript, isNull);
      expect(telemetry.events.last, 'failed:audio');
    });
  });

  test('listen failure is reported as a generic error', () async {
    speech.listenError = Exception('raw plugin failure');
    await cubit.start(questionId: 'q-1', languageCode: 'en');

    expect(cubit.state.status, SpeechInputStatus.error);
    expect(cubit.state.error, SpeechErrorCategory.unknown);
  });

  test('cancel ignores stale callbacks from the old session', () async {
    await startListening();
    final oldCallbacks = speech.callbacks!;
    await cubit.cancel();

    expect(speech.cancelCalls, 1);
    expect(cubit.state.status, SpeechInputStatus.idle);
    oldCallbacks.onResult('stale text', true);
    oldCallbacks.onDone();
    expect(cubit.state.transcript, isNull);
    expect(cubit.state.status, SpeechInputStatus.idle);
    expect(telemetry.events, ['started:en', 'cancelled:en']);
  });

  test('a new session ignores the previous session callbacks', () async {
    await startListening();
    final oldCallbacks = speech.callbacks!;
    await cubit.cancel();
    await cubit.start(questionId: 'q-2', languageCode: 'en');

    oldCallbacks.onResult('from q-1', true);
    expect(cubit.state.status, SpeechInputStatus.listening);
    expect(cubit.state.questionId, 'q-2');

    speech.finalResult('from q-2');
    expect(cubit.state.transcript, isNull);
    expect(cubit.state.partialText, 'from q-2');
    await cubit.finish();
    expect(cubit.state.transcript!.questionId, 'q-2');
    expect(cubit.state.transcript!.text, 'from q-2');
    expect(cubit.state.transcript!.sessionId, greaterThan(1));
  });

  test('cancel while asking for permission never starts listening', () async {
    final pending = cubit.start(questionId: 'q-1', languageCode: 'en');
    await cubit.cancel();
    await pending;

    expect(speech.listenCalls, 0);
    expect(cubit.state.status, SpeechInputStatus.idle);
  });

  test('going to the background finalizes the recording', () async {
    await startListening();
    speech.partial('before background');
    speech.finalOnStop = 'before background.';
    foreground.setResumed(false);
    await Future<void>.delayed(Duration.zero);

    expect(speech.stopCalls, 1);
    expect(cubit.state.transcript!.text, 'before background.');

    speech.callbacks?.onStopped();
    await Future<void>.delayed(cubit.restartDelay);
    expect(speech.listenCalls, 1);
  });

  test('close cancels an active session', () async {
    await startListening();
    await cubit.close();

    expect(speech.cancelCalls, 1);
  });

  test('can record again after completing', () async {
    await startListening();
    speech.finalOnStop = 'first';
    await cubit.finish();
    await startListening();
    speech.finalOnStop = 'second';
    await cubit.finish();

    expect(cubit.state.transcript!.text, 'second');
    expect(cubit.state.transcript!.sessionId, 2);
  });
}
