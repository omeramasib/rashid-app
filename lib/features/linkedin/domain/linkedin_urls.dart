final _feedPostUrn = RegExp(r'^urn:li:(?:share|ugcPost):[A-Za-z0-9_-]{1,128}$');

bool isLinkedInAuthorizationUrl(Uri uri) {
  if (uri.scheme != 'https') return false;
  final host = uri.host.toLowerCase();
  return host == 'linkedin.com' || host == 'www.linkedin.com';
}

/// A backend permalink for one share or ugcPost.
///
/// The app does not build a post URL. Anything else, including the LinkedIn
/// home page and an activity URN, is not treated as a post that can be opened.
String? verifiedLinkedInPostUrl(String? raw) {
  if (raw == null) return null;
  final trimmed = raw.trim();
  final uri = Uri.tryParse(trimmed);
  if (uri == null || uri.scheme != 'https' || uri.userInfo.isNotEmpty) {
    return null;
  }
  final host = uri.host.toLowerCase();
  final linkedInHost = host == 'linkedin.com' || host.endsWith('.linkedin.com');
  if (!linkedInHost) return null;
  // Dart keeps the trailing slash as an empty segment.
  final segments =
      uri.pathSegments.where((segment) => segment.isNotEmpty).toList();
  if (segments.length != 3 ||
      segments[0] != 'feed' ||
      segments[1] != 'update') {
    return null;
  }
  if (!_feedPostUrn.hasMatch(segments[2])) return null;
  return trimmed;
}
