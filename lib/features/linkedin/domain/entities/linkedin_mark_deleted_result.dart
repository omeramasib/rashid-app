import 'package:equatable/equatable.dart';

class LinkedInMarkDeletedResult extends Equatable {
  final String shareId;
  final String status;
  final bool canRepublish;
  final int remainingActivePosts;

  const LinkedInMarkDeletedResult({
    required this.shareId,
    required this.status,
    required this.canRepublish,
    required this.remainingActivePosts,
  });

  bool get markedDeleted => status == 'externally_deleted';

  /// A fresh preview is allowed only when the backend says this share no
  /// longer blocks publishing and no other active post remains.
  bool get allowsFreshPreview =>
      markedDeleted && canRepublish && remainingActivePosts == 0;

  @override
  List<Object?> get props =>
      [shareId, status, canRepublish, remainingActivePosts];
}
