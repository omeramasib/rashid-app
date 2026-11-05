import '../../domain/entities/linkedin_publish_result.dart';
import 'linkedin_connection_status_model.dart';

class LinkedInPublishResultModel extends LinkedInPublishResult {
  const LinkedInPublishResultModel({super.postUrl});

  factory LinkedInPublishResultModel.fromJson(dynamic json) {
    if (json == null) return const LinkedInPublishResultModel();
    final body = LinkedInJson.objectBody(json);
    return LinkedInPublishResultModel(
        postUrl: LinkedInJson.text(body['post_url']));
  }
}
