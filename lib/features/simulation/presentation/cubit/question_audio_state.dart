part of 'question_audio_cubit.dart';

enum QuestionPlaybackStatus {
  idle,
  loading,
  ready,
  playing,
  paused,
  completed,
  error,
}

/// Local problem distinct from the backend generation status.
///
/// [sessionExpired] is an authentication failure. It is not an audio-generation
/// result and must not be presented as one.
enum QuestionAudioIssue {
  none,
  timedOut,
  temporary,
  unavailable,
  sessionExpired,

  /// HTTP 429. Rate limit and spending limit are not distinguishable.
  limited,
}

class QuestionAudioState extends Equatable {
  const QuestionAudioState({
    this.questionId,
    this.backend,
    this.playback = QuestionPlaybackStatus.idle,
    this.issue = QuestionAudioIssue.none,
    this.deferred = false,
    this.retryLocked = false,
  });

  final String? questionId;
  final QuestionAudioStatus? backend;
  final QuestionPlaybackStatus playback;
  final QuestionAudioIssue issue;

  /// An answered question has not requested audio yet.
  final bool deferred;

  /// A 429 `Retry-After` window is still open. No request is sent.
  final bool retryLocked;

  QuestionAudioState copyWith({
    QuestionAudioStatus? backend,
    QuestionPlaybackStatus? playback,
    QuestionAudioIssue? issue,
    bool? deferred,
    bool? retryLocked,
    bool clearBackend = false,
  }) {
    return QuestionAudioState(
      questionId: questionId,
      backend: clearBackend ? null : (backend ?? this.backend),
      playback: playback ?? this.playback,
      issue: issue ?? this.issue,
      deferred: deferred ?? this.deferred,
      retryLocked: retryLocked ?? this.retryLocked,
    );
  }

  @override
  List<Object?> get props =>
      [questionId, backend, playback, issue, deferred, retryLocked];
}
