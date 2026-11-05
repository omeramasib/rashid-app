import '../../domain/entities/linkedin_oauth_start.dart';
import 'linkedin_connection_status_model.dart';

class LinkedInOAuthStartModel extends LinkedInOAuthStart {
  const LinkedInOAuthStartModel({
    required super.authorizationUrl,
    super.expiresAt,
  });

  factory LinkedInOAuthStartModel.fromJson(Map<String, dynamic> json) {
    final body = LinkedInJson.objectBody(json);
    return LinkedInOAuthStartModel(
      authorizationUrl: LinkedInJson.requiredText(
        body['authorization_url'],
        'authorization_url',
      ),
      expiresAt: LinkedInJson.date(body['expires_at']),
    );
  }
}
