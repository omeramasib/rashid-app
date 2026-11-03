import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rashed_app/Presentation/utils/api_endpoints.dart' as legacy;
import 'package:rashed_app/core/network/api_endpoints.dart' as core;

void main() {
  tearDown(() => debugDefaultTargetPlatformOverride = null);

  test('Android emulator uses the host loopback alias by default', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    const configuredUrl = String.fromEnvironment('API_BASE_URL');
    expect(core.ApiEndpoints.baseUrl,
        configuredUrl.isNotEmpty ? configuredUrl : 'http://10.0.2.2:8000');
    expect(legacy.ApiEndpoints.baseUrl, core.ApiEndpoints.baseUrl);
  });

  test('iOS simulator uses localhost by default', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    const configuredUrl = String.fromEnvironment('API_BASE_URL');
    expect(core.ApiEndpoints.baseUrl,
        configuredUrl.isNotEmpty ? configuredUrl : 'http://localhost:8000');
    expect(legacy.ApiEndpoints.baseUrl, core.ApiEndpoints.baseUrl);
  });
}
