import 'package:equatable/equatable.dart';

enum QuestionAudioStatus {
  pending,
  processing,
  ready,
  failed,
  disabled;

  static QuestionAudioStatus? parse(Object? raw) {
    if (raw is! String) return null;
    for (final status in values) {
      if (status.name == raw) return status;
    }
    return null;
  }
}

/// Speech metadata returned by the question-audio endpoint.
class QuestionAudio extends Equatable {
  const QuestionAudio({
    required this.questionId,
    required this.status,
    this.audioUrl,
    this.mimeType,
    this.durationMs,
    this.expiresInSeconds,
  });

  final String questionId;
  final QuestionAudioStatus status;
  final String? audioUrl;
  final String? mimeType;
  final int? durationMs;
  final int? expiresInSeconds;

  @override
  List<Object?> get props => [
        questionId,
        status,
        audioUrl,
        mimeType,
        durationMs,
        expiresInSeconds,
      ];
}

/// Optional audio block embedded in an interview question.
///
/// Older start responses omit it. A missing or unrecognized block stays null
/// so question text still loads.
class QuestionAudioHint extends Equatable {
  const QuestionAudioHint({
    required this.status,
    this.url,
    this.mimeType,
    this.durationMs,
  });

  final QuestionAudioStatus status;
  final String? url;
  final String? mimeType;
  final int? durationMs;

  @override
  List<Object?> get props => [status, url, mimeType, durationMs];
}
