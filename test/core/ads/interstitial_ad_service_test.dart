import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rashed_app/core/ads/ad_frequency_cap.dart';
import 'package:rashed_app/core/ads/ad_placement.dart';
import 'package:rashed_app/core/ads/admob_config.dart';
import 'package:rashed_app/core/ads/app_foreground.dart';
import 'package:rashed_app/core/ads/interstitial_ad_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeFullScreenAd implements FullScreenAd {
  void Function()? dismissed;
  void Function()? failed;
  void Function()? impression;
  void Function()? showed;
  int shows = 0;
  int disposes = 0;
  bool throwOnShow = false;

  @override
  set onDismissed(void Function() callback) => dismissed = callback;

  @override
  set onFailedToShow(void Function() callback) => failed = callback;

  @override
  set onImpression(void Function() callback) => impression = callback;

  @override
  set onShowed(void Function() callback) => showed = callback;

  @override
  Future<void> show() {
    shows += 1;
    if (throwOnShow) throw StateError('show');
    return Future<void>.value();
  }

  @override
  void dispose() {
    disposes += 1;
  }
}

class ScriptedLoader {
  int calls = 0;
  String? unitId;
  void Function(FullScreenAd ad)? onLoaded;
  void Function(Object error)? onFailed;
  FakeFullScreenAd? ad;

  void call({
    required String adUnitId,
    required void Function(FullScreenAd ad) onLoaded,
    required void Function(Object error) onFailed,
  }) {
    calls += 1;
    unitId = adUnitId;
    this.onLoaded = onLoaded;
    this.onFailed = onFailed;
  }

  FakeFullScreenAd succeed() {
    final loaded = FakeFullScreenAd();
    ad = loaded;
    onLoaded!(loaded);
    return loaded;
  }

  void fail() {
    onFailed!(StateError('load'));
  }
}

class ControllableForeground implements AppForegroundSignal {
  ControllableForeground({this.resumed = true});

  bool resumed;
  final List<void Function()> _listeners = <void Function()>[];

  @override
  bool get isResumed => resumed;

  @override
  void addListener(void Function() listener) => _listeners.add(listener);

  @override
  void removeListener(void Function() listener) => _listeners.remove(listener);

  void setResumed(bool value) {
    resumed = value;
    for (final listener in List<void Function()>.of(_listeners)) {
      listener();
    }
  }
}

GoogleInterstitialAdService serviceFor(
  ScriptedLoader loader, {
  AppForegroundSignal? foreground,
  void Function()? onImpression,
  Duration presentationTimeout = const Duration(seconds: 8),
  Duration dismissGrace = const Duration(milliseconds: 500),
  Duration resumedPresentationGrace = const Duration(seconds: 1),
}) {
  return GoogleInterstitialAdService(
    adUnitId: AdMobConfig.androidTestInterstitialId,
    foreground: foreground ?? const AlwaysResumedForeground(),
    onImpression: onImpression,
    presentationTimeout: presentationTimeout,
    resumedPresentationGrace: resumedPresentationGrace,
    dismissGrace: dismissGrace,
    loadTimeout: const Duration(hours: 1),
    loadAd: loader.call,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loads once until the current ad is consumed', () async {
    final loader = ScriptedLoader();
    final service = serviceFor(loader);
    final first = service.preload();
    final second = service.preload();
    expect(loader.calls, 1);
    expect(service.isReady, isFalse);
    loader.succeed();
    await Future.wait(<Future<void>>[first, second]);
    expect(service.isReady, isTrue);
    await service.preload();
    expect(loader.calls, 1);
    expect(loader.unitId, AdMobConfig.androidTestInterstitialId);
    service.dispose();
  });

  test('a failed load leaves the interview path with no ad', () async {
    final loader = ScriptedLoader();
    final service = serviceFor(loader);
    final pending = service.preload();
    loader.fail();
    await pending;
    expect(service.isReady, isFalse);
    final again = service.preload();
    expect(loader.calls, 2);
    loader.succeed();
    await again;
    expect(service.isReady, isTrue);
    service.dispose();
  });

  test('show failure completes once and records no impression', () async {
    final loader = ScriptedLoader();
    var impressions = 0;
    final service = serviceFor(loader, onImpression: () => impressions++);
    final pending = service.preload();
    final ad = loader.succeed();
    await pending;
    final shown = service.show();
    ad.failed!.call();
    ad.failed!.call();
    await shown;
    expect(ad.shows, 1);
    expect(ad.disposes, 1);
    expect(impressions, 0);
    expect(service.isReady, isFalse);
    service.dispose();
  });

  test('a thrown show completes once', () async {
    final loader = ScriptedLoader();
    final service = serviceFor(loader);
    final pending = service.preload();
    final ad = loader.succeed();
    await pending;
    ad.throwOnShow = true;
    await service.show();
    expect(ad.disposes, 1);
    service.dispose();
  });

  test('impression is stored from the callback, not from show()', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final preferences = await SharedPreferences.getInstance();
    final cap = AdFrequencyCap(
      preferences: preferences,
      cooldown: const Duration(minutes: 5),
      now: () => DateTime(2026, 1, 1, 12),
    );
    final loader = ScriptedLoader();
    Future<void>? write;
    final service = serviceFor(
      loader,
      onImpression: () {
        write = cap.recordImpression();
      },
    );
    final pending = service.preload();
    final ad = loader.succeed();
    await pending;
    final shown = service.show();
    await Future<void>.delayed(Duration.zero);
    expect(preferences.getInt(AdFrequencyCap.storageKey), isNull);
    expect(cap.canShow(), isTrue);
    ad.impression!.call();
    await write;
    expect(cap.canShow(), isFalse);
    ad.dismissed!.call();
    ad.dismissed!.call();
    await shown;
    expect(ad.disposes, 1);
    service.dispose();
  });

  test('an ad that never presents is released once, and not while backgrounded',
      () {
    fakeAsync((async) {
      final foreground = ControllableForeground(resumed: false);
      final loader = ScriptedLoader();
      final service = serviceFor(loader, foreground: foreground);
      service.preload();
      final ad = loader.succeed();
      var done = false;
      service.show().then((_) => done = true);
      async.elapse(const Duration(seconds: 8));
      expect(done, isFalse);
      foreground.setResumed(true);
      async.elapse(const Duration(milliseconds: 999));
      expect(done, isFalse);
      async.elapse(const Duration(milliseconds: 2));
      expect(done, isTrue);
      expect(ad.disposes, 1);
      service.dispose();
    });
  });

  test('a visible ad is not released by the presentation timeout', () {
    fakeAsync((async) {
      final loader = ScriptedLoader();
      final service = serviceFor(loader);
      service.preload();
      final ad = loader.succeed();
      var done = false;
      service.show().then((_) => done = true);
      ad.showed!.call();
      async.elapse(const Duration(seconds: 30));
      expect(done, isFalse);
      expect(ad.disposes, 0);
      ad.dismissed!.call();
      async.elapse(Duration.zero);
      expect(done, isTrue);
      service.dispose();
    });
  });

  test('a missing dismiss after the ad activity closes completes once', () {
    fakeAsync((async) {
      final foreground = ControllableForeground();
      final loader = ScriptedLoader();
      final service = serviceFor(loader, foreground: foreground);
      service.preload();
      final ad = loader.succeed();
      var done = false;
      service.show().then((_) => done = true);
      ad.showed!.call();
      async.elapse(const Duration(seconds: 9));
      expect(done, isFalse);
      foreground.setResumed(false);
      foreground.setResumed(true);
      async.elapse(const Duration(milliseconds: 499));
      expect(done, isFalse);
      async.elapse(const Duration(milliseconds: 2));
      expect(done, isTrue);
      expect(ad.disposes, 1);
      service.dispose();
    });
  });

  test('iOS and disabled configs never call the loader', () async {
    final loader = ScriptedLoader();
    final service = createInterstitialAdService(
      config: const AdMobConfig(
        enabled: true,
        useTestAds: false,
        isAndroid: false,
      ),
      foreground: const AlwaysResumedForeground(),
      onImpression: () {},
      loadAd: loader.call,
    );
    expect(service, isA<DisabledInterstitialAdService>());
    await service.preload();
    await service.show();
    expect(loader.calls, 0);
    expect(service.isReady, isFalse);
  });

  test('the Android test configuration requests the Google test unit',
      () async {
    final loader = ScriptedLoader();
    final service = createInterstitialAdService(
      config: const AdMobConfig(
        enabled: true,
        useTestAds: true,
        isAndroid: true,
      ),
      foreground: const AlwaysResumedForeground(),
      onImpression: () {},
      loadAd: loader.call,
    );
    final pending = service.preload();
    expect(loader.unitId, AdMobConfig.androidTestInterstitialId);
    expect(loader.unitId, isNot(AdMobConfig.androidProductionInterstitialId));
    loader.succeed();
    await pending;
    service.dispose();
  });

  test('the finish placement uses the test unit until production ads',
      () async {
    final loader = ScriptedLoader();
    final service = createInterstitialAdService(
      config: const AdMobConfig(
        enabled: true,
        useTestAds: true,
        isAndroid: true,
      ),
      foreground: const AlwaysResumedForeground(),
      placement: AdPlacement.interviewFinish,
      onImpression: () {},
      loadAd: loader.call,
    );
    final pending = service.preload();
    expect(loader.unitId, AdMobConfig.androidTestInterstitialId);
    expect(
      loader.unitId,
      isNot(AdMobConfig.androidProductionFinishInterstitialId),
    );
    loader.succeed();
    await pending;
    service.dispose();
  });

  test('production finish ads use the finish unit and not the start unit',
      () async {
    final loader = ScriptedLoader();
    final service = createInterstitialAdService(
      config: const AdMobConfig(
        enabled: true,
        useTestAds: false,
        isAndroid: true,
      ),
      foreground: const AlwaysResumedForeground(),
      placement: AdPlacement.interviewFinish,
      onImpression: () {},
      loadAd: loader.call,
    );
    final pending = service.preload();
    expect(loader.unitId, AdMobConfig.androidProductionFinishInterstitialId);
    expect(loader.unitId, isNot(AdMobConfig.androidProductionInterstitialId));
    loader.succeed();
    await pending;
    service.dispose();
  });

  test('iOS does not request the finish placement', () async {
    final loader = ScriptedLoader();
    final service = createInterstitialAdService(
      config: const AdMobConfig(
        enabled: true,
        useTestAds: false,
        isAndroid: false,
      ),
      foreground: const AlwaysResumedForeground(),
      placement: AdPlacement.interviewFinish,
      onImpression: () {},
      loadAd: loader.call,
    );
    expect(service, isA<DisabledInterstitialAdService>());
    await service.preload();
    expect(loader.calls, 0);
  });
}
