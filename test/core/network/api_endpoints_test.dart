import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rashed_app/Presentation/utils/api_endpoints.dart' as legacy;
import 'package:rashed_app/core/network/api_endpoints.dart' as core;

void main() {
  tearDown(() => debugDefaultTargetPlatformOverride = null);

  test('Android uses the deployed backend by default', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    const configuredUrl = String.fromEnvironment('API_BASE_URL');
    expect(
      core.ApiEndpoints.baseUrl,
      configuredUrl.isNotEmpty
          ? configuredUrl
          : 'https://rashed-backend.vercel.app',
    );
    expect(legacy.ApiEndpoints.baseUrl, core.ApiEndpoints.baseUrl);
  });

  test('iOS uses the deployed backend by default', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    const configuredUrl = String.fromEnvironment('API_BASE_URL');
    expect(
      core.ApiEndpoints.baseUrl,
      configuredUrl.isNotEmpty
          ? configuredUrl
          : 'https://rashed-backend.vercel.app',
    );
    expect(legacy.ApiEndpoints.baseUrl, core.ApiEndpoints.baseUrl);
  });
}
