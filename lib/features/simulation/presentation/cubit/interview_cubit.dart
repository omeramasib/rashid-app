import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/ads/ads_log.dart';
import '../../../../core/ads/app_foreground.dart';
import '../../../../core/ads/interview_ad_gate.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../cv/domain/entities/cv_profile.dart';
import '../../../cv/domain/usecases/get_my_cv_profile_usecase.dart';
import '../../domain/entities/answer_evaluation.dart';
import '../../domain/entities/interview_finish_result.dart';
import '../../domain/entities/interview_question.dart';
import '../../domain/entities/interview_report.dart';
import '../../domain/entities/interview_simulation_history.dart';
import '../../domain/entities/interview_start_response.dart';
import '../../domain/failures/interview_start_failure.dart';
import '../../domain/interview_options.dart';
import '../../domain/usecases/finish_interview_usecase.dart';
import '../../domain/usecases/get_interview_report_usecase.dart';
import '../../domain/usecases/get_simulations_history_usecase.dart';
import '../../domain/usecases/retry_interview_generation_usecase.dart';
import '../../domain/usecases/start_interview_by_job_description_usecase.dart';
import '../../domain/usecases/start_interview_by_job_usecase.dart';
import '../../domain/usecases/submit_answer_usecase.dart';

part 'interview_state.dart';

/// Trims titles, drops blanks, and keeps the first copy of each remaining title.
List<String> normalizeCvJobTitles(List<String> titles) {
  final seen = <String>{};
  final unique = <String>[];
  for (final title in titles) {
    final trimmed = title.trim();
    if (trimmed.isEmpty || !seen.add(trimmed)) continue;
    unique.add(trimmed);
  }
  return unique;
}

class InterviewCubit extends Cubit<InterviewState> {
  final StartInterviewByJobUseCase startInterviewByJobUseCase;
  final StartInterviewByJobDescriptionUseCase
      startInterviewByJobDescriptionUseCase;
  final RetryInterviewGenerationUseCase retryInterviewGenerationUseCase;
  final SubmitAnswerUseCase submitAnswerUseCase;
  final FinishInterviewUseCase finishInterviewUseCase;
  final GetInterviewReportUseCase getInterviewReportUseCase;
  final GetSimulationsHistoryUseCase getSimulationsHistoryUseCase;
  final GetMyCvProfileUseCase getMyCvProfileUseCase;
  final InterviewAdGate? adGate;

  final AppForegroundSignal _foreground;
  Future<void>? _cvLoad;
  bool _busyLock = false;
  bool _abandonStart = false;
  Completer<void>? _untilResumed;

  InterviewCubit({
    required this.startInterviewByJobUseCase,
    required this.startInterviewByJobDescriptionUseCase,
    required this.retryInterviewGenerationUseCase,
    required this.submitAnswerUseCase,
    required this.finishInterviewUseCase,
    required this.getInterviewReportUseCase,
    required this.getSimulationsHistoryUseCase,
    required this.getMyCvProfileUseCase,
    this.adGate,
    AppForegroundSignal? foreground,
  })  : _foreground = foreground ?? const AlwaysResumedForeground(),
        super(const InterviewState());

  /// Preloads the start interstitial while the setup screen is open.
  ///
  /// Failures are ignored. The interview never waits on this.
  void preloadAd() {
    final gate = adGate;
    if (gate == null) return;
    unawaited(gate.preload());
  }

  Future<void> loadCv() {
    return _cvLoad ??= _loadCv();
  }

  /// Uses a profile the interview gate already loaded.
  ///
  /// Later [loadCv] calls do not send another GET /cv/me.
  void adoptProcessedProfile(CvProfile profile) {
    if (_cvLoad != null) return;
    _cvLoad = Future<void>.value();
    _applyCvProfile(profile);
  }

  Future<void> retryLoadCv() {
    if (state.cvLoadFailure == null || _locked) return Future<void>.value();
    _cvLoad = null;
    emit(state.copyWith(
      cvChecked: false,
      clearCvId: true,
      cvJobTitles: const [],
      clearCvLoadFailure: true,
    ));
    return loadCv();
  }

  Future<void> _loadCv() async {
    final result = await getMyCvProfileUseCase(NoParams());
    if (isClosed) return;
    result.fold(_failCvLoad, _applyCvProfile);
  }

  void _failCvLoad(Failure failure) {
    emit(state.copyWith(
      cvChecked: true,
      clearCvId: true,
      cvJobTitles: const [],
      cvLoadFailure: failure,
    ));
  }

  void _applyCvProfile(CvProfile? profile) {
    if (profile == null || profile.status != CvAnalysisStatus.processed) {
      emit(state.copyWith(
        cvChecked: true,
        clearCvId: true,
        cvJobTitles: const [],
        clearCvLoadFailure: true,
      ));
      return;
    }
    emit(state.copyWith(
      cvChecked: true,
      cvId: profile.cvId,
      cvJobTitles: normalizeCvJobTitles(profile.jobTitles),
      clearCvLoadFailure: true,
    ));
  }

  bool get _locked => _busyLock || state.requestInFlight;

  Future<void> start({
    required InterviewStartMode mode,
    required String input,
    required String interviewType,
    required String difficulty,
    required String language,
    required int numQuestions,
  }) async {
    if (_locked) return;
    final collapsed = collapseInterviewWhitespace(input);
    if (!_settingsAreValid(
      mode: mode,
      input: collapsed,
      interviewType: interviewType,
      difficulty: difficulty,
      language: language,
      numQuestions: numQuestions,
    )) {
      return;
    }
    _busyLock = true;
    try {
      await loadCv();
      if (isClosed || _abandonStart || state.requestInFlight) return;
      try {
        await adGate?.showIfEligible();
      } catch (_) {
        adsLog('ad gate failed');
      }
      if (isClosed || _abandonStart) return;
      await _waitUntilResumed();
      if (isClosed || _abandonStart) return;
      emit(state.copyWith(
        phase: InterviewPhase.starting,
        language: language,
        clearError: true,
      ));
      final result = mode == InterviewStartMode.byJob
          ? await startInterviewByJobUseCase(StartInterviewByJobParams(
              jobField: collapsed,
              interviewType: interviewType,
              difficulty: difficulty,
              language: language,
              simulationType: InterviewOptions.simulationType,
              numQuestions: numQuestions,
              cvId: state.cvId,
            ))
          : await startInterviewByJobDescriptionUseCase(
              StartInterviewByJobDescriptionParams(
                jobDescription: collapsed,
                interviewType: interviewType,
                difficulty: difficulty,
                language: language,
                simulationType: InterviewOptions.simulationType,
                numQuestions: numQuestions,
                cvId: state.cvId,
              ),
            );
      if (isClosed || _abandonStart) return;
      result.fold(_failStart, _beginSession);
    } finally {
      _busyLock = false;
    }
  }

  Future<void> retryStart() async {
    final simulationId = state.failedSimulationId;
    if (simulationId == null || simulationId.isEmpty || _locked) return;
    _busyLock = true;
    try {
      emit(state.copyWith(phase: InterviewPhase.starting, clearError: true));
      final result = await retryInterviewGenerationUseCase(
        RetryInterviewGenerationParams(simulationId: simulationId),
      );
      if (isClosed) return;
      result.fold(_failStart, _beginSession);
    } finally {
      _busyLock = false;
    }
  }

  Future<void> submit(String text) async {
    if (_locked) return;
    final question = state.currentQuestion;
    if (question == null || state.evaluations.containsKey(question.id)) return;
    final answer = text.trim();
    if (answer.isEmpty || answer.length > InterviewOptions.maxAnswerLength) {
      return;
    }
    _busyLock = true;
    try {
      await _sendAnswer(question.id, skipped: false, answerText: answer);
    } finally {
      _busyLock = false;
    }
  }

  Future<void> skip() async {
    if (_locked) return;
    final question = state.currentQuestion;
    if (question == null || state.evaluations.containsKey(question.id)) return;
    _busyLock = true;
    try {
      await _sendAnswer(question.id, skipped: true);
    } finally {
      _busyLock = false;
    }
  }

  void next() {
    if (_locked || state.questions.isEmpty) return;
    if (state.phase != InterviewPhase.inProgress) return;
    if (state.isLastQuestion) {
      finish();
      return;
    }
    emit(state.copyWith(
      currentIndex: state.currentIndex + 1,
      clearError: true,
    ));
  }

  void previous() {
    if (_locked || state.currentIndex <= 0) return;
    emit(state.copyWith(
      currentIndex: state.currentIndex - 1,
      clearError: true,
    ));
  }

  Future<void> finish() async {
    if (_locked || state.phase == InterviewPhase.finished) return;
    final simulationId = state.simulationId;
    if (simulationId == null || simulationId.isEmpty) return;
    _busyLock = true;
    try {
      emit(state.copyWith(phase: InterviewPhase.finishing, clearError: true));
      final result = await finishInterviewUseCase(
        FinishInterviewParams(simulationId: simulationId),
      );
      if (isClosed || _abandonStart) return;
      await result.fold((failure) async {
        emit(state.copyWith(phase: InterviewPhase.inProgress, error: failure));
      }, (finishResult) async {
        try {
          await adGate?.showIfEligible(AdPlacement.interviewFinish);
        } catch (_) {
          adsLog('finish ad gate failed');
        }
        if (isClosed || _abandonStart) return;
        await _waitUntilResumed();
        if (isClosed || _abandonStart) return;
        emit(state.copyWith(
          phase: InterviewPhase.finished,
          finishResult: finishResult,
          reportLoading: true,
          clearReport: true,
          clearReportFailure: true,
          clearError: true,
        ));
        await _loadReport(simulationId);
      });
    } finally {
      _busyLock = false;
    }
  }

  Future<void> loadReport() async {
    if (state.phase != InterviewPhase.finished || _locked) return;
    final simulationId = state.finishResult?.simulationId ?? state.simulationId;
    if (simulationId == null || simulationId.isEmpty) return;
    _busyLock = true;
    try {
      final seedSummary = state.finishResult == null;
      emit(state.copyWith(reportLoading: true, clearReportFailure: true));
      await _loadReport(simulationId, seedSummary: seedSummary);
    } finally {
      _busyLock = false;
    }
  }

  /// Opens an already completed interview on the existing result screen.
  ///
  /// The finish endpoint is not called. A successful report fills [finishResult]
  /// only when the cubit does not already have one.
  Future<void> openCompletedReport(String simulationId) async {
    if (simulationId.isEmpty || _locked) return;
    _busyLock = true;
    try {
      emit(state.copyWith(
        phase: InterviewPhase.finished,
        simulationId: simulationId,
        reportLoading: true,
        clearFinish: true,
        clearReport: true,
        clearReportFailure: true,
        clearError: true,
      ));
      await _loadReport(simulationId, seedSummary: true);
    } finally {
      _busyLock = false;
    }
  }

  void clearError() {
    if (state.error == null) return;
    emit(state.copyWith(clearError: true));
  }

  void prepareAnother() {
    emit(InterviewState(
      cvChecked: state.cvChecked,
      cvId: state.cvId,
      cvJobTitles: state.cvJobTitles,
      cvLoadFailure: state.cvLoadFailure,
    ));
  }

  Future<void> getHistory() async {
    if (_locked) return;
    _busyLock = true;
    try {
      final result = await getSimulationsHistoryUseCase(NoParams());
      if (isClosed) return;
      result.fold(
        (failure) => emit(state.copyWith(error: failure)),
        (history) => emit(state.copyWith(history: history, clearError: true)),
      );
    } finally {
      _busyLock = false;
    }
  }

  Future<void> _sendAnswer(
    String questionId, {
    required bool skipped,
    String? answerText,
  }) async {
    emit(state.copyWith(phase: InterviewPhase.submitting, clearError: true));
    final result = await submitAnswerUseCase(SubmitAnswerParams(
      questionId: questionId,
      skipped: skipped,
      answerText: answerText,
    ));
    if (isClosed) return;
    result.fold(
      (failure) => emit(state.copyWith(
        phase: InterviewPhase.inProgress,
        error: failure,
      )),
      (evaluation) {
        final evaluations =
            Map<String, AnswerEvaluation>.from(state.evaluations);
        evaluations[questionId] = evaluation;
        final answers = Map<String, String>.from(state.submittedAnswers);
        if (!skipped && answerText != null) {
          answers[questionId] = answerText;
        }
        emit(state.copyWith(
          phase: InterviewPhase.inProgress,
          evaluations: evaluations,
          submittedAnswers: answers,
          clearError: true,
        ));
      },
    );
  }

  Future<void> _loadReport(
    String simulationId, {
    bool seedSummary = false,
  }) async {
    final result = await getInterviewReportUseCase(
      GetInterviewReportParams(simulationId: simulationId),
    );
    if (isClosed) return;
    result.fold(
      (failure) => emit(state.copyWith(
        reportLoading: false,
        reportFailure: failure,
      )),
      (report) {
        final seeded = seedSummary && state.finishResult == null
            ? _finishResultFromReport(report)
            : null;
        emit(state.copyWith(
          reportLoading: false,
          report: report,
          clearReportFailure: true,
          finishResult: seeded,
        ));
      },
    );
  }

  void _failStart(Failure failure) {
    final startFailure = failure is InterviewStartFailure ? failure : null;
    final simulationId = startFailure?.simulationId;
    emit(state.copyWith(
      phase: InterviewPhase.startFailed,
      error: startFailure?.cause ?? failure,
      failedSimulationId: simulationId,
      clearFailedSimulationId: simulationId == null || simulationId.isEmpty,
    ));
  }

  void _beginSession(InterviewStartResponse response) {
    emit(state.copyWith(
      phase: InterviewPhase.inProgress,
      simulationId: response.simulationId,
      questions: response.questions,
      currentIndex: 0,
      evaluations: const {},
      submittedAnswers: const {},
      clearError: true,
      clearFailedSimulationId: true,
      clearFinish: true,
      clearReport: true,
      clearReportFailure: true,
      reportLoading: false,
    ));
    final gate = adGate;
    if (gate != null) {
      unawaited(gate.preload(AdPlacement.interviewFinish));
    }
  }

  Future<void> _waitUntilResumed() {
    if (_abandonStart || isClosed || _foreground.isResumed) {
      return Future<void>.value();
    }
    final completer = Completer<void>();
    _untilResumed = completer;
    void listener() {
      if (!_foreground.isResumed || completer.isCompleted) return;
      _foreground.removeListener(listener);
      completer.complete();
    }

    _foreground.addListener(listener);
    return completer.future.whenComplete(() {
      _foreground.removeListener(listener);
      if (identical(_untilResumed, completer)) _untilResumed = null;
    });
  }

  @override
  Future<void> close() {
    _abandonStart = true;
    final pending = _untilResumed;
    if (pending != null && !pending.isCompleted) {
      pending.complete();
    }
    return super.close();
  }

  InterviewFinishResult _finishResultFromReport(InterviewReport report) {
    final answered = report.answeredQuestions;
    final skipped = report.skippedQuestions;
    final unanswered = report.unansweredQuestions;
    final int? totalQuestions;
    if (report.questions.isNotEmpty) {
      totalQuestions = report.questions.length;
    } else if (answered != null && skipped != null && unanswered != null) {
      totalQuestions = answered + skipped + unanswered;
    } else {
      totalQuestions = null;
    }
    return InterviewFinishResult(
      simulationId: report.simulationId,
      score: report.score,
      performanceStatus: report.performanceStatus,
      totalQuestions: totalQuestions,
      answeredQuestions: answered,
      skippedQuestions: skipped,
      unansweredQuestions: unanswered,
      status: report.status,
      reportStatus: report.reportStatus,
      reportSummary: report.reportSummary,
    );
  }

  bool _settingsAreValid({
    required InterviewStartMode mode,
    required String input,
    required String interviewType,
    required String difficulty,
    required String language,
    required int numQuestions,
  }) {
    final lengthOk = mode == InterviewStartMode.byJob
        ? input.length >= InterviewOptions.minJobFieldLength &&
            input.length <= InterviewOptions.maxJobFieldLength
        : input.length >= InterviewOptions.minJobDescriptionLength &&
            input.length <= InterviewOptions.maxJobDescriptionLength;
    return lengthOk &&
        InterviewOptions.types.contains(interviewType) &&
        InterviewOptions.difficulties.contains(difficulty) &&
        InterviewOptions.languages.contains(language) &&
        numQuestions >= InterviewOptions.minQuestions &&
        numQuestions <= InterviewOptions.maxQuestions;
  }
}
