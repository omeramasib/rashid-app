import 'package:equatable/equatable.dart';

import 'linkedin_app_return_url.dart';

enum LinkedInOAuthResult {
  connected,
  cancelled,
  invalidState,
  missingPermission,
  accountConflict,
  unavailable,
}

class LinkedInOAuthReturnLink extends Equatable {
  final LinkedInOAuthResult result;
  final String dedupeKey;

  const LinkedInOAuthReturnLink({
    required this.result,
    required this.dedupeKey,
  });

  /// Accepts only the publishing return URL.
  ///
  /// `simulation_id` and every other query parameter are ignored. Ownership
  /// stays with the simulation id the app stored before opening the browser.
  static LinkedInOAuthReturnLink? tryParse(Uri uri) {
    if (uri.scheme.toLowerCase() != LinkedInAppReturnUrl.scheme) return null;
    if (uri.host.toLowerCase() != LinkedInAppReturnUrl.host) return null;
    final path = uri.path.endsWith('/') && uri.path.length > 1
        ? uri.path.substring(0, uri.path.length - 1)
        : uri.path;
    if (path != LinkedInAppReturnUrl.path) return null;

    final result = _result(uri.queryParameters['result']);
    if (result == null) return null;
    return LinkedInOAuthReturnLink(
      result: result,
      dedupeKey:
          '${LinkedInAppReturnUrl.value}?result=${uri.queryParameters['result']}',
    );
  }

  static LinkedInOAuthResult? _result(String? raw) {
    switch (raw) {
      case 'connected':
        return LinkedInOAuthResult.connected;
      case 'cancelled':
        return LinkedInOAuthResult.cancelled;
      case 'invalid_state':
        return LinkedInOAuthResult.invalidState;
      case 'missing_permission':
        return LinkedInOAuthResult.missingPermission;
      case 'account_conflict':
        return LinkedInOAuthResult.accountConflict;
      case 'unavailable':
        return LinkedInOAuthResult.unavailable;
      default:
        return null;
    }
  }

  @override
  List<Object?> get props => [result, dedupeKey];
}
