import 'package:flutter_test/flutter_test.dart';
import 'package:rashed_app/features/linkedin/presentation/linkedin_post_link.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  Future<bool> Function(Uri uri, {LaunchMode mode}) record(
    List<(Uri, LaunchMode)> calls,
  ) {
    return (Uri uri, {LaunchMode mode = LaunchMode.platformDefault}) async {
      calls.add((uri, mode));
      return true;
    };
  }

  test('opens the exact share and ugcPost permalinks in the browser', () async {
    final calls = <(Uri, LaunchMode)>[];
    final launch = record(calls);

    expect(
      await openVerifiedLinkedInPost(
        'https://www.linkedin.com/feed/update/urn:li:share:9/',
        launch: launch,
      ),
      isTrue,
    );
    expect(
      await openVerifiedLinkedInPost(
        'https://www.linkedin.com/feed/update/urn:li:ugcPost:44/',
        launch: launch,
      ),
      isTrue,
    );

    expect(calls.map((call) => call.$1.toString()).toList(), [
      'https://www.linkedin.com/feed/update/urn:li:share:9/',
      'https://www.linkedin.com/feed/update/urn:li:ugcPost:44/',
    ]);
    expect(
      calls.every((call) => call.$2 == LaunchMode.inAppBrowserView),
      isTrue,
    );
  });

  test('does not launch LinkedIn when the url is not a post', () async {
    final calls = <(Uri, LaunchMode)>[];
    final launch = record(calls);

    for (final raw in <String?>[
      null,
      'https://www.linkedin.com/',
      'https://www.linkedin.com/feed/update/1',
      'https://www.linkedin.com/feed/update/urn:li:activity:9/',
    ]) {
      expect(await openVerifiedLinkedInPost(raw, launch: launch), isFalse);
    }
    expect(calls, isEmpty);
  });
}
