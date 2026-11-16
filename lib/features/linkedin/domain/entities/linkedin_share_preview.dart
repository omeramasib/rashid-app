import 'package:equatable/equatable.dart';

class LinkedInSharePreview extends Equatable {
  final String previewId;
  final String simulationId;
  final String text;
  final String contentSha256;
  final DateTime? expiresAt;
  final String? existingPostUrl;
  final bool? existingContentMatches;
  final String? existingShareId;

  const LinkedInSharePreview({
    required this.previewId,
    required this.simulationId,
    required this.text,
    required this.contentSha256,
    this.expiresAt,
    this.existingPostUrl,
    this.existingContentMatches,
    this.existingShareId,
  });

  @override
  List<Object?> get props => [
        previewId,
        simulationId,
        text,
        contentSha256,
        expiresAt,
        existingPostUrl,
        existingContentMatches,
        existingShareId,
      ];
}
