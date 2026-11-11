import 'package:equatable/equatable.dart';

class LinkedInSharePreview extends Equatable {
  final String previewId;
  final String simulationId;
  final String text;
  final String contentSha256;
  final DateTime? expiresAt;

  const LinkedInSharePreview({
    required this.previewId,
    required this.simulationId,
    required this.text,
    required this.contentSha256,
    this.expiresAt,
  });

  @override
  List<Object?> get props => [
        previewId,
        simulationId,
        text,
        contentSha256,
        expiresAt,
      ];
}
