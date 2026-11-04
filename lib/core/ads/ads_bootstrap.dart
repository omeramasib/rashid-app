import 'dart:async';

import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_consent_service.dart';
import 'admob_config.dart';
import 'ads_log.dart';

/// Starts consent and the Mobile Ads SDK without blocking [runApp].
///
/// [ensureInitialized] is safe to call more than once. The SDK initialize
/// call itself is also memoized by [GoogleMobileAdsInitializer].
class AdsBootstrap {
  AdsBootstrap({
    required this.config,
    required this.consent,
    this.initializeSdk,
    this.sdkTimeout = const Duration(seconds: 10),
  });

  final AdMobConfig config;
  final AdConsentService consent;
  final Future<void> Function()? initializeSdk;
  final Duration sdkTimeout;

  Future<bool>? _attempt;
  bool _ready = false;

  bool get isReady => _ready;

  /// Kicks off initialization and does not wait for it.
  void start() {
    unawaited(ensureInitialized());
  }

  Future<bool> ensureInitialized() {
    if (!config.requestsAds) return Future<bool>.value(false);
    if (_ready) return Future<bool>.value(true);
    final current = _attempt;
    if (current != null) return current;
    final run = _initialize();
    _attempt = run;
    return run.whenComplete(() {
      if (!_ready && identical(_attempt, run)) {
        _attempt = null;
      }
    });
  }

  Future<bool> _initialize() async {
    try {
      await consent.gatherConsent();
    } catch (_) {
      adsLog('consent step failed');
    }
    final allowed = await _canRequest();
    if (!allowed) return false;
    final initialize = initializeSdk;
    if (initialize == null) return false;
    try {
      await initialize().timeout(sdkTimeout);
      _ready = true;
      return true;
    } catch (_) {
      adsLog('mobile ads sdk init failed');
      return false;
    }
  }

  Future<bool> _canRequest() async {
    try {
      return await consent.canRequestAds().timeout(const Duration(seconds: 5));
    } catch (_) {
      adsLog('canRequestAds failed');
      return false;
    }
  }
}

/// Calls [MobileAds.instance.initialize] at most once until it fails.
class GoogleMobileAdsInitializer {
  Future<void>? _pending;
  bool _done = false;

  Future<void> call() {
    if (_done) return Future<void>.value();
    return _pending ??= _run();
  }

  Future<void> _run() async {
    try {
      await MobileAds.instance.initialize();
      _done = true;
    } catch (_) {
      _pending = null;
      rethrow;
    }
  }
}
