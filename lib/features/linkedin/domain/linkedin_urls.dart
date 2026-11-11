bool isLinkedInAuthorizationUrl(Uri uri) {
  if (uri.scheme != 'https') return false;
  final host = uri.host.toLowerCase();
  return host == 'linkedin.com' || host == 'www.linkedin.com';
}

/// A post URL the backend returned. The app never builds one itself.
String? verifiedLinkedInPostUrl(String? raw) {
  if (raw == null) return null;
  final uri = Uri.tryParse(raw.trim());
  if (uri == null || uri.scheme != 'https') return null;
  final host = uri.host.toLowerCase();
  final linkedInHost = host == 'linkedin.com' || host.endsWith('.linkedin.com');
  if (!linkedInHost || uri.path.isEmpty || uri.path == '/') return null;
  return uri.toString();
}
