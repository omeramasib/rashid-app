part of 'interview_entry_cubit.dart';

enum InterviewEntryPhase { checking, ready, needsProfile, failed, unauthorized }

class InterviewEntryState extends Equatable {
  const InterviewEntryState._({
    required this.phase,
    this.profile,
    this.failure,
  });

  const InterviewEntryState.checking()
      : this._(phase: InterviewEntryPhase.checking);

  const InterviewEntryState.ready(CvProfile profile)
      : this._(phase: InterviewEntryPhase.ready, profile: profile);

  const InterviewEntryState.needsProfile()
      : this._(phase: InterviewEntryPhase.needsProfile);

  const InterviewEntryState.failed(Failure failure)
      : this._(phase: InterviewEntryPhase.failed, failure: failure);

  const InterviewEntryState.unauthorized(Failure failure)
      : this._(phase: InterviewEntryPhase.unauthorized, failure: failure);

  final InterviewEntryPhase phase;
  final CvProfile? profile;
  final Failure? failure;

  @override
  List<Object?> get props => [phase, profile, failure];
}
