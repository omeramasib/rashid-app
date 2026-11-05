import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:rashed_app/core/ads/ad_consent_service.dart';
import 'package:rashed_app/core/ads/ad_frequency_cap.dart';
import 'package:rashed_app/core/ads/admob_config.dart';
import 'package:rashed_app/core/ads/ads_bootstrap.dart';
import 'package:rashed_app/core/ads/interview_ad_gate.dart';
import 'package:rashed_app/core/ads/interstitial_ad_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeConsent implements AdConsentService {
  FakeConsent({this.allowed = true});

  bool allowed;
  int gathers = 0;
  final List<String> events = <String>[];

  @override
  bool canRequestAdsNow = false;

  @override
  Future<void> gatherConsent() async {
    gathers += 1;
    events.add('consent');
    canRequestAdsNow = allowed;
  }

  @override
  Future<bool> canRequestAds() async => allowed;

  @override
  Future<bool> isPrivacyOptionsRequired() async => false;

  @override
  Future<void> showPrivacyOptionsForm() async {}
}

class FakeAds implements InterstitialAdService {
  bool ready = false;
  int preloads = 0;
  int shows = 0;

  @override
  bool get isReady => ready;

  @override
  Future<void> preload() async {
    preloads += 1;
  }

  @override
  Future<void> show() async {
    shows += 1;
  }

  @override
  void dispose() {}
}

const AdMobConfig androidTestConfig = AdMobConfig(
  enabled: true,
  useTestAds: true,
  isAndroid: true,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeConsent consent;
  late FakeAds ads;
  late AdFrequencyCap frequency;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final preferences = await SharedPreferences.getInstance();
    frequency = AdFrequencyCap(
      preferences: preferences,
      cooldown: const Duration(minutes: 5),
    );
    consent = FakeConsent();
    ads = FakeAds();
  });

  MobileAdsInterviewAdGate gate(
    AdsBootstrap bootstrap,
  ) {
    return MobileAdsInterviewAdGate(
      bootstrap: bootstrap,
      consent: consent,
      frequencyCap: frequency,
      ads: ads,
    );
  }

  test('preload waits for SDK initialization before loading', () async {
    final started = Completer<void>();
    final bootstrap = AdsBootstrap(
      config: androidTestConfig,
      consent: consent,
      initializeSdk: () {
        consent.events.add('init');
        return started.future;
      },
    );
    final pending = gate(bootstrap).preload();
    await Future<void>.delayed(Duration.zero);
    expect(consent.events, <String>['consent', 'init']);
    expect(ads.preloads, 0);
    started.complete();
    await pending;
    expect(ads.preloads, 1);
  });

  test('show does not wait for initialization or a load', () async {
    final hung = Completer<void>();
    final bootstrap = AdsBootstrap(
      config: androidTestConfig,
      consent: consent,
      initializeSdk: () => hung.future,
      sdkTimeout: const Duration(seconds: 30),
    );
    final pending = gate(bootstrap).preload();
    await Future<void>.delayed(Duration.zero);
    ads.ready = false;
    await gate(bootstrap)
        .showIfEligible()
        .timeout(const Duration(milliseconds: 200));
    expect(ads.shows, 0);
    expect(ads.preloads, 0);
    hung.complete();
    await pending;
  });

  test('consent that disallows ads skips initialization and display', () async {
    consent.allowed = false;
    var inits = 0;
    final bootstrap = AdsBootstrap(
      config: androidTestConfig,
      consent: consent,
      initializeSdk: () async {
        inits += 1;
      },
    );
    final interview = gate(bootstrap);
    ads.ready = true;
    await interview.preload();
    await interview.showIfEligible();
    expect(inits, 0);
    expect(ads.preloads, 0);
    expect(ads.shows, 0);
  });

  test('an ad that is not ready is skipped immediately', () async {
    consent.canRequestAdsNow = true;
    ads.ready = false;
    final bootstrap = AdsBootstrap(
      config: androidTestConfig,
      consent: consent,
    );
    await gate(bootstrap).showIfEligible();
    expect(ads.shows, 0);
  });

  test('a ready ad is shown when consent and cooldown allow it', () async {
    consent.canRequestAdsNow = true;
    ads.ready = true;
    final bootstrap = AdsBootstrap(
      config: androidTestConfig,
      consent: consent,
    );
    await gate(bootstrap).showIfEligible();
    expect(ads.shows, 1);
  });

  test('the cooldown skips a ready ad', () async {
    consent.canRequestAdsNow = true;
    ads.ready = true;
    await frequency.recordImpression();
    final bootstrap = AdsBootstrap(
      config: androidTestConfig,
      consent: consent,
    );
    await gate(bootstrap).showIfEligible();
    expect(ads.shows, 0);
  });

  test('iOS does not gather consent or initialize the SDK', () async {
    var inits = 0;
    final bootstrap = AdsBootstrap(
      config: const AdMobConfig(
        enabled: true,
        useTestAds: false,
        isAndroid: false,
      ),
      consent: consent,
      initializeSdk: () async {
        inits += 1;
      },
    );
    ads.ready = true;
    final interview = gate(bootstrap);
    await interview.preload();
    await interview.showIfEligible();
    expect(consent.gathers, 0);
    expect(inits, 0);
    expect(ads.preloads, 0);
    expect(ads.shows, 0);
  });

  test('a failed SDK init can be retried on the next preload', () async {
    var attempts = 0;
    final bootstrap = AdsBootstrap(
      config: androidTestConfig,
      consent: consent,
      initializeSdk: () async {
        attempts += 1;
        if (attempts == 1) throw StateError('init');
      },
    );
    final interview = gate(bootstrap);
    await interview.preload();
    expect(attempts, 1);
    expect(ads.preloads, 0);
    await interview.preload();
    expect(attempts, 2);
    expect(ads.preloads, 1);
  });

  test('the finish placement loads and shows its own ad', () async {
    consent.canRequestAdsNow = true;
    final finishAds = FakeAds()..ready = true;
    final bootstrap = AdsBootstrap(
      config: androidTestConfig,
      consent: consent,
      initializeSdk: () async {},
    );
    final interview = MobileAdsInterviewAdGate(
      bootstrap: bootstrap,
      consent: consent,
      frequencyCap: frequency,
      ads: ads,
      finishAds: finishAds,
    );
    await interview.preload(AdPlacement.interviewFinish);
    await interview.showIfEligible(AdPlacement.interviewFinish);
    expect(finishAds.preloads, 1);
    expect(finishAds.shows, 1);
    expect(ads.preloads, 0);
    expect(ads.shows, 0);
  });

  test('a start impression blocks the finish placement', () async {
    consent.canRequestAdsNow = true;
    ads.ready = true;
    final finishAds = FakeAds()..ready = true;
    await frequency.recordImpression();
    final bootstrap = AdsBootstrap(
      config: androidTestConfig,
      consent: consent,
    );
    final interview = MobileAdsInterviewAdGate(
      bootstrap: bootstrap,
      consent: consent,
      frequencyCap: frequency,
      ads: ads,
      finishAds: finishAds,
    );
    await interview.showIfEligible();
    await interview.showIfEligible(AdPlacement.interviewFinish);
    expect(ads.shows, 0);
    expect(finishAds.shows, 0);
  });

  test('consent that disallows ads skips the finish placement', () async {
    consent.allowed = false;
    final finishAds = FakeAds()..ready = true;
    var inits = 0;
    final bootstrap = AdsBootstrap(
      config: androidTestConfig,
      consent: consent,
      initializeSdk: () async {
        inits += 1;
      },
    );
    final interview = MobileAdsInterviewAdGate(
      bootstrap: bootstrap,
      consent: consent,
      frequencyCap: frequency,
      ads: ads,
      finishAds: finishAds,
    );
    await interview.preload(AdPlacement.interviewFinish);
    await interview.showIfEligible(AdPlacement.interviewFinish);
    expect(inits, 0);
    expect(finishAds.preloads, 0);
    expect(finishAds.shows, 0);
  });

  test('a finish ad that is not ready is skipped immediately', () async {
    consent.canRequestAdsNow = true;
    final finishAds = FakeAds();
    final bootstrap = AdsBootstrap(
      config: androidTestConfig,
      consent: consent,
    );
    final interview = MobileAdsInterviewAdGate(
      bootstrap: bootstrap,
      consent: consent,
      frequencyCap: frequency,
      ads: ads,
      finishAds: finishAds,
    );
    await interview.showIfEligible(AdPlacement.interviewFinish);
    expect(finishAds.shows, 0);
    expect(ads.shows, 0);
  });
}
