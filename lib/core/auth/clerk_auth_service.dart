import 'dart:async';
import 'package:clerk_auth/clerk_auth.dart';
import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:flutter/widgets.dart';

/// Result of a social OAuth operation
class SocialAuthResult {
  final String? accessToken;
  final String? error;

  const SocialAuthResult({this.accessToken, this.error});

  bool get isSuccess => accessToken != null && error == null;
}

/// Abstraction for Clerk OAuth operations.
///
/// Handles LinkedIn OAuth flow and extracts provider access token
/// to be sent to backend for authentication.
abstract class ClerkAuthService {
  /// Start LinkedIn OAuth flow and retrieve the LinkedIn access token.
  ///
  /// Returns [SocialAuthResult] with access token on success,
  /// or error message on failure.
  ///
  /// Requires [context] to show the OAuth webview/dialog.
  Future<SocialAuthResult> signInWithLinkedIn(BuildContext context);

  /// Check if user is currently signed in with Clerk
  ///
  /// Requires [context] to access AuthState
  bool isSignedIn(BuildContext context);

  /// Sign out from Clerk
  ///
  /// Requires [context] to access AuthState
  Future<void> signOut(BuildContext context);

  /// Get the current user's access token for a specific provider
  String? getLinkedInAccessToken(BuildContext context);
}

/// Mock/Placeholder implementation for when Clerk is not configured.
///
/// Replace this with ClerkAuthServiceImpl when Clerk SDK is properly set up.
/// To enable Clerk:
/// 1. Run `flutter pub get` to install clerk_flutter
/// 2. Set CLERK_PUBLISHABLE_KEY in ClerkConfig
/// 3. Create ClerkAuthServiceImpl that uses ClerkAuth from the SDK
class MockClerkAuthService implements ClerkAuthService {
  @override
  Future<SocialAuthResult> signInWithLinkedIn(BuildContext context) async {
    // Return error until Clerk is properly configured
    return const SocialAuthResult(
      error: 'LinkedIn authentication not configured. Please set up Clerk.',
    );
  }

  @override
  bool isSignedIn(BuildContext context) => false;

  @override
  Future<void> signOut(BuildContext context) async {}

  @override
  String? getLinkedInAccessToken(BuildContext context) => null;
}

class ClerkAuthServiceImpl implements ClerkAuthService {
  @override
  Future<SocialAuthResult> signInWithLinkedIn(BuildContext context) async {
    try {
      final authState = ClerkAuth.of(context);
      if (authState.isSignedIn) {
        await authState.signOut();
      }
      if (!context.mounted) {
        return const SocialAuthResult(error: 'LinkedIn authentication failed');
      }
      return await _startLinkedInSignIn(context, ClerkAuth.of(context));
    } catch (_) {
      if (!context.mounted) {
        return const SocialAuthResult(error: 'LinkedIn authentication failed');
      }
      try {
        final authState = ClerkAuth.of(context);
        if (authState.isSignedIn) {
          await authState.signOut();
        }
        if (!context.mounted) {
          return const SocialAuthResult(
            error: 'LinkedIn authentication failed',
          );
        }
        return await _startLinkedInSignIn(context, ClerkAuth.of(context));
      } catch (_) {
        return const SocialAuthResult(
          error: 'LinkedIn authentication failed',
        );
      }
    }
  }

  Future<SocialAuthResult> _startLinkedInSignIn(
    BuildContext context,
    ClerkAuthState authState,
  ) async {
    await authState.ssoSignIn(
      context,
      const Strategy(name: 'oauth', provider: 'linkedin_oidc'),
    );
    if (!authState.isSignedIn) {
      return const SocialAuthResult(
        error: 'LinkedIn sign-in was cancelled or failed',
      );
    }
    final jwt = authState.session?.lastActiveToken?.jwt;
    if (jwt == null || jwt.isEmpty) {
      return const SocialAuthResult(
        error: 'Sign-in successful but no session token available',
      );
    }
    return SocialAuthResult(accessToken: jwt);
  }

  @override
  bool isSignedIn(BuildContext context) {
    return ClerkAuth.of(context).isSignedIn;
  }

  @override
  Future<void> signOut(BuildContext context) async {
    await ClerkAuth.of(context).signOut();
  }

  @override
  String? getLinkedInAccessToken(BuildContext context) {
    // Return the Clerk session JWT as the token
    final session = ClerkAuth.sessionOf(context);
    return session?.lastActiveToken?.jwt;
  }
}
