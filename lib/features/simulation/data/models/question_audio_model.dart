import 'dart:typed_data';

import '../../domain/entities/question_audio.dart';
import 'interview_json.dart';

/// Largest WAV this client will store. Longer payloads are rejected.
const int maxQuestionAudioBytes = 8 * 1024 * 1024;

/// WAV payloads the backend generates. Parameters after ';' are ignored.
bool supportedWavMime(String? mime) {
  if (mime == null || mime.trim().isEmpty) return false;
  final base = mime.split(';').first.trim().toLowerCase();
  return base == 'audio/wav' || base == 'audio/x-wav' || base == 'audio/wave';
}

/// A playable PCM WAV: RIFF/WAVE, a `fmt ` chunk, and a non-empty `data` chunk.
///
/// A content type is checked only when the caller has one. Cached files are
/// checked from their bytes alone.
bool isPlayableWav(Uint8List bytes, {String? contentType}) {
  if (contentType != null &&
      contentType.trim().isNotEmpty &&
      !supportedWavMime(contentType)) {
    return false;
  }
  if (bytes.length < 44 || bytes.length > maxQuestionAudioBytes) return false;
  if (!_ascii(bytes, 0, 'RIFF') || !_ascii(bytes, 8, 'WAVE')) return false;
  var offset = 12;
  var fmt = false;
  var data = false;
  while (offset + 8 <= bytes.length) {
    final id = String.fromCharCodes(bytes.sublist(offset, offset + 4));
    final size = ByteData.sublistView(bytes, offset + 4, offset + 8)
        .getUint32(0, Endian.little);
    if (id == 'fmt ' && size >= 16) fmt = true;
    if (id == 'data' && size > 0 && offset + 8 + size <= bytes.length) {
      data = true;
    }
    final next = offset + 8 + size + (size.isOdd ? 1 : 0);
    if (next <= offset || next > bytes.length + 1) return fmt && data;
    if (next == offset) return false;
    offset = next;
  }
  return fmt && data;
}

bool _ascii(Uint8List bytes, int offset, String text) {
  if (offset + text.length > bytes.length) return false;
  for (var i = 0; i < text.length; i++) {
    if (bytes[offset + i] != text.codeUnitAt(i)) return false;
  }
  return true;
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
