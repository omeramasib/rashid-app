import '../../domain/entities/share_result.dart';

class ShareResultModel extends ShareResult {
  const ShareResultModel({required super.postUrl, required super.postUrn});

  factory ShareResultModel.fromJson(Map<String, dynamic> json) {
    return ShareResultModel(
      postUrl: json['post_url'] ?? '',
      postUrn: json['post_urn'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'post_url': postUrl,
      'post_urn': postUrn,
    };
  }
}
