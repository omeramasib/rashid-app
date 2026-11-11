import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rashed_app/core/ads/app_foreground.dart';
import 'package:rashed_app/core/ads/interview_ad_gate.dart';
import 'package:rashed_app/core/error/failures.dart';
import 'package:rashed_app/core/usecases/usecase.dart';
import 'package:rashed_app/features/cv/domain/entities/cv_profile.dart';
import 'package:rashed_app/features/cv/domain/usecases/get_my_cv_profile_usecase.dart';
import 'package:rashed_app/features/simulation/domain/entities/answer_evaluation.dart';
import 'package:rashed_app/features/simulation/domain/entities/interview_finish_result.dart';
import 'package:rashed_app/features/simulation/domain/entities/interview_question.dart';
import 'package:rashed_app/features/simulation/domain/entities/interview_report.dart';
import 'package:rashed_app/features/simulation/domain/entities/interview_start_response.dart';
import 'package:rashed_app/features/simulation/domain/failures/interview_start_failure.dart';
import 'package:rashed_app/features/simulation/domain/interview_options.dart';
import 'package:rashed_app/features/simulation/domain/usecases/finish_interview_usecase.dart';
import 'package:rashed_app/features/simulation/domain/usecases/get_interview_report_usecase.dart';
import 'package:rashed_app/features/simulation/domain/usecases/get_simulations_history_usecase.dart';
import 'package:rashed_app/features/simulation/domain/usecases/retry_interview_generation_usecase.dart';
import 'package:rashed_app/features/simulation/domain/usecases/start_interview_by_job_description_usecase.dart';
import 'package:rashed_app/features/simulation/domain/usecases/start_interview_by_job_usecase.dart';
import 'package:rashed_app/features/simulation/domain/usecases/submit_answer_usecase.dart';
import 'package:rashed_app/features/simulation/presentation/cubit/interview_cubit.dart';

class MockStartByJob extends Mock implements StartInterviewByJobUseCase {}

class MockStartByDescription extends Mock
    implements StartInterviewByJobDescriptionUseCase {}

class MockRetry extends Mock implements RetryInterviewGenerationUseCase {}

class MockSubmit extends Mock implements SubmitAnswerUseCase {}

class MockFinish extends Mock implements FinishInterviewUseCase {}

class MockReport extends Mock implements GetInterviewReportUseCase {}

class MockHistory extends Mock implements GetSimulationsHistoryUseCase {}

class MockProfile extends Mock implements GetMyCvProfileUseCase {}

class ScriptedAdGate implements InterviewAdGate {
  ScriptedAdGate({this.show, this.finishShow, this.finishError});

  final Completer<void>? show;
  final Completer<void>? finishShow;
  final Object? finishError;
  int preloads = 0;
  int shows = 0;
  final List<AdPlacement> placementsShown = <AdPlacement>[];
  final List<AdPlacement> placementsPreloaded = <AdPlacement>[];

  @override
  Future<void> preload([
    AdPlacement placement = AdPlacement.interviewStart,
  ]) async {
    preloads += 1;
    placementsPreloaded.add(placement);
  }

  @override
  Future<void> showIfEligible([
    AdPlacement placement = AdPlacement.interviewStart,
  ]) {
    shows += 1;
    placementsShown.add(placement);
    if (placement == AdPlacement.interviewFinish && finishError != null) {
      return Future<void>.error(finishError!);
    }
    final pending =
        placement == AdPlacement.interviewFinish ? finishShow : show;
    return pending?.future ?? Future<void>.value();
  }
}

class ControllableForeground implements AppForegroundSignal {
  ControllableForeground({this.resumed = true});

  bool resumed;
  final List<VoidCallback> _listeners = <VoidCallback>[];

  @override
  bool get isResumed => resumed;

  @override
  void addListener(VoidCallback listener) => _listeners.add(listener);

  @override
  void removeListener(VoidCallback listener) => _listeners.remove(listener);

  void setResumed(bool value) {
    resumed = value;
    for (final listener in List<VoidCallback>.of(_listeners)) {
      listener();
    }
  }
}

void main() {
  const question = InterviewQuestion(
    id: 'q-1',
    questionText: 'Tell me about a project.',
    category: 'technical',
    position: 1,
  );
  const second = InterviewQuestion(
    id: 'q-2',
    questionText: 'How do you handle feedback?',
    position: 2,
  );
  const started = InterviewStartResponse(
    simulationId: 'sim-1',
    interviewSettingId: 'setting-1',
    status: 'ready',
    reportStatus: 'pending',
    questions: [question, second],
  );
  const evaluation = AnswerEvaluation(
    questionId: 'q-1',
    score: 70,
    strengths: ['Clear'],
    skipped: false,
  );
  const skipped = AnswerEvaluation(questionId: 'q-1', skipped: true);
  const finished = InterviewFinishResult(
    simulationId: 'sim-1',
    score: 82,
    performanceStatus: 'excellent',
    totalQuestions: 2,
    answeredQuestions: 2,
    skippedQuestions: 0,
    unansweredQuestions: 0,
    status: 'completed',
    reportStatus: 'completed',
    reportSummary: 'Strong examples.',
  );
  const report = InterviewReport(
    simulationId: 'sim-1',
    score: 82,
    performanceStatus: 'excellent',
    strengths: ['Clear'],
    questions: [],
  );

  late MockStartByJob startByJob;
  late MockStartByDescription startByDescription;
  late MockRetry retry;
  late MockSubmit submit;
  late MockFinish finish;
  late MockReport getReport;
  late MockProfile profile;

  setUpAll(() {
    registerFallbackValue(const StartInterviewByJobParams(
      jobField: 'Nurse',
      interviewType: 'technical',
      difficulty: 'medium',
      language: 'English',
      simulationType: 'text',
      numQuestions: 5,
    ));
    registerFallbackValue(const StartInterviewByJobDescriptionParams(
      jobDescription: 'A sufficiently long job description.',
      interviewType: 'technical',
      difficulty: 'medium',
      language: 'English',
      simulationType: 'text',
      numQuestions: 5,
    ));
    registerFallbackValue(
      const RetryInterviewGenerationParams(simulationId: 'sim'),
    );
    registerFallbackValue(const SubmitAnswerParams(
      questionId: 'q-1',
      skipped: false,
    ));
    registerFallbackValue(const FinishInterviewParams(simulationId: 'sim'));
    registerFallbackValue(const GetInterviewReportParams(simulationId: 'sim'));
    registerFallbackValue(NoParams());
  });

  setUp(() {
    startByJob = MockStartByJob();
    startByDescription = MockStartByDescription();
    retry = MockRetry();
    submit = MockSubmit();
    finish = MockFinish();
    getReport = MockReport();
    profile = MockProfile();
    when(() => profile(any())).thenAnswer((_) async => const Right(null));
    when(() => startByJob(any())).thenAnswer((_) async => const Right(started));
    when(() => startByDescription(any()))
        .thenAnswer((_) async => const Right(started));
    when(() => retry(any())).thenAnswer((_) async => const Right(started));
    when(() => submit(any())).thenAnswer((_) async => const Right(evaluation));
    when(() => finish(any())).thenAnswer((_) async => const Right(finished));
    when(() => getReport(any())).thenAnswer((_) async => const Right(report));
  });

  InterviewCubit build({
    InterviewAdGate? adGate,
    AppForegroundSignal? foreground,
  }) {
    return InterviewCubit(
      startInterviewByJobUseCase: startByJob,
      startInterviewByJobDescriptionUseCase: startByDescription,
      retryInterviewGenerationUseCase: retry,
      submitAnswerUseCase: submit,
      finishInterviewUseCase: finish,
      getInterviewReportUseCase: getReport,
      getSimulationsHistoryUseCase: MockHistory(),
      getMyCvProfileUseCase: profile,
      adGate: adGate,
      foreground: foreground,
    );
  }

  Future<void> startJob(InterviewCubit cubit, {String input = 'Nurse'}) {
    return cubit.start(
      mode: InterviewStartMode.byJob,
      input: input,
      interviewType: 'technical',
      difficulty: 'medium',
      language: 'English',
      numQuestions: 5,
    );
  }

  const checked = InterviewState(cvChecked: true);

  blocTest<InterviewCubit, InterviewState>(
    'starts by job without a cv id when no analyzed cv exists',
    build: build,
    act: startJob,
    expect: () => [
      checked,
      checked.copyWith(language: 'English', phase: InterviewPhase.starting),
      checked.copyWith(
        language: 'English',
        phase: InterviewPhase.inProgress,
        simulationId: 'sim-1',
        questions: started.questions,
      ),
    ],
    verify: (_) {
      final params = verify(() => startByJob(captureAny())).captured.single
          as StartInterviewByJobParams;
      expect(params.cvId, isNull);
      expect(params.jobField, 'Nurse');
      expect(params.simulationType, 'text');
      verifyNever(() => startByDescription(any()));
    },
  );

  blocTest<InterviewCubit, InterviewState>(
    'starts by job description and attaches an analyzed cv id',
    build: build,
    setUp: () {
      when(() => profile(any())).thenAnswer(
        (_) async => const Right(CvProfile(
          cvId: 'cv-1',
          status: CvAnalysisStatus.processed,
        )),
      );
    },
    act: (cubit) => cubit.start(
      mode: InterviewStartMode.byJobDescription,
      input: '  A role that needs careful clinical judgment.  ',
      interviewType: 'behavioral',
      difficulty: 'hard',
      language: 'Arabic',
      numQuestions: 3,
    ),
    expect: () => [
      checked.copyWith(cvId: 'cv-1'),
      checked.copyWith(
          cvId: 'cv-1', language: 'Arabic', phase: InterviewPhase.starting),
      checked.copyWith(
        cvId: 'cv-1',
        language: 'Arabic',
        phase: InterviewPhase.inProgress,
        simulationId: 'sim-1',
        questions: started.questions,
      ),
    ],
    verify: (_) {
      final params = verify(() => startByDescription(captureAny()))
          .captured
          .single as StartInterviewByJobDescriptionParams;
      expect(params.cvId, 'cv-1');
      expect(params.jobDescription,
          'A role that needs careful clinical judgment.');
      expect(params.numQuestions, 3);
      verifyNever(() => startByJob(any()));
    },
  );

  blocTest<InterviewCubit, InterviewState>(
    'does not attach a cv that has not been analyzed',
    build: build,
    setUp: () {
      when(() => profile(any())).thenAnswer(
        (_) async => const Right(CvProfile(
          cvId: 'cv-pending',
          status: CvAnalysisStatus.pending,
        )),
      );
    },
    act: startJob,
    verify: (_) {
      final params = verify(() => startByJob(captureAny())).captured.single
          as StartInterviewByJobParams;
      expect(params.cvId, isNull);
    },
  );

  blocTest<InterviewCubit, InterviewState>(
    'does not call the backend for a job field that is too short',
    build: build,
    act: (cubit) => startJob(cubit, input: 'N'),
    expect: () => <InterviewState>[],
    verify: (_) => verifyNever(() => startByJob(any())),
  );

  blocTest<InterviewCubit, InterviewState>(
    'retries a failed start with the returned simulation id',
    build: build,
    setUp: () {
      when(() => startByJob(any())).thenAnswer(
        (_) async => const Left(InterviewStartFailure(
          UpstreamFailure('Interview AI provider returned an invalid result'),
          simulationId: 'sim-x',
        )),
      );
    },
    act: (cubit) async {
      await startJob(cubit);
      await cubit.retryStart();
    },
    expect: () => [
      checked,
      checked.copyWith(language: 'English', phase: InterviewPhase.starting),
      checked.copyWith(
        language: 'English',
        phase: InterviewPhase.startFailed,
        failedSimulationId: 'sim-x',
        error: const UpstreamFailure(
          'Interview AI provider returned an invalid result',
        ),
      ),
      checked.copyWith(
        language: 'English',
        phase: InterviewPhase.starting,
        failedSimulationId: 'sim-x',
      ),
      checked.copyWith(
        language: 'English',
        phase: InterviewPhase.inProgress,
        simulationId: 'sim-1',
        questions: started.questions,
      ),
    ],
    verify: (_) {
      final params = verify(() => retry(captureAny())).captured.single
          as RetryInterviewGenerationParams;
      expect(params.simulationId, 'sim-x');
    },
  );

  blocTest<InterviewCubit, InterviewState>(
    'does not retry when the failed start has no simulation id',
    build: build,
    setUp: () {
      when(() => startByJob(any())).thenAnswer(
        (_) async => const Left(InterviewStartFailure(
          NetworkFailure('No internet connection'),
        )),
      );
    },
    act: (cubit) async {
      await startJob(cubit);
      await cubit.retryStart();
    },
    verify: (_) => verifyNever(() => retry(any())),
    expect: () => [
      checked,
      checked.copyWith(language: 'English', phase: InterviewPhase.starting),
      checked.copyWith(
        language: 'English',
        phase: InterviewPhase.startFailed,
        error: const NetworkFailure('No internet connection'),
      ),
    ],
  );

  blocTest<InterviewCubit, InterviewState>(
    'ignores a second start while the first request is running',
    build: build,
    act: (cubit) async {
      final gate = Completer<Either<Failure, InterviewStartResponse>>();
      when(() => startByJob(any())).thenAnswer((_) => gate.future);
      await cubit.loadCv();
      final first = startJob(cubit);
      final second = startJob(cubit);
      gate.complete(const Right(started));
      await Future.wait([first, second]);
    },
    verify: (_) => verify(() => startByJob(any())).called(1),
  );

  const session = InterviewState(
    cvChecked: true,
    phase: InterviewPhase.inProgress,
    simulationId: 'sim-1',
    questions: [question, second],
  );

  blocTest<InterviewCubit, InterviewState>(
    'submits an answer and keeps it for a later read-only view',
    build: build,
    seed: () => session,
    act: (cubit) => cubit.submit('  My answer  '),
    expect: () => [
      session.copyWith(phase: InterviewPhase.submitting),
      session.copyWith(
        evaluations: const {'q-1': evaluation},
        submittedAnswers: const {'q-1': 'My answer'},
      ),
    ],
    verify: (_) {
      final params = verify(() => submit(captureAny())).captured.single
          as SubmitAnswerParams;
      expect(params.skipped, isFalse);
      expect(params.answerText, 'My answer');
      expect(params.questionId, 'q-1');
    },
  );

  blocTest<InterviewCubit, InterviewState>(
    'skips a question without sending answer text',
    build: build,
    setUp: () {
      when(() => submit(any())).thenAnswer((_) async => const Right(skipped));
    },
    seed: () => session,
    act: (cubit) => cubit.skip(),
    expect: () => [
      session.copyWith(phase: InterviewPhase.submitting),
      session.copyWith(evaluations: const {'q-1': skipped}),
    ],
    verify: (_) {
      final params = verify(() => submit(captureAny())).captured.single
          as SubmitAnswerParams;
      expect(params.skipped, isTrue);
      expect(params.answerText, isNull);
    },
  );

  blocTest<InterviewCubit, InterviewState>(
    'does not submit twice while a request is running or after evaluation',
    build: build,
    seed: () => session,
    act: (cubit) async {
      final gate = Completer<Either<Failure, AnswerEvaluation>>();
      when(() => submit(any())).thenAnswer((_) => gate.future);
      final first = cubit.submit('My answer');
      final second = cubit.submit('My answer');
      gate.complete(const Right(evaluation));
      await Future.wait([first, second]);
      await cubit.submit('A different answer');
    },
    verify: (_) => verify(() => submit(any())).called(1),
  );

  blocTest<InterviewCubit, InterviewState>(
    'keeps the session when the answer is rejected',
    build: build,
    seed: () => session,
    setUp: () {
      when(() => submit(any())).thenAnswer(
        (_) async => const Left(
          ConflictFailure('This question has already been evaluated'),
        ),
      );
    },
    act: (cubit) => cubit.submit('My answer'),
    expect: () => [
      session.copyWith(phase: InterviewPhase.submitting),
      session.copyWith(
        error: const ConflictFailure(
          'This question has already been evaluated',
        ),
      ),
    ],
  );

  blocTest<InterviewCubit, InterviewState>(
    'moving back does not submit the earlier answer again',
    build: build,
    seed: () => session.copyWith(
      currentIndex: 1,
      evaluations: const {'q-1': evaluation},
      submittedAnswers: const {'q-1': 'My answer'},
    ),
    act: (cubit) async {
      cubit.previous();
      await cubit.submit('Different');
    },
    expect: () => [
      session.copyWith(
        evaluations: const {'q-1': evaluation},
        submittedAnswers: const {'q-1': 'My answer'},
      ),
    ],
    verify: (_) => verifyNever(() => submit(any())),
  );

  blocTest<InterviewCubit, InterviewState>(
    'finishes and loads the report once',
    build: build,
    seed: () => session,
    act: (cubit) => cubit.finish(),
    expect: () => [
      session.copyWith(phase: InterviewPhase.finishing),
      session.copyWith(
        phase: InterviewPhase.finished,
        finishResult: finished,
        reportLoading: true,
      ),
      session.copyWith(
        phase: InterviewPhase.finished,
        finishResult: finished,
        report: report,
      ),
    ],
    verify: (_) => verify(() => getReport(any())).called(1),
  );

  blocTest<InterviewCubit, InterviewState>(
    'keeps the finish result when the report request fails',
    build: build,
    seed: () => session,
    setUp: () {
      when(() => getReport(any())).thenAnswer(
        (_) async => const Left(NetworkFailure('No internet connection')),
      );
    },
    act: (cubit) => cubit.finish(),
    expect: () => [
      session.copyWith(phase: InterviewPhase.finishing),
      session.copyWith(
        phase: InterviewPhase.finished,
        finishResult: finished,
        reportLoading: true,
      ),
      session.copyWith(
        phase: InterviewPhase.finished,
        finishResult: finished,
        reportFailure: const NetworkFailure('No internet connection'),
      ),
    ],
    verify: (cubit) {
      expect(cubit.state.finishResult, finished);
      expect(cubit.state.report, isNull);
    },
  );

  blocTest<InterviewCubit, InterviewState>(
    'does not finish again after the result is stored',
    build: build,
    seed: () => session.copyWith(
      phase: InterviewPhase.finished,
      finishResult: finished,
      report: report,
    ),
    act: (cubit) => cubit.finish(),
    expect: () => <InterviewState>[],
    verify: (_) {
      verifyNever(() => finish(any()));
      verifyNever(() => getReport(any()));
    },
  );

  blocTest<InterviewCubit, InterviewState>(
    'stores one processed job title and sends that title with its cv id',
    build: build,
    setUp: () {
      when(() => profile(any())).thenAnswer(
        (_) async => const Right(CvProfile(
          cvId: 'cv-1',
          status: CvAnalysisStatus.processed,
          fullName: 'Example Name',
          jobTitles: ['Flutter Developer'],
          skills: ['Flutter'],
        )),
      );
    },
    act: (cubit) => startJob(cubit, input: 'Flutter Developer'),
    expect: () => [
      checked.copyWith(
        cvId: 'cv-1',
        cvJobTitles: const ['Flutter Developer'],
      ),
      checked.copyWith(
        cvId: 'cv-1',
        cvJobTitles: const ['Flutter Developer'],
        language: 'English',
        phase: InterviewPhase.starting,
      ),
      checked.copyWith(
        cvId: 'cv-1',
        cvJobTitles: const ['Flutter Developer'],
        language: 'English',
        phase: InterviewPhase.inProgress,
        simulationId: 'sim-1',
        questions: started.questions,
      ),
    ],
    verify: (_) {
      final params = verify(() => startByJob(captureAny())).captured.single
          as StartInterviewByJobParams;
      expect(params.jobField, 'Flutter Developer');
      expect(params.cvId, 'cv-1');
      expect(params.interviewType, 'technical');
      expect(params.difficulty, 'medium');
      expect(params.language, 'English');
      expect(params.numQuestions, 5);
    },
  );

  blocTest<InterviewCubit, InterviewState>(
    'keeps the first copy of each trimmed job title in its original order',
    build: build,
    setUp: () {
      when(() => profile(any())).thenAnswer(
        (_) async => const Right(CvProfile(
          cvId: 'cv-1',
          status: CvAnalysisStatus.processed,
          fullName: 'Example Name',
          jobTitles: [
            ' Flutter Developer ',
            '',
            'Mobile Engineer',
            'Flutter Developer',
            '   ',
            'Mobile Engineer',
          ],
          skills: ['Flutter', 'Dart'],
        )),
      );
    },
    act: (cubit) => cubit.loadCv(),
    expect: () => [
      checked.copyWith(
        cvId: 'cv-1',
        cvJobTitles: const ['Flutter Developer', 'Mobile Engineer'],
      ),
    ],
    verify: (_) => verify(() => profile(any())).called(1),
  );

  blocTest<InterviewCubit, InterviewState>(
    'sends only the chosen job field when several titles were loaded',
    build: build,
    setUp: () {
      when(() => profile(any())).thenAnswer(
        (_) async => const Right(CvProfile(
          cvId: 'cv-1',
          status: CvAnalysisStatus.processed,
          jobTitles: ['Flutter Developer', 'Mobile Engineer'],
        )),
      );
    },
    act: (cubit) => startJob(cubit, input: 'Mobile Engineer'),
    verify: (_) {
      final params = verify(() => startByJob(captureAny())).captured.single
          as StartInterviewByJobParams;
      expect(params.jobField, 'Mobile Engineer');
      expect(params.cvId, 'cv-1');
    },
  );

  blocTest<InterviewCubit, InterviewState>(
    'keeps a processed cv id when it has no usable job titles',
    build: build,
    setUp: () {
      when(() => profile(any())).thenAnswer(
        (_) async => const Right(CvProfile(
          cvId: 'cv-1',
          status: CvAnalysisStatus.processed,
          fullName: 'Example Name',
          jobTitles: [' ', ''],
          skills: ['Flutter'],
        )),
      );
    },
    act: (cubit) => startJob(cubit),
    expect: () => [
      checked.copyWith(cvId: 'cv-1'),
      checked.copyWith(
          cvId: 'cv-1', language: 'English', phase: InterviewPhase.starting),
      checked.copyWith(
        cvId: 'cv-1',
        language: 'English',
        phase: InterviewPhase.inProgress,
        simulationId: 'sim-1',
        questions: started.questions,
      ),
    ],
    verify: (_) {
      final params = verify(() => startByJob(captureAny())).captured.single
          as StartInterviewByJobParams;
      expect(params.jobField, 'Nurse');
      expect(params.cvId, 'cv-1');
    },
  );

  test('does not read titles from a cv that is not processed', () async {
    for (final status in [
      CvAnalysisStatus.pending,
      CvAnalysisStatus.inProgress,
      CvAnalysisStatus.failed,
    ]) {
      when(() => profile(any())).thenAnswer(
        (_) async => Right(CvProfile(
          cvId: 'cv-pending',
          status: status,
          fullName: 'Example Name',
          jobTitles: const ['Flutter Developer'],
          skills: const ['Flutter'],
        )),
      );
      final cubit = build();
      await cubit.loadCv();
      await cubit.loadCv();
      await cubit.retryLoadCv();
      expect(cubit.state.cvChecked, isTrue);
      expect(cubit.state.cvId, isNull);
      expect(cubit.state.cvJobTitles, isEmpty);
      expect(cubit.state.cvLoadFailure, isNull);
      verify(() => profile(any())).called(1);
      verifyNever(() => startByJob(any()));
      verifyNever(() => startByDescription(any()));
      clearInteractions(profile);
      await cubit.close();
    }
  });

  blocTest<InterviewCubit, InterviewState>(
    'keeps a failed cv load separate from an empty cv',
    build: build,
    setUp: () {
      when(() => profile(any())).thenAnswer(
        (_) async => const Left(NetworkFailure('No internet connection')),
      );
    },
    act: (cubit) => startJob(cubit),
    expect: () => [
      checked.copyWith(
        cvLoadFailure: const NetworkFailure('No internet connection'),
      ),
      checked.copyWith(
        cvLoadFailure: const NetworkFailure('No internet connection'),
        language: 'English',
        phase: InterviewPhase.starting,
      ),
      checked.copyWith(
        cvLoadFailure: const NetworkFailure('No internet connection'),
        language: 'English',
        phase: InterviewPhase.inProgress,
        simulationId: 'sim-1',
        questions: started.questions,
      ),
    ],
    verify: (_) {
      final params = verify(() => startByJob(captureAny())).captured.single
          as StartInterviewByJobParams;
      expect(params.cvId, isNull);
      expect(params.jobField, 'Nurse');
      verify(() => profile(any())).called(1);
    },
  );

  blocTest<InterviewCubit, InterviewState>(
    'retries a failed cv load and then stores the processed titles',
    build: build,
    setUp: () {
      var attempt = 0;
      when(() => profile(any())).thenAnswer((_) async {
        attempt += 1;
        if (attempt == 1) {
          return const Left(NetworkFailure('No internet connection'));
        }
        return const Right(CvProfile(
          cvId: 'cv-1',
          status: CvAnalysisStatus.processed,
          jobTitles: ['Flutter Developer'],
        ));
      });
    },
    act: (cubit) async {
      await cubit.loadCv();
      await cubit.retryLoadCv();
    },
    expect: () => [
      checked.copyWith(
        cvLoadFailure: const NetworkFailure('No internet connection'),
      ),
      const InterviewState(),
      checked.copyWith(
        cvId: 'cv-1',
        cvJobTitles: const ['Flutter Developer'],
      ),
    ],
    verify: (_) => verify(() => profile(any())).called(2),
  );

  blocTest<InterviewCubit, InterviewState>(
    'requests the cv profile once when load is called twice',
    build: build,
    act: (cubit) async {
      final gate = Completer<Either<Failure, CvProfile?>>();
      when(() => profile(any())).thenAnswer((_) => gate.future);
      final first = cubit.loadCv();
      final second = cubit.loadCv();
      gate.complete(const Right(null));
      await Future.wait([first, second]);
    },
    expect: () => [checked],
    verify: (_) => verify(() => profile(any())).called(1),
  );

  blocTest<InterviewCubit, InterviewState>(
    'keeps the cv titles when another interview is prepared',
    build: build,
    seed: () => checked.copyWith(
      cvId: 'cv-1',
      cvJobTitles: const ['Flutter Developer', 'Mobile Engineer'],
      phase: InterviewPhase.finished,
    ),
    act: (cubit) => cubit.prepareAnother(),
    expect: () => [
      checked.copyWith(
        cvId: 'cv-1',
        cvJobTitles: const ['Flutter Developer', 'Mobile Engineer'],
      ),
    ],
  );

  blocTest<InterviewCubit, InterviewState>(
    'does not replace a job description with a cv job title',
    build: build,
    setUp: () {
      when(() => profile(any())).thenAnswer(
        (_) async => const Right(CvProfile(
          cvId: 'cv-1',
          status: CvAnalysisStatus.processed,
          jobTitles: ['Flutter Developer', 'Mobile Engineer'],
        )),
      );
    },
    act: (cubit) => cubit.start(
      mode: InterviewStartMode.byJobDescription,
      input: '  A role that needs careful clinical judgment.  ',
      interviewType: 'behavioral',
      difficulty: 'hard',
      language: 'Arabic',
      numQuestions: 3,
    ),
    verify: (_) {
      final params = verify(() => startByDescription(captureAny()))
          .captured
          .single as StartInterviewByJobDescriptionParams;
      expect(params.jobDescription,
          'A role that needs careful clinical judgment.');
      expect(params.cvId, 'cv-1');
      expect(params.interviewType, 'behavioral');
      expect(params.difficulty, 'hard');
      expect(params.language, 'Arabic');
      expect(params.numQuestions, 3);
      verifyNever(() => startByJob(any()));
    },
  );

  test('adopts a processed profile without another CV request', () async {
    final cubit = build();
    cubit.adoptProcessedProfile(const CvProfile(
      cvId: 'cv-1',
      status: CvAnalysisStatus.processed,
      jobTitles: [
        ' Flutter Developer ',
        '',
        'Mobile Engineer',
        'Flutter Developer',
      ],
    ));
    expect(cubit.state.cvChecked, isTrue);
    expect(cubit.state.cvId, 'cv-1');
    expect(
      cubit.state.cvJobTitles,
      const ['Flutter Developer', 'Mobile Engineer'],
    );
    await cubit.loadCv();
    await cubit.start(
      mode: InterviewStartMode.byJob,
      input: 'Mobile Engineer',
      interviewType: 'technical',
      difficulty: 'medium',
      language: 'English',
      numQuestions: 5,
    );
    final params = verify(() => startByJob(captureAny())).captured.single
        as StartInterviewByJobParams;
    expect(params.jobField, 'Mobile Engineer');
    expect(params.cvId, 'cv-1');
    verifyNever(() => profile(any()));
    await cubit.close();
  });

  const historyReport = InterviewReport(
    simulationId: 'sim-9',
    score: 85,
    performanceStatus: 'excellent',
    status: 'completed',
    reportStatus: 'completed',
    reportSummary: 'Clear answers.',
    answeredQuestions: 4,
    skippedQuestions: 1,
    unansweredQuestions: 0,
    questions: [
      InterviewReportQuestion(
        id: 'q-9',
        questionText: 'Describe a project.',
        isSkipped: false,
      ),
    ],
  );
  const seeded = InterviewFinishResult(
    simulationId: 'sim-9',
    score: 85,
    performanceStatus: 'excellent',
    totalQuestions: 1,
    answeredQuestions: 4,
    skippedQuestions: 1,
    unansweredQuestions: 0,
    status: 'completed',
    reportStatus: 'completed',
    reportSummary: 'Clear answers.',
  );

  blocTest<InterviewCubit, InterviewState>(
    'opens a completed report once and seeds the finish summary',
    build: build,
    setUp: () {
      when(() => getReport(any()))
          .thenAnswer((_) async => const Right(historyReport));
    },
    act: (cubit) => cubit.openCompletedReport('sim-9'),
    expect: () => [
      const InterviewState(
        phase: InterviewPhase.finished,
        simulationId: 'sim-9',
        reportLoading: true,
      ),
      const InterviewState(
        phase: InterviewPhase.finished,
        simulationId: 'sim-9',
        report: historyReport,
        finishResult: seeded,
      ),
    ],
    verify: (_) {
      verify(
        () => getReport(const GetInterviewReportParams(simulationId: 'sim-9')),
      ).called(1);
      verifyNever(() => finish(any()));
    },
  );

  blocTest<InterviewCubit, InterviewState>(
    'sums question counts when a historical report has no question list',
    build: build,
    setUp: () {
      when(() => getReport(any())).thenAnswer(
        (_) async => const Right(InterviewReport(
          simulationId: 'sim-4',
          answeredQuestions: 2,
          skippedQuestions: 1,
          unansweredQuestions: 0,
          questions: [],
        )),
      );
    },
    act: (cubit) => cubit.openCompletedReport('sim-4'),
    verify: (cubit) {
      expect(cubit.state.finishResult?.totalQuestions, 3);
      expect(cubit.state.finishResult?.score, isNull);
      verifyNever(() => finish(any()));
    },
  );

  blocTest<InterviewCubit, InterviewState>(
    'keeps the retry state when a historical report fails',
    build: build,
    setUp: () {
      when(() => getReport(any())).thenAnswer(
        (_) async => const Left(NetworkFailure('No internet connection')),
      );
    },
    act: (cubit) => cubit.openCompletedReport('sim-9'),
    expect: () => [
      const InterviewState(
        phase: InterviewPhase.finished,
        simulationId: 'sim-9',
        reportLoading: true,
      ),
      const InterviewState(
        phase: InterviewPhase.finished,
        simulationId: 'sim-9',
        reportFailure: NetworkFailure('No internet connection'),
      ),
    ],
    verify: (cubit) {
      expect(cubit.state.finishResult, isNull);
      expect(cubit.state.report, isNull);
      verifyNever(() => finish(any()));
    },
  );

  blocTest<InterviewCubit, InterviewState>(
    'does not request a report for a blank simulation id',
    build: build,
    act: (cubit) => cubit.openCompletedReport(''),
    expect: () => const <InterviewState>[],
    verify: (_) => verifyNever(() => getReport(any())),
  );
}
