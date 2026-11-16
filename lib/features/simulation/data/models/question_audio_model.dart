import '../../domain/entities/question_audio.dart';
import 'interview_json.dart';

class QuestionAudioModel extends QuestionAudio {
  const QuestionAudioModel({
    required super.questionId,
    required super.status,
    super.audioUrl,
    super.mimeType,
    super.durationMs,
    super.expiresInSeconds,
  });

  factory QuestionAudioModel.fromJson(Map<String, dynamic> json) {
    final status = QuestionAudioStatus.parse(json['status']);
    if (status == null) {
      throw const FormatException('Invalid question audio status');
    }
    final questionId = requiredString(json['question_id']);
    if (questionId.isEmpty) {
      throw const FormatException('Missing question id');
    }
    final audioUrl = optionalString(json['audio_url']);
    final mimeType = optionalString(json['mime_type']);
    if (status == QuestionAudioStatus.ready) {
      if (audioUrl == null || audioUrl.trim().isEmpty) {
        throw const FormatException('Missing audio url');
      }
      if (!supportedWavMime(mimeType)) {
        throw const FormatException('Unsupported audio type');
      }
    }
    return QuestionAudioModel(
      questionId: questionId,
      status: status,
      audioUrl: audioUrl,
      mimeType: mimeType,
      durationMs: optionalInt(json['duration_ms']),
      expiresInSeconds: optionalInt(json['expires_in_seconds']),
    );
  }
}

/// WAV payloads the backend generates. Parameters after ';' are ignored.
bool supportedWavMime(String? mime) {
  if (mime == null || mime.trim().isEmpty) return false;
  final base = mime.split(';').first.trim().toLowerCase();
  return base == 'audio/wav' || base == 'audio/x-wav' || base == 'audio/wave';
}

/// Parses the optional `audio` object on a question. Invalid data becomes null.
QuestionAudioHint? questionAudioHintFromJson(Object? value) {
  if (value is! Map) return null;
  final status = QuestionAudioStatus.parse(value['status']);
  if (status == null) return null;
  return QuestionAudioHint(
    status: status,
    url: optionalString(value['url']),
    mimeType: optionalString(value['mime_type']),
    durationMs: optionalInt(value['duration_ms']),
  );
}
