part of 'interview_cubit.dart';

abstract class InterviewState extends Equatable {
  const InterviewState();

  @override
  List<Object?> get props => [];
}

class InterviewInitial extends InterviewState {}

class InterviewStarting extends InterviewState {}

class InterviewInProgress extends InterviewState {
  final String simulationId;
  final List<InterviewQuestion> questions;
  final int currentIndex;

  const InterviewInProgress({
    required this.simulationId,
    required this.questions,
    required this.currentIndex,
  });

  @override
  List<Object?> get props => [simulationId, questions, currentIndex];
}

class AnswerSubmitting extends InterviewState {
  final String simulationId;
  final List<InterviewQuestion> questions;
  final int currentIndex;

  const AnswerSubmitting({
    required this.simulationId,
    required this.questions,
    required this.currentIndex,
  });

  @override
  List<Object?> get props => [simulationId, questions, currentIndex];
}

class InterviewFinishing extends InterviewState {}

class InterviewFinished extends InterviewState {
  final InterviewReport report;

  const InterviewFinished(this.report);

  @override
  List<Object?> get props => [report];
}

class InterviewHistoryLoading extends InterviewState {}

class InterviewHistoryLoaded extends InterviewState {
  final List<InterviewSimulationHistory> history;

  const InterviewHistoryLoaded(this.history);

  @override
  List<Object?> get props => [history];
}

class InterviewError extends InterviewState {
  final String message;

  const InterviewError(this.message);

  @override
  List<Object?> get props => [message];
}
