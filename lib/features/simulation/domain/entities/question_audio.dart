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

/// Where a playable file came from for this activation.
enum QuestionAudioSource { cold, cache, prefetch }

/// A validated WAV already stored on disk.
class QuestionAudioFile extends Equatable {
  const QuestionAudioFile({
    required this.questionId,
    required this.filePath,
    required this.bytes,
    required this.source,
    this.httpMs = 0,
    this.cacheWriteMs = 0,
  });

  final String questionId;
  final String filePath;
  final int bytes;
  final QuestionAudioSource source;
  final int httpMs;
  final int cacheWriteMs;

  @override
  List<Object?> get props =>
      [questionId, filePath, bytes, source, httpMs, cacheWriteMs];
}

/// Optional audio block embedded in an interview question.
///
/// Older start responses omit it. A missing or unrecognized block stays null
/// so question text still loads. Direct audio honors only
/// [QuestionAudioStatus.disabled].
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
