import 'package:shared_preferences/shared_preferences.dart';

/// Remembers the last interstitial impression so another one can wait.
class AdFrequencyCap {
  AdFrequencyCap({
    required SharedPreferences preferences,
    required this.cooldown,
    DateTime Function()? now,
  })  : _preferences = preferences,
        _now = now ?? DateTime.now;

  static const String storageKey = 'admob_last_interstitial_ms';

  final SharedPreferences _preferences;
  final Duration cooldown;
  final DateTime Function() _now;

  bool canShow() {
    final stored = _preferences.getInt(storageKey);
    if (stored == null) return true;
    final last = DateTime.fromMillisecondsSinceEpoch(stored);
    return _now().difference(last) >= cooldown;
  }

  /// Persists the SDK impression time. This is not called when show() starts.
  Future<void> recordImpression() {
    return _preferences.setInt(
      storageKey,
      _now().millisecondsSinceEpoch,
    );
  }
}
