import 'package:url_launcher/url_launcher.dart';

import '../domain/linkedin_urls.dart';

/// The LinkedIn app claims linkedin.com and does not open
/// `/feed/update/urn:li:share` or `ugcPost` links. A browser view does.
const linkedInPostLaunchMode = LaunchMode.inAppBrowserView;

/// Opens [raw] only when it is one share or ugcPost permalink.
Future<bool> openVerifiedLinkedInPost(
  String? raw, {
  Future<bool> Function(Uri uri, {LaunchMode mode})? launch,
}) async {
  final verified = verifiedLinkedInPostUrl(raw);
  if (verified == null) return false;
  final uri = Uri.tryParse(verified);
  if (uri == null) return false;
  try {
    return await (launch ?? _launchInBrowser)(
      uri,
      mode: linkedInPostLaunchMode,
    );
  } catch (_) {
    return false;
  }
}

Future<bool> _launchInBrowser(
  Uri uri, {
  LaunchMode mode = LaunchMode.platformDefault,
}) {
  return launchUrl(uri, mode: mode);
}
