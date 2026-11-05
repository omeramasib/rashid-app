import 'package:flutter/foundation.dart';

/// Debug-only diagnostics. Messages stay free of ad-unit and user data.
void adsLog(String message) {
  if (kDebugMode) {
    debugPrint('ads: $message');
  }
}
