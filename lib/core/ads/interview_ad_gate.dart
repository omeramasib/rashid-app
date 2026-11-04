import 'ad_consent_service.dart';
import 'ad_frequency_cap.dart';
import 'ad_placement.dart';
import 'ads_bootstrap.dart';
import 'ads_log.dart';
import 'interstitial_ad_service.dart';

export 'ad_placement.dart';

/// Decides whether one interview placement may show an interstitial.
///
/// [showIfEligible] never waits for a load or for SDK startup. If nothing is
/// ready, consent is missing, or the shared cooldown is active, it returns
/// immediately. Both placements use the same [AdFrequencyCap].
abstract class InterviewAdGate {
  Future<void> preload([AdPlacement placement = AdPlacement.interviewStart]);

  Future<void> showIfEligible([
    AdPlacement placement = AdPlacement.interviewStart,
  ]);
}

class MobileAdsInterviewAdGate implements InterviewAdGate {
  MobileAdsInterviewAdGate({
    required this.bootstrap,
    required this.consent,
    required this.frequencyCap,
    required this.ads,
    InterstitialAdService? finishAds,
  }) : finishAds = finishAds ?? const DisabledInterstitialAdService();

  final AdsBootstrap bootstrap;
  final AdConsentService consent;
  final AdFrequencyCap frequencyCap;
  final InterstitialAdService ads;
  final InterstitialAdService finishAds;

  InterstitialAdService _service(AdPlacement placement) {
    return placement == AdPlacement.interviewFinish ? finishAds : ads;
  }

  @override
  Future<void> preload([
    AdPlacement placement = AdPlacement.interviewStart,
  ]) async {
    try {
      final ready = await bootstrap.ensureInitialized();
      if (!ready || !consent.canRequestAdsNow) return;
      await _service(placement).preload();
    } catch (_) {
      adsLog('preload failed');
    }
  }

  @override
  Future<void> showIfEligible([
    AdPlacement placement = AdPlacement.interviewStart,
  ]) async {
    try {
      final service = _service(placement);
      if (!consent.canRequestAdsNow ||
          !frequencyCap.canShow() ||
          !service.isReady) {
        return;
      }
      await service.show();
    } catch (_) {
      adsLog('ad skipped');
    }
  }
}
