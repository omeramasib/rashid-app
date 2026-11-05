import 'package:flutter/foundation.dart';

import 'ad_placement.dart';

/// AdMob identifiers and switches.
///
/// A normal run uses Google's test interstitial. Real ads are requested only
/// when the app is built with both of these defines:
/// `--dart-define=ADMOB_ENABLED=true --dart-define=ADMOB_USE_TEST_ADS=false`.
///
/// iOS has no production App ID yet, so both unit ids are null there and no
/// ad is requested. [iosSampleAppId] is Google's public sample App ID, used
/// only as an iOS startup placeholder in Info.plist.
class AdMobConfig {
  const AdMobConfig({
    required this.enabled,
    required this.useTestAds,
    required this.isAndroid,
    this.cooldown = const Duration(minutes: 5),
  });

  factory AdMobConfig.fromEnvironment({bool? isAndroid}) {
    final seconds = int.fromEnvironment(
      'ADMOB_COOLDOWN_SECONDS',
      defaultValue: 300,
    );
    return AdMobConfig(
      enabled: const bool.fromEnvironment(
        'ADMOB_ENABLED',
        defaultValue: true,
      ),
      useTestAds: const bool.fromEnvironment(
        'ADMOB_USE_TEST_ADS',
        defaultValue: true,
      ),
      isAndroid: isAndroid ?? defaultTargetPlatform == TargetPlatform.android,
      cooldown: Duration(seconds: seconds < 0 ? 0 : seconds),
    );
  }

  static const String androidProductionAppId =
      'ca-app-pub-7186366676354332~5056410115';
  static const String androidProductionInterstitialId =
      'ca-app-pub-7186366676354332/7622863708';
  static const String androidProductionFinishInterstitialId =
      'ca-app-pub-7186366676354332/4980835605';
  static const String androidTestInterstitialId =
      'ca-app-pub-3940256099942544/1033173712';
  static const String iosSampleAppId = 'ca-app-pub-3940256099942544~1458002511';

  final bool enabled;
  final bool useTestAds;
  final bool isAndroid;
  final Duration cooldown;

  /// Android advertising is the only supported target until an iOS App ID exists.
  bool get requestsAds => enabled && isAndroid;

  /// Start-placement unit. Null when ads must not be requested.
  String? get interstitialUnitId => unitIdFor(AdPlacement.interviewStart);

  /// Finish-placement unit. Null on iOS and when ads are disabled.
  ///
  /// Development builds use Google's test interstitial for both placements.
  String? get finishInterstitialUnitId =>
      unitIdFor(AdPlacement.interviewFinish);

  /// Null when ads must not be requested, including every iOS build.
  String? unitIdFor(AdPlacement placement) {
    if (!requestsAds) return null;
    if (useTestAds) return androidTestInterstitialId;
    return switch (placement) {
      AdPlacement.interviewStart => androidProductionInterstitialId,
      AdPlacement.interviewFinish => androidProductionFinishInterstitialId,
    };
  }
}
