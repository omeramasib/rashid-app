/// Clerk configuration constants.
///
/// Replace the publishable key with your actual Clerk publishable key
/// from the Clerk dashboard (https://dashboard.clerk.com).
class ClerkConfig {
  /// Clerk publishable key
  ///
  /// Get this from: Clerk Dashboard -> API Keys -> Publishable Key
  /// Format: pk_test_xxx or pk_live_xxx
  static const String publishableKey = String.fromEnvironment(
    'CLERK_PUBLISHABLE_KEY',
    defaultValue: 'pk_test_YW1wbGUtcGhlYXNhbnQtODUuY2xlcmsuYWNjb3VudHMuZGV2JA',
  );

  /// Check if Clerk is properly configured
  static bool get isConfigured => publishableKey.isNotEmpty;
}
