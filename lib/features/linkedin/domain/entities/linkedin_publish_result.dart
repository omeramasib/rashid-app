import 'package:equatable/equatable.dart';

class LinkedInPublishResult extends Equatable {
  final String? postUrl;
  final bool alreadyPublished;
  final String? shareId;

  const LinkedInPublishResult({
    this.postUrl,
    this.alreadyPublished = false,
    this.shareId,
  });

  @override
  List<Object?> get props => [postUrl, alreadyPublished, shareId];
}
