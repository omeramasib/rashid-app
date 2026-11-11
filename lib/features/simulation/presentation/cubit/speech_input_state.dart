part of 'speech_input_cubit.dart';

enum SpeechInputStatus {
  idle,
  requestingPermission,
  initializing,
  listening,
  processing,
  completed,
  permissionDenied,
  permissionPermanentlyDenied,
  unavailable,
  error;

  /// A session is starting, recording, or finalizing.
  bool get isActive =>
      this == requestingPermission ||
      this == initializing ||
      this == listening ||
      this == processing;
}

/// Committed text for one session. The screen appends it exactly once.
class SpeechTranscript extends Equatable {
  const SpeechTranscript({
    required this.text,
    required this.questionId,
    required this.sessionId,
  });

  final String text;
  final String questionId;
  final int sessionId;

  @override
  List<Object?> get props => [text, questionId, sessionId];
}

class SpeechInputState extends Equatable {
  const SpeechInputState({
    this.status = SpeechInputStatus.idle,
    this.questionId,
    this.partialText = '',
    this.transcript,
    this.error,
  });

  final SpeechInputStatus status;
  final String? questionId;

  /// Provisional text shown while listening. Never written to the answer.
  final String partialText;
  final SpeechTranscript? transcript;
  final SpeechErrorCategory? error;

  @override
  List<Object?> get props =>
      [status, questionId, partialText, transcript, error];
}
