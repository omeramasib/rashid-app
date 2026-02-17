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
    print('DEBUG: ClerkAuthServiceImpl - signInWithLinkedIn called');

    try {
      final authState = ClerkAuth.of(context);
      print(
          'DEBUG: ClerkAuthServiceImpl - AuthState obtained: isSignedIn=${authState.isSignedIn}');

      // If already signed in, skip ssoSignIn and return the session JWT directly
      if (authState.isSignedIn) {
        print(
            'DEBUG: ClerkAuthServiceImpl - User already signed in, returning session JWT');
        final session = authState.session;
        final jwt = session?.lastActiveToken?.jwt;
        if (jwt != null) {
          return SocialAuthResult(accessToken: jwt);
        }
        // If no JWT yet, sign out first and re-sign in
        print(
            'DEBUG: ClerkAuthServiceImpl - No JWT available, signing out first');
        await authState.signOut();
      }

      // Trigger the SSO sign-in flow (shows in-app WebView, awaits completion)
      print('DEBUG: ClerkAuthServiceImpl - Calling ssoSignIn');
      await authState.ssoSignIn(
        context,
        const Strategy(name: 'oauth', provider: 'linkedin_oidc'),
      );
      print('DEBUG: ClerkAuthServiceImpl - ssoSignIn completed');

      // After ssoSignIn returns, check if user is signed in
      if (authState.isSignedIn) {
        print('DEBUG: ClerkAuthServiceImpl - User is signed in!');

        // Get the Clerk session JWT token
        final session = authState.session;
        final jwt = session?.lastActiveToken?.jwt;
        print(
            'DEBUG: ClerkAuthServiceImpl - Session JWT: ${jwt != null ? "present (${jwt.length} chars)" : "null"}');

        if (jwt != null) {
          return SocialAuthResult(accessToken: jwt);
        } else {
          // Fallback: user is signed in but no JWT yet
          print(
              'DEBUG: ClerkAuthServiceImpl - No JWT available, returning user email as indicator');
          return const SocialAuthResult(
            error: 'Sign-in successful but no session token available',
          );
        }
      } else {
        print(
            'DEBUG: ClerkAuthServiceImpl - isSignedIn is false after ssoSignIn');
        return const SocialAuthResult(
          error: 'LinkedIn sign-in was cancelled or failed',
        );
      }
    } catch (e) {
      print('DEBUG: ClerkAuthServiceImpl - Exception caught: $e');

      // Handle "already signed in" server error by signing out and retrying
      final errorMsg = e.toString().toLowerCase();
      if (errorMsg.contains('already signed in')) {
        print(
            'DEBUG: ClerkAuthServiceImpl - Server says already signed in, signing out and retrying');
        try {
          final authState = ClerkAuth.of(context);
          await authState.signOut();
          print('DEBUG: ClerkAuthServiceImpl - Signed out, retrying ssoSignIn');

          await authState.ssoSignIn(
            context,
            const Strategy(name: 'oauth', provider: 'linkedin_oidc'),
          );

          if (authState.isSignedIn) {
            final jwt = authState.session?.lastActiveToken?.jwt;
            if (jwt != null) {
              return SocialAuthResult(accessToken: jwt);
            }
          }
        } catch (retryError) {
          print('DEBUG: ClerkAuthServiceImpl - Retry failed: $retryError');
          return SocialAuthResult(error: retryError.toString());
        }
      }

      return SocialAuthResult(error: e.toString());
    }
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
