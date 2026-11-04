import 'package:flutter_test/flutter_test.dart';
import 'package:rashed_app/core/ads/admob_config.dart';

void main() {
  test('default defines use the Google test interstitial on Android', () {
    final config = AdMobConfig.fromEnvironment(isAndroid: true);
    expect(config.enabled, isTrue);
    expect(config.useTestAds, isTrue);
    expect(config.interstitialUnitId, AdMobConfig.androidTestInterstitialId);
    expect(
      config.finishInterstitialUnitId,
      AdMobConfig.androidTestInterstitialId,
    );
    expect(
      config.interstitialUnitId,
      isNot(AdMobConfig.androidProductionInterstitialId),
    );
    expect(
      config.finishInterstitialUnitId,
      isNot(AdMobConfig.androidProductionFinishInterstitialId),
    );
    expect(config.cooldown, const Duration(minutes: 5));
  });

  test('real ads require an explicit production configuration', () {
    final production = const AdMobConfig(
      enabled: true,
      useTestAds: false,
      isAndroid: true,
    );
    expect(
      production.interstitialUnitId,
      AdMobConfig.androidProductionInterstitialId,
    );
    expect(
      production.finishInterstitialUnitId,
      AdMobConfig.androidProductionFinishInterstitialId,
    );
    expect(
      production.interstitialUnitId,
      isNot(production.finishInterstitialUnitId),
    );

    final disabled = const AdMobConfig(
      enabled: false,
      useTestAds: false,
      isAndroid: true,
    );
    expect(disabled.requestsAds, isFalse);
    expect(disabled.interstitialUnitId, isNull);
    expect(disabled.finishInterstitialUnitId, isNull);
  });

  test('iOS never receives an ad unit, including a production configuration',
      () {
    final config = const AdMobConfig(
      enabled: true,
      useTestAds: false,
      isAndroid: false,
    );
    expect(config.requestsAds, isFalse);
    expect(config.interstitialUnitId, isNull);
    expect(config.finishInterstitialUnitId, isNull);
  });
}
