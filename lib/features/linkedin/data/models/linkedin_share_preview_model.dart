import '../../domain/entities/linkedin_share_preview.dart';
import 'linkedin_connection_status_model.dart';

class LinkedInSharePreviewModel extends LinkedInSharePreview {
  const LinkedInSharePreviewModel({
    required super.previewId,
    required super.simulationId,
    required super.text,
    required super.contentSha256,
    super.expiresAt,
  });

  factory LinkedInSharePreviewModel.fromJson(Map<String, dynamic> json) {
    final body = LinkedInJson.objectBody(json);
    return LinkedInSharePreviewModel(
      previewId: LinkedInJson.requiredText(body['preview_id'], 'preview_id'),
      simulationId:
          LinkedInJson.requiredText(body['simulation_id'], 'simulation_id'),
      text: LinkedInJson.requiredText(body['text'], 'text'),
      contentSha256:
          LinkedInJson.requiredText(body['content_sha256'], 'content_sha256'),
      expiresAt: LinkedInJson.date(body['expires_at']),
    );
  }
}
