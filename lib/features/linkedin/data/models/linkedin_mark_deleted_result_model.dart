import '../../domain/entities/linkedin_mark_deleted_result.dart';
import 'linkedin_connection_status_model.dart';

class LinkedInMarkDeletedResultModel extends LinkedInMarkDeletedResult {
  const LinkedInMarkDeletedResultModel({
    required super.shareId,
    required super.status,
    required super.canRepublish,
    required super.remainingActivePosts,
  });

  factory LinkedInMarkDeletedResultModel.fromJson(dynamic json) {
    final body = LinkedInJson.objectBody(json);
    final remaining = body['remaining_active_posts'];
    return LinkedInMarkDeletedResultModel(
      shareId: LinkedInJson.requiredText(body['share_id'], 'share_id'),
      status: LinkedInJson.requiredText(body['status'], 'status'),
      canRepublish: body['can_republish'] == true,
      remainingActivePosts: remaining is int
          ? remaining
          : remaining is num
              ? remaining.toInt()
              : 0,
    );
  }
}
