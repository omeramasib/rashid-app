import 'package:flutter_test/flutter_test.dart';
import 'package:rashed_app/features/linkedin/domain/linkedin_app_return_url.dart';
import 'package:rashed_app/features/linkedin/domain/linkedin_oauth_return_link.dart';
import 'package:rashed_app/features/linkedin/domain/linkedin_urls.dart';

void main() {
  test('the publishing return url is the existing app scheme', () {
    expect(LinkedInAppReturnUrl.value, 'rashedapp://linkedin/oauth');
  });

  test('accepts a connected return and ignores untrusted parameters', () {
    final link = LinkedInOAuthReturnLink.tryParse(Uri.parse(
      '${LinkedInAppReturnUrl.value}?result=connected&simulation_id=other&access_token=secret&code=abc&state=xyz',
    ));

    expect(link, isNotNull);
    expect(link!.result, LinkedInOAuthResult.connected);
    expect(link.dedupeKey, '${LinkedInAppReturnUrl.value}?result=connected');
    expect(link.props.join(), isNot(contains('secret')));
    expect(link.props.join(), isNot(contains('other')));
  });

  test('maps the publishing failure results', () {
    expect(
      LinkedInOAuthReturnLink.tryParse(
        Uri.parse('${LinkedInAppReturnUrl.value}?result=cancelled'),
      )?.result,
      LinkedInOAuthResult.cancelled,
    );
    expect(
      LinkedInOAuthReturnLink.tryParse(
        Uri.parse('${LinkedInAppReturnUrl.value}?result=invalid_state'),
      )?.result,
      LinkedInOAuthResult.invalidState,
    );
    expect(
      LinkedInOAuthReturnLink.tryParse(
        Uri.parse('${LinkedInAppReturnUrl.value}?result=missing_permission'),
      )?.result,
      LinkedInOAuthResult.missingPermission,
    );
    expect(
      LinkedInOAuthReturnLink.tryParse(
        Uri.parse('${LinkedInAppReturnUrl.value}?result=account_conflict'),
      )?.result,
      LinkedInOAuthResult.accountConflict,
    );
    expect(
      LinkedInOAuthReturnLink.tryParse(
        Uri.parse('${LinkedInAppReturnUrl.value}?result=unavailable'),
      )?.result,
      LinkedInOAuthResult.unavailable,
    );
  });

  test('rejects clerk redirects and unknown results', () {
    expect(
      LinkedInOAuthReturnLink.tryParse(
        Uri.parse('rashedapp://oauth-callback?result=connected'),
      ),
      isNull,
    );
    expect(
      LinkedInOAuthReturnLink.tryParse(
        Uri.parse('${LinkedInAppReturnUrl.value}?result=token'),
      ),
      isNull,
    );
    expect(
      LinkedInOAuthReturnLink.tryParse(Uri.parse('https://linkedin.com/oauth')),
      isNull,
    );
  });

  test('only a returned linkedin post url can be opened', () {
    expect(verifiedLinkedInPostUrl(null), isNull);
    expect(verifiedLinkedInPostUrl(''), isNull);
    expect(
      verifiedLinkedInPostUrl('https://evil.example/post'),
      isNull,
    );
    expect(
      verifiedLinkedInPostUrl('https://www.linkedin.com/feed/update/1'),
      'https://www.linkedin.com/feed/update/1',
    );
  });
}
