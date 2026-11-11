part of 'interview_cubit.dart';

enum InterviewPhase {
  setup,
  starting,
  startFailed,
  inProgress,
  submitting,
  finishing,
  finished,
}

class InterviewState extends Equatable {
  final InterviewPhase phase;
  final bool cvChecked;
  final String? cvId;
  final List<String> cvJobTitles;
  final Failure? cvLoadFailure;
  final String? failedSimulationId;
  final String? simulationId;
  final List<InterviewQuestion> questions;
  final int currentIndex;
  final Map<String, AnswerEvaluation> evaluations;
  final Map<String, String> submittedAnswers;
  final InterviewFinishResult? finishResult;
  final InterviewReport? report;
  final bool reportLoading;
  final Failure? reportFailure;
  final Failure? error;
  final List<InterviewSimulationHistory>? history;

  /// Interview language sent to the start endpoint (`English` or `Arabic`).
  final String? language;

  const InterviewState({
    this.phase = InterviewPhase.setup,
    this.cvChecked = false,
    this.cvId,
    this.cvJobTitles = const [],
    this.cvLoadFailure,
    this.failedSimulationId,
    this.simulationId,
    this.questions = const [],
    this.currentIndex = 0,
    this.evaluations = const {},
    this.submittedAnswers = const {},
    this.finishResult,
    this.report,
    this.reportLoading = false,
    this.reportFailure,
    this.error,
    this.history,
    this.language,
  });

  InterviewQuestion? get currentQuestion {
    if (currentIndex < 0 || currentIndex >= questions.length) return null;
    return questions[currentIndex];
  }

  bool get isLastQuestion =>
      questions.isNotEmpty && currentIndex >= questions.length - 1;

  /// `ar` or `en` for the interview language, or null when unknown.
  String? get languageCode => switch (language) {
        'Arabic' => 'ar',
        'English' => 'en',
        _ => null,
      };

  bool get requestInFlight =>
      phase == InterviewPhase.starting ||
      phase == InterviewPhase.submitting ||
      phase == InterviewPhase.finishing ||
      reportLoading;

  InterviewState copyWith({
    InterviewPhase? phase,
    bool? cvChecked,
    String? cvId,
    bool clearCvId = false,
    List<String>? cvJobTitles,
    Failure? cvLoadFailure,
    bool clearCvLoadFailure = false,
    String? failedSimulationId,
    bool clearFailedSimulationId = false,
    String? simulationId,
    List<InterviewQuestion>? questions,
    int? currentIndex,
    Map<String, AnswerEvaluation>? evaluations,
    Map<String, String>? submittedAnswers,
    InterviewFinishResult? finishResult,
    bool clearFinish = false,
    InterviewReport? report,
    bool clearReport = false,
    bool? reportLoading,
    Failure? reportFailure,
    bool clearReportFailure = false,
    Failure? error,
    bool clearError = false,
    List<InterviewSimulationHistory>? history,
    String? language,
  }) {
    return InterviewState(
      phase: phase ?? this.phase,
      cvChecked: cvChecked ?? this.cvChecked,
      cvId: clearCvId ? null : (cvId ?? this.cvId),
      cvJobTitles: cvJobTitles ?? this.cvJobTitles,
      cvLoadFailure:
          clearCvLoadFailure ? null : (cvLoadFailure ?? this.cvLoadFailure),
      failedSimulationId: clearFailedSimulationId
          ? null
          : (failedSimulationId ?? this.failedSimulationId),
      simulationId: simulationId ?? this.simulationId,
      questions: questions ?? this.questions,
      currentIndex: currentIndex ?? this.currentIndex,
      evaluations: evaluations ?? this.evaluations,
      submittedAnswers: submittedAnswers ?? this.submittedAnswers,
      finishResult: clearFinish ? null : (finishResult ?? this.finishResult),
      report: clearReport ? null : (report ?? this.report),
      reportLoading: reportLoading ?? this.reportLoading,
      reportFailure:
          clearReportFailure ? null : (reportFailure ?? this.reportFailure),
      error: clearError ? null : (error ?? this.error),
      history: history ?? this.history,
      language: language ?? this.language,
    );
  }

  @override
  List<Object?> get props => [
        phase,
        cvChecked,
        cvId,
        cvJobTitles,
        cvLoadFailure,
        failedSimulationId,
        simulationId,
        questions,
        currentIndex,
        evaluations,
        submittedAnswers,
        finishResult,
        report,
        reportLoading,
        reportFailure,
        error,
        history,
        language,
      ];
}
