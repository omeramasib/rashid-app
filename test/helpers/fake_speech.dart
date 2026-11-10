import 'dart:async';
import 'dart:ui';

import 'package:rashed_app/core/ads/app_foreground.dart';
import 'package:rashed_app/core/speech/microphone_permission_service.dart';
import 'package:rashed_app/core/speech/speech_input_telemetry.dart';
import 'package:rashed_app/core/speech/speech_recognition_service.dart';
import 'package:rashed_app/features/simulation/presentation/cubit/speech_input_cubit.dart';

class FakeSpeechRecognitionService implements SpeechRecognitionService {
  bool available = true;
  List<String> locales = ['en_US', 'ar_SA'];

  /// When true, [localeIds] never completes.
  bool hangLocales = false;
  Object? listenError;

  /// Delivered as a final result when [stop] is called, if not null.
  String? finalOnStop;

  int initializeCalls = 0;
  int listenCalls = 0;
  int stopCalls = 0;
  int cancelCalls = 0;
  String? lastLocaleId;
  SpeechSessionCallbacks? callbacks;

  @override
  Future<bool> initialize() async {
    initializeCalls++;
    return available;
  }

  @override
  Future<List<String>> localeIds() {
    if (hangLocales) return Completer<List<String>>().future;
    return Future.value(locales);
  }

  @override
  Future<void> listen({
    required String localeId,
    required SpeechSessionCallbacks callbacks,
  }) async {
    listenCalls++;
    final error = listenError;
    if (error != null) throw error;
    lastLocaleId = localeId;
    this.callbacks = callbacks;
  }

  @override
  Future<void> stop() async {
    stopCalls++;
    final text = finalOnStop;
    if (text != null) callbacks?.onResult(text, true);
  }

  @override
  Future<void> cancel() async {
    cancelCalls++;
  }

  void partial(String text) => callbacks!.onResult(text, false);

  void finalResult(String text) => callbacks!.onResult(text, true);
}

class FakeMicrophonePermissionService implements MicrophonePermissionService {
  MicrophonePermissionResult result = MicrophonePermissionResult.granted;
  int requestCalls = 0;
  int settingsCalls = 0;

  @override
  Future<MicrophonePermissionResult> request() async {
    requestCalls++;
    return result;
  }

  @override
  Future<bool> openSettings() async {
    settingsCalls++;
    return true;
  }
}

class FakeForeground implements AppForegroundSignal {
  final _listeners = <VoidCallback>[];
  bool resumed = true;

  @override
  bool get isResumed => resumed;

  void setResumed(bool value) {
    resumed = value;
    for (final listener in List<VoidCallback>.of(_listeners)) {
      listener();
    }
  }

  @override
  void addListener(VoidCallback listener) => _listeners.add(listener);

  @override
  void removeListener(VoidCallback listener) => _listeners.remove(listener);
}

class RecordingTelemetry implements SpeechInputTelemetry {
  final events = <String>[];

  @override
  void started({required String language}) => events.add('started:$language');

  @override
  void completed({required String language, required int durationSeconds}) =>
      events.add('completed:$language');

  @override
  void cancelled({required String language, required int durationSeconds}) =>
      events.add('cancelled:$language');

  @override
  void failed({required String language, required String errorCategory}) =>
      events.add('failed:$errorCategory');
}

/// A speech cubit backed by fakes, for screens that only need it to exist.
SpeechInputCubit idleSpeechCubit() => SpeechInputCubit(
      speech: FakeSpeechRecognitionService(),
      permissions: FakeMicrophonePermissionService(),
    );
