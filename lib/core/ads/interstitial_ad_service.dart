import 'dart:async';

import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_placement.dart';
import 'admob_config.dart';
import 'ads_log.dart';
import 'app_foreground.dart';

/// One full-screen ad. Production uses [SdkFullScreenAd]. Tests use a fake.
abstract class FullScreenAd {
  set onDismissed(void Function() callback);

  set onFailedToShow(void Function() callback);

  set onImpression(void Function() callback);

  set onShowed(void Function() callback);

  Future<void> show();

  void dispose();
}

typedef InterstitialLoader = void Function({
  required String adUnitId,
  required void Function(FullScreenAd ad) onLoaded,
  required void Function(Object error) onFailed,
});

abstract class InterstitialAdService {
  bool get isReady;

  Future<void> preload();

  /// Completes once, after the ad is dismissed, fails to show, or never appears.
  ///
  /// A visible ad is not treated as finished until it closes. The returned
  /// future does not finish while the app is backgrounded unless the ad was
  /// already dismissed.
  Future<void> show();

  void dispose();
}

class DisabledInterstitialAdService implements InterstitialAdService {
  const DisabledInterstitialAdService();

  @override
  bool get isReady => false;

  @override
  Future<void> preload() async {}

  @override
  Future<void> show() async {}

  @override
  void dispose() {}
}

/// Builds the platform service, or a disabled one when [AdMobConfig] has no unit.
InterstitialAdService createInterstitialAdService({
  required AdMobConfig config,
  required AppForegroundSignal foreground,
  required void Function() onImpression,
  AdPlacement placement = AdPlacement.interviewStart,
  InterstitialLoader? loadAd,
}) {
  final unitId = config.unitIdFor(placement);
  if (unitId == null) return const DisabledInterstitialAdService();
  return GoogleInterstitialAdService(
    adUnitId: unitId,
    foreground: foreground,
    onImpression: onImpression,
    loadAd: loadAd,
  );
}

class GoogleInterstitialAdService implements InterstitialAdService {
  GoogleInterstitialAdService({
    required String adUnitId,
    required AppForegroundSignal foreground,
    this.onImpression,
    this.presentationTimeout = const Duration(seconds: 8),
    this.resumedPresentationGrace = const Duration(seconds: 1),
    this.dismissGrace = const Duration(seconds: 1),
    this.loadTimeout = const Duration(seconds: 30),
    InterstitialLoader? loadAd,
  })  : _adUnitId = adUnitId,
        _foreground = foreground,
        _loadAd = loadAd ?? _loadGoogleInterstitial;

  final String _adUnitId;
  final AppForegroundSignal _foreground;
  final void Function()? onImpression;
  final Duration presentationTimeout;
  final Duration resumedPresentationGrace;
  final Duration dismissGrace;
  final Duration loadTimeout;
  final InterstitialLoader _loadAd;

  FullScreenAd? _loaded;
  FullScreenAd? _showing;
  bool _loading = false;
  int _loadGeneration = 0;
  Timer? _loadTimer;
  Timer? _presentationTimer;
  Timer? _dismissGraceTimer;
  Completer<void>? _showCompleter;
  bool _showFinished = true;
  bool _visible = false;
  bool _sawHiddenWhileVisible = false;
  bool _holdPresentation = false;
  bool _disposed = false;

  @override
  bool get isReady => _loaded != null;

  @override
  Future<void> preload() {
    if (_disposed || _loaded != null || _loading || _showing != null) {
      return Future<void>.value();
    }
    if (_adUnitId.isEmpty) return Future<void>.value();
    final generation = ++_loadGeneration;
    final completer = Completer<void>();
    _loading = true;
    _loadTimer = Timer(loadTimeout, () {
      if (generation != _loadGeneration || !_loading) return;
      _loading = false;
      _loadGeneration++;
      adsLog('interstitial load timed out');
      if (!completer.isCompleted) completer.complete();
    });
    _loadAd(
      adUnitId: _adUnitId,
      onLoaded: (ad) {
        _loadTimer?.cancel();
        if (generation != _loadGeneration || _disposed || _loaded != null) {
          ad.dispose();
          _loading = false;
          if (!completer.isCompleted) completer.complete();
          return;
        }
        _loading = false;
        _loaded = ad;
        if (!completer.isCompleted) completer.complete();
      },
      onFailed: (error) {
        _loadTimer?.cancel();
        if (generation != _loadGeneration) return;
        _loading = false;
        adsLog('interstitial load failed (${error.runtimeType})');
        if (!completer.isCompleted) completer.complete();
      },
    );
    return completer.future;
  }

  @override
  Future<void> show() {
    final ad = _loaded;
    if (ad == null || _disposed) return Future<void>.value();
    _loaded = null;
    _showing = ad;
    _showFinished = false;
    _visible = false;
    _sawHiddenWhileVisible = false;
    _holdPresentation = false;
    final completer = Completer<void>();
    _showCompleter = completer;
    ad.onShowed = () {
      if (_showFinished) return;
      _visible = true;
      _presentationTimer?.cancel();
      _holdPresentation = false;
    };
    ad.onImpression = () {
      if (_showFinished) return;
      _visible = true;
      _presentationTimer?.cancel();
      _holdPresentation = false;
      final report = onImpression;
      if (report == null) return;
      try {
        report();
      } catch (_) {
        adsLog('impression record failed');
      }
    };
    ad.onDismissed = _finishShow;
    ad.onFailedToShow = _finishShow;
    _foreground.addListener(_onLifecycle);
    _presentationTimer = Timer(presentationTimeout, _onPresentationTimeout);
    try {
      final pending = ad.show();
      unawaited(
        pending.then<void>(
          (_) {},
          onError: (Object _, StackTrace __) {
            adsLog('interstitial show failed');
            _finishShow();
          },
        ),
      );
    } catch (_) {
      adsLog('interstitial show failed');
      _finishShow();
    }
    return completer.future;
  }

  void _onPresentationTimeout() {
    if (_showFinished || _visible) return;
    if (!_foreground.isResumed) {
      _holdPresentation = true;
      return;
    }
    adsLog('interstitial did not present');
    _finishShow();
  }

  void _onLifecycle() {
    if (_showFinished) return;
    if (!_foreground.isResumed) {
      if (_visible) _sawHiddenWhileVisible = true;
      _dismissGraceTimer?.cancel();
      _dismissGraceTimer = null;
      return;
    }
    if (_visible && _sawHiddenWhileVisible) {
      _dismissGraceTimer ??= Timer(dismissGrace, () {
        if (_showFinished || !_foreground.isResumed) return;
        adsLog('interstitial dismiss callback missing');
        _finishShow();
      });
      return;
    }
    if (!_visible && _holdPresentation) {
      _holdPresentation = false;
      _presentationTimer?.cancel();
      _presentationTimer = Timer(
        resumedPresentationGrace,
        _onPresentationTimeout,
      );
    }
  }

  void _finishShow() {
    if (_showFinished) return;
    _showFinished = true;
    _presentationTimer?.cancel();
    _dismissGraceTimer?.cancel();
    _foreground.removeListener(_onLifecycle);
    final ad = _showing;
    _showing = null;
    ad?.dispose();
    final completer = _showCompleter;
    _showCompleter = null;
    if (completer != null && !completer.isCompleted) {
      completer.complete();
    }
    if (!_disposed) {
      unawaited(preload());
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _loadGeneration++;
    _loading = false;
    _loadTimer?.cancel();
    _presentationTimer?.cancel();
    _dismissGraceTimer?.cancel();
    _foreground.removeListener(_onLifecycle);
    _loaded?.dispose();
    _loaded = null;
    if (!_visible) {
      _finishShow();
    }
  }
}

void _loadGoogleInterstitial({
  required String adUnitId,
  required void Function(FullScreenAd ad) onLoaded,
  required void Function(Object error) onFailed,
}) {
  unawaited(
    InterstitialAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => onLoaded(SdkFullScreenAd(ad)),
        onAdFailedToLoad: onFailed,
      ),
    ).catchError((Object error) {
      onFailed(error);
    }),
  );
}

class SdkFullScreenAd implements FullScreenAd {
  SdkFullScreenAd(this._ad);

  final InterstitialAd _ad;
  void Function()? _onDismissed;
  void Function()? _onFailedToShow;
  void Function()? _onImpression;
  void Function()? _onShowed;

  @override
  set onDismissed(void Function() callback) => _onDismissed = callback;

  @override
  set onFailedToShow(void Function() callback) => _onFailedToShow = callback;

  @override
  set onImpression(void Function() callback) => _onImpression = callback;

  @override
  set onShowed(void Function() callback) => _onShowed = callback;

  @override
  Future<void> show() {
    _ad.fullScreenContentCallback = FullScreenContentCallback<InterstitialAd>(
      onAdShowedFullScreenContent: (_) => _onShowed?.call(),
      onAdImpression: (_) => _onImpression?.call(),
      onAdDismissedFullScreenContent: (_) => _onDismissed?.call(),
      onAdFailedToShowFullScreenContent: (_, __) => _onFailedToShow?.call(),
    );
    return _ad.show();
  }

  @override
  void dispose() {
    _ad.dispose();
  }
}
