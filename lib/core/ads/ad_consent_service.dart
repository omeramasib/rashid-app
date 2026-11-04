import 'dart:async';

import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ads_log.dart';

/// Consent gate used before any ad request.
abstract class AdConsentService {
  Future<void> gatherConsent();

  Future<bool> canRequestAds();

  /// Last known answer. False until consent has been gathered.
  bool get canRequestAdsNow;

  Future<bool> isPrivacyOptionsRequired();

  Future<void> showPrivacyOptionsForm();
}

/// Used on iOS and whenever advertising is turned off. It never calls UMP.
class DeniedAdConsentService implements AdConsentService {
  const DeniedAdConsentService();

  @override
  Future<void> gatherConsent() async {}

  @override
  Future<bool> canRequestAds() async => false;

  @override
  bool get canRequestAdsNow => false;

  @override
  Future<bool> isPrivacyOptionsRequired() async => false;

  @override
  Future<void> showPrivacyOptionsForm() async {}
}

/// Google User Messaging Platform. Failures are swallowed so the interview
/// can still start.
class UmpAdConsentService implements AdConsentService {
  bool _canRequestAds = false;
  Future<bool>? _privacyOptions;

  @override
  bool get canRequestAdsNow => _canRequestAds;

  @override
  Future<void> gatherConsent() async {
    try {
      await _requestConsentUpdate().timeout(const Duration(seconds: 10));
    } catch (_) {
      adsLog('consent update failed');
    }
    try {
      await ConsentForm.loadAndShowConsentFormIfRequired((error) {
        if (error != null) {
          adsLog('consent form failed (${error.errorCode})');
        }
      });
    } catch (_) {
      adsLog('consent form failed');
    }
    await _refresh();
  }

  Future<void> _requestConsentUpdate() {
    final completer = Completer<void>();
    try {
      ConsentInformation.instance.requestConsentInfoUpdate(
        ConsentRequestParameters(),
        () {
          if (!completer.isCompleted) completer.complete();
        },
        (error) {
          adsLog('consent update failed (${error.errorCode})');
          if (!completer.isCompleted) completer.complete();
        },
      );
    } catch (_) {
      if (!completer.isCompleted) completer.complete();
    }
    return completer.future;
  }

  @override
  Future<bool> canRequestAds() async {
    await _refresh();
    return _canRequestAds;
  }

  Future<void> _refresh() async {
    try {
      _canRequestAds = await ConsentInformation.instance.canRequestAds();
    } catch (_) {
      adsLog('canRequestAds failed');
      _canRequestAds = false;
    }
  }

  @override
  Future<bool> isPrivacyOptionsRequired() {
    return _privacyOptions ??= _queryPrivacyOptions();
  }

  Future<bool> _queryPrivacyOptions() async {
    try {
      final status = await ConsentInformation.instance
          .getPrivacyOptionsRequirementStatus();
      return status == PrivacyOptionsRequirementStatus.required;
    } catch (_) {
      adsLog('privacy options status failed');
      return false;
    }
  }

  @override
  Future<void> showPrivacyOptionsForm() async {
    try {
      await ConsentForm.showPrivacyOptionsForm((error) {
        if (error != null) {
          adsLog('privacy options failed (${error.errorCode})');
        }
      });
    } catch (_) {
      adsLog('privacy options failed');
    }
    _privacyOptions = null;
    await _refresh();
  }
}
