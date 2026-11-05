import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rashed_app/app/routes_name.dart';
import 'package:rashed_app/app_localizations.dart';
import 'package:rashed_app/core/error/failures.dart';
import 'package:rashed_app/core/usecases/usecase.dart';
import 'package:rashed_app/features/cv/domain/entities/cv_profile.dart';
import 'package:rashed_app/features/cv/domain/usecases/get_my_cv_profile_usecase.dart';
import 'package:rashed_app/features/home/domain/entities/share_result.dart';
import 'package:rashed_app/features/home/domain/usecases/share_interview_result_usecase.dart';
import 'package:rashed_app/features/home/presentation/cubit/home_cubit.dart';
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
import 'package:rashed_app/features/simulation/presentation/screens/interview_evaluation_screen.dart';
import 'package:rashed_app/features/simulation/presentation/screens/interview_question_screen.dart';
import 'package:rashed_app/features/simulation/presentation/screens/interview_result_screen.dart';
import 'package:rashed_app/features/simulation/presentation/screens/interview_setup_screen.dart';
import 'package:rashed_app/features/simulation/presentation/widgets/interview_widgets.dart';

class MockStartByJob extends Mock implements StartInterviewByJobUseCase {}

class MockStartByDescription extends Mock
    implements StartInterviewByJobDescriptionUseCase {}

class MockRetry extends Mock implements RetryInterviewGenerationUseCase {}

class MockSubmit extends Mock implements SubmitAnswerUseCase {}

class MockFinish extends Mock implements FinishInterviewUseCase {}

class MockReport extends Mock implements GetInterviewReportUseCase {}

class MockHistory extends Mock implements GetSimulationsHistoryUseCase {}

class MockProfile extends Mock implements GetMyCvProfileUseCase {}

class MockShare extends Mock implements ShareInterviewResultUseCase {}

class LoadedLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  final Map<String, AppLocalizations> loaded;
  const LoadedLocalizationsDelegate(this.loaded);

  @override
  bool isSupported(Locale locale) => loaded.containsKey(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) =>
      SynchronousFuture(loaded[locale.languageCode]!);

  @override
  bool shouldReload(LoadedLocalizationsDelegate old) => false;
}

void main() {
  final loaded = <String, AppLocalizations>{};
  const question = InterviewQuestion(
    id: 'q-1',
    questionText: 'Tell me about a project.',
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
    questions: [question, second],
  );
  const evaluation = AnswerEvaluation(
    questionId: 'q-1',
    score: 70,
    strengths: ['Clear structure'],
    suggestedAnswer: 'Add a measurable result.',
    skipped: false,
  );
  const finished = InterviewFinishResult(
    simulationId: 'sim-1',
    score: 82,
    performanceStatus: 'excellent',
    totalQuestions: 2,
    answeredQuestions: 1,
    skippedQuestions: 0,
    unansweredQuestions: 1,
    reportSummary: 'Strong examples.',
  );
  const report = InterviewReport(
    simulationId: 'sim-1',
    score: 82,
    strengths: ['Clear structure'],
    questions: [
      InterviewReportQuestion(
        id: 'q-1',
        questionText: 'Tell me about a project.',
        isSkipped: false,
        evaluationScore: 70,
      ),
    ],
  );

  late MockStartByJob startByJob;
  late MockStartByDescription startByDescription;
  late MockRetry retry;
  late MockSubmit submit;
  late MockFinish finish;
  late MockReport getReport;
  late MockProfile profile;
  late MockShare share;
  late InterviewCubit cubit;
  late HomeCubit homeCubit;

  setUpAll(() async {
    for (final code in ['en', 'ar']) {
      final strings = AppLocalizations(Locale(code));
      await strings.loadJsonLanguage();
      loaded[code] = strings;
    }
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
    registerFallbackValue(const ShareInterviewResultParams());
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
    share = MockShare();
    when(() => profile(any())).thenAnswer((_) async => const Right(null));
    when(() => startByJob(any())).thenAnswer((_) async => const Right(started));
    when(() => startByDescription(any()))
        .thenAnswer((_) async => const Right(started));
    when(() => retry(any())).thenAnswer((_) async => const Right(started));
    when(() => submit(any())).thenAnswer((_) async => const Right(evaluation));
    when(() => finish(any())).thenAnswer((_) async => const Right(finished));
    when(() => getReport(any())).thenAnswer((_) async => const Right(report));
    when(() => share(any())).thenAnswer(
      (_) async => const Right(
          ShareResult(postUrl: 'https://example.test/post', postUrn: 'urn')),
    );
    cubit = InterviewCubit(
      startInterviewByJobUseCase: startByJob,
      startInterviewByJobDescriptionUseCase: startByDescription,
      retryInterviewGenerationUseCase: retry,
      submitAnswerUseCase: submit,
      finishInterviewUseCase: finish,
      getInterviewReportUseCase: getReport,
      getSimulationsHistoryUseCase: MockHistory(),
      getMyCvProfileUseCase: profile,
    );
    homeCubit = HomeCubit(shareInterviewResultUseCase: share);
  });

  tearDown(() async {
    await cubit.close();
    await homeCubit.close();
  });

  Future<void> pump(
    WidgetTester tester,
    Locale locale,
    Widget home,
  ) async {
    tester.view.physicalSize = const Size(900, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
      locale: locale,
      supportedLocales: const [Locale('en'), Locale('ar')],
      localizationsDelegates: [
        LoadedLocalizationsDelegate(loaded),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: home,
      onGenerateRoute: (settings) {
        final page = switch (settings.name) {
          RoutesName.simulationQuestion => const InterviewQuestionScreen(),
          RoutesName.simulationEvaluation => const InterviewEvaluationScreen(),
          RoutesName.simulationResult => const InterviewResultScreen(),
          _ => const SizedBox.shrink(),
        };
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => BlocProvider.value(
            value: cubit,
            child: settings.name == RoutesName.simulationResult
                ? BlocProvider.value(value: homeCubit, child: page)
                : page,
          ),
        );
      },
    ));
  }

  Widget hosted(Widget child) {
    return BlocProvider.value(
      value: cubit,
      child: BlocProvider.value(value: homeCubit, child: child),
    );
  }

  testWidgets(
      'setup rejects a short job field and disables start while starting',
      (tester) async {
    final gate = Completer<Either<Failure, InterviewStartResponse>>();
    when(() => startByJob(any())).thenAnswer((_) => gate.future);
    await pump(
      tester,
      const Locale('en'),
      hosted(const InterviewSetupScreen(initialMode: InterviewStartMode.byJob)),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('interview_job_input')), 'N');
    await tester.pump();
    expect(find.text('Enter a career field between 2 and 150 characters.'),
        findsOneWidget);
    expect(
      tester
          .widget<InterviewActionButton>(
              find.byKey(const Key('interview_start_button')))
          .enabled,
      isFalse,
    );

    await tester.enterText(
        find.byKey(const Key('interview_job_input')), 'Nurse');
    await tester.pump();
    await tester.tap(find.byKey(const Key('interview_start_button')));
    await tester.pump();
    expect(
      tester
          .widget<InterviewActionButton>(
              find.byKey(const Key('interview_start_button')))
          .enabled,
      isFalse,
    );
    gate.complete(const Right(started));
    await tester.pumpAndSettle();
    expect(find.text('1 of 2'), findsOneWidget);
    expect(find.text('Tell me about a project.'), findsOneWidget);
  });

  testWidgets('setup can start from a job description and shows the cv note',
      (tester) async {
    when(() => profile(any())).thenAnswer(
      (_) async => const Right(CvProfile(
        cvId: 'cv-1',
        status: CvAnalysisStatus.processed,
      )),
    );
    await pump(
      tester,
      const Locale('en'),
      hosted(const InterviewSetupScreen(
        initialMode: InterviewStartMode.byJobDescription,
      )),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('interview_cv_used')), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('interview_description_input')),
      'A role that needs careful clinical judgment.',
    );
    await tester.pump();
    await tester.ensureVisible(find.byKey(const Key('interview_start_button')));
    await tester.tap(find.byKey(const Key('interview_start_button')));
    await tester.pumpAndSettle();
    final params = verify(() => startByDescription(captureAny()))
        .captured
        .single as StartInterviewByJobDescriptionParams;
    expect(params.cvId, 'cv-1');
    verifyNever(() => startByJob(any()));
  });

  testWidgets('question, evaluation, and result render in English and Arabic',
      (tester) async {
    for (final locale in const [Locale('en'), Locale('ar')]) {
      await cubit.start(
        mode: InterviewStartMode.byJob,
        input: 'Nurse',
        interviewType: 'technical',
        difficulty: 'medium',
        language: 'English',
        numQuestions: 5,
      );
      await pump(tester, locale, hosted(const InterviewQuestionScreen()));
      await tester.pumpAndSettle();
      final icon =
          tester.widget<Icon>(find.byKey(const Key('interview_back_icon')));
      final direction = tester.widget<Directionality>(find
          .descendant(
            of: find.byType(InterviewQuestionScreen),
            matching: find.byType(Directionality),
          )
          .first);
      if (locale.languageCode == 'ar') {
        expect(direction.textDirection, TextDirection.rtl);
        expect(icon.icon, Icons.chevron_right);
        expect(find.text('1 من 2'), findsOneWidget);
      } else {
        expect(direction.textDirection, TextDirection.ltr);
        expect(icon.icon, Icons.chevron_left);
        expect(find.text('1 of 2'), findsOneWidget);
      }

      await tester.pumpWidget(const SizedBox.shrink());
      await cubit.submit('My answer');
      await pump(tester, locale, hosted(const InterviewEvaluationScreen()));
      await tester.pumpAndSettle();
      expect(find.text('Clear structure'), findsOneWidget);
      expect(find.text('Add a measurable result.'), findsOneWidget);
      expect(find.byKey(const Key('interview_negatives')), findsNothing);
      expect(find.textContaining('70'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await cubit.finish();
      await pump(tester, locale, hosted(const InterviewResultScreen()));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('interview_result_score')), findsOneWidget);
      expect(find.text('82'), findsOneWidget);
      expect(find.text('Strong examples.'), findsOneWidget);
      expect(find.byKey(const Key('interview_strengths')), findsOneWidget);
      expect(find.byKey(const Key('interview_improvements')), findsNothing);
      expect(find.byKey(const Key('interview_recommendations')), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
      cubit.prepareAnother();
    }
  });

  testWidgets(
      'back confirms before finishing and keep going stays on the question',
      (tester) async {
    await pump(
      tester,
      const Locale('en'),
      hosted(const InterviewSetupScreen(initialMode: InterviewStartMode.byJob)),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const Key('interview_job_input')), 'Nurse');
    await tester.pump();
    await tester.ensureVisible(find.byKey(const Key('interview_start_button')));
    await tester.tap(find.byKey(const Key('interview_start_button')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('interview_back_button')));
    await tester.pumpAndSettle();
    expect(find.text('Finish this interview?'), findsOneWidget);
    await tester.tap(find.byKey(const Key('interview_keep_going')));
    await tester.pumpAndSettle();
    expect(find.text('Tell me about a project.'), findsOneWidget);
    verifyNever(() => finish(any()));

    await tester.tap(find.byKey(const Key('interview_back_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('interview_finish_now')));
    await tester.pumpAndSettle();
    expect(find.text('82'), findsOneWidget);
    verify(() => finish(any())).called(1);
  });

  testWidgets(
      'skip moves to the evaluation and a duplicate tap does not submit again',
      (tester) async {
    final gate = Completer<Either<Failure, AnswerEvaluation>>();
    when(() => submit(any())).thenAnswer((_) => gate.future);
    await cubit.start(
      mode: InterviewStartMode.byJob,
      input: 'Nurse',
      interviewType: 'technical',
      difficulty: 'medium',
      language: 'English',
      numQuestions: 5,
    );
    await pump(
        tester, const Locale('en'), hosted(const InterviewQuestionScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('interview_skip_button')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('interview_skip_button')));
    gate.complete(
        const Right(AnswerEvaluation(questionId: 'q-1', skipped: true)));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('interview_skipped')), findsOneWidget);
    verify(() => submit(any())).called(1);
  });

  testWidgets('a failed start offers retry when the simulation id was returned',
      (tester) async {
    when(() => startByJob(any())).thenAnswer(
      (_) async => const Left(InterviewStartFailure(
        UpstreamFailure('Interview AI provider returned an invalid result'),
        simulationId: 'sim-x',
      )),
    );
    await pump(
      tester,
      const Locale('en'),
      hosted(const InterviewSetupScreen(initialMode: InterviewStartMode.byJob)),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const Key('interview_job_input')), 'Nurse');
    await tester.pump();
    await tester.ensureVisible(find.byKey(const Key('interview_start_button')));
    await tester.tap(find.byKey(const Key('interview_start_button')));
    await tester.pumpAndSettle();
    expect(find.text('Retry'), findsOneWidget);
    await tester.tap(find.byKey(const Key('interview_error_action')));
    await tester.pumpAndSettle();
    verify(() => retry(any())).called(1);
  });

  testWidgets('one processed job title is preselected and sent as job_field',
      (tester) async {
    when(() => profile(any())).thenAnswer(
      (_) async => const Right(CvProfile(
        cvId: 'cv-1',
        status: CvAnalysisStatus.processed,
        fullName: 'Example Name',
        jobTitles: ['Flutter Developer'],
        skills: ['Flutter'],
      )),
    );
    await pump(
      tester,
      const Locale('en'),
      hosted(const InterviewSetupScreen(initialMode: InterviewStartMode.byJob)),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('interview_cv_job_title')), findsOneWidget);
    expect(find.text('Flutter Developer'), findsOneWidget);
    expect(find.text('Job title from your CV'), findsOneWidget);
    expect(
        find.byKey(const Key('interview_cv_job_title_dropdown')), findsNothing);
    expect(find.byKey(const Key('interview_job_input')), findsNothing);
    await tester.ensureVisible(find.byKey(const Key('interview_start_button')));
    await tester.tap(find.byKey(const Key('interview_start_button')));
    await tester.pumpAndSettle();
    final params = verify(() => startByJob(captureAny())).captured.single
        as StartInterviewByJobParams;
    expect(params.jobField, 'Flutter Developer');
    expect(params.cvId, 'cv-1');
    verify(() => profile(any())).called(1);
  });

  testWidgets('several job titles keep the chosen title and the same cv id',
      (tester) async {
    when(() => profile(any())).thenAnswer(
      (_) async => const Right(CvProfile(
        cvId: 'cv-1',
        status: CvAnalysisStatus.processed,
        jobTitles: [
          ' Flutter Developer ',
          '',
          'Mobile Engineer',
          'Flutter Developer',
        ],
      )),
    );
    await pump(
      tester,
      const Locale('en'),
      hosted(const InterviewSetupScreen(initialMode: InterviewStartMode.byJob)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Select job title'), findsOneWidget);
    expect(find.text('Flutter Developer'), findsOneWidget);
    expect(find.text('Mobile Engineer'), findsNothing);
    await tester.tap(find.byKey(const Key('interview_cv_job_title_dropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mobile Engineer').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('interview_start_button')));
    await tester.tap(find.byKey(const Key('interview_start_button')));
    await tester.pumpAndSettle();
    final params = verify(() => startByJob(captureAny())).captured.single
        as StartInterviewByJobParams;
    expect(params.jobField, 'Mobile Engineer');
    expect(params.cvId, 'cv-1');
  });

  testWidgets('a processed cv with no titles keeps manual entry and the cv id',
      (tester) async {
    when(() => profile(any())).thenAnswer(
      (_) async => const Right(CvProfile(
        cvId: 'cv-1',
        status: CvAnalysisStatus.processed,
        fullName: 'Example Name',
        jobTitles: [' ', ''],
        skills: ['Flutter'],
      )),
    );
    await pump(
      tester,
      const Locale('en'),
      hosted(const InterviewSetupScreen(initialMode: InterviewStartMode.byJob)),
    );
    await tester.pumpAndSettle();
    expect(
        find.byKey(const Key('interview_cv_job_titles_empty')), findsOneWidget);
    expect(find.text('No job titles found'), findsOneWidget);
    expect(find.byKey(const Key('interview_job_input')), findsOneWidget);
    expect(find.text('Example Name'), findsNothing);
    expect(find.text('Flutter'), findsNothing);
    await tester.enterText(
        find.byKey(const Key('interview_job_input')), 'Nurse');
    await tester.pump();
    await tester.ensureVisible(find.byKey(const Key('interview_start_button')));
    await tester.tap(find.byKey(const Key('interview_start_button')));
    await tester.pumpAndSettle();
    final params = verify(() => startByJob(captureAny())).captured.single
        as StartInterviewByJobParams;
    expect(params.jobField, 'Nurse');
    expect(params.cvId, 'cv-1');
  });

  testWidgets('no cv leaves manual entry and omits cv id', (tester) async {
    await pump(
      tester,
      const Locale('en'),
      hosted(const InterviewSetupScreen(initialMode: InterviewStartMode.byJob)),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('interview_job_input')), findsOneWidget);
    expect(
        find.byKey(const Key('interview_cv_job_titles_empty')), findsNothing);
    expect(find.byKey(const Key('interview_cv_titles_error')), findsNothing);
    await tester.enterText(
        find.byKey(const Key('interview_job_input')), 'Nurse');
    await tester.pump();
    await tester.ensureVisible(find.byKey(const Key('interview_start_button')));
    await tester.tap(find.byKey(const Key('interview_start_button')));
    await tester.pumpAndSettle();
    final params = verify(() => startByJob(captureAny())).captured.single
        as StartInterviewByJobParams;
    expect(params.jobField, 'Nurse');
    expect(params.cvId, isNull);
  });

  testWidgets('a pending or failed cv does not block manual setup',
      (tester) async {
    for (final status in [
      CvAnalysisStatus.pending,
      CvAnalysisStatus.failed,
    ]) {
      when(() => profile(any())).thenAnswer(
        (_) async => Right(CvProfile(
          cvId: 'cv-pending',
          status: status,
          jobTitles: const ['Flutter Developer'],
        )),
      );
      final localCubit = InterviewCubit(
        startInterviewByJobUseCase: startByJob,
        startInterviewByJobDescriptionUseCase: startByDescription,
        retryInterviewGenerationUseCase: retry,
        submitAnswerUseCase: submit,
        finishInterviewUseCase: finish,
        getInterviewReportUseCase: getReport,
        getSimulationsHistoryUseCase: MockHistory(),
        getMyCvProfileUseCase: profile,
      );
      addTearDown(localCubit.close);
      await pump(
        tester,
        const Locale('en'),
        BlocProvider.value(
          value: localCubit,
          child: const InterviewSetupScreen(
            initialMode: InterviewStartMode.byJob,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('interview_job_input')), findsOneWidget);
      expect(
          find.byKey(const Key('interview_cv_job_titles_empty')), findsNothing);
      expect(find.byKey(const Key('interview_cv_titles_error')), findsNothing);
      expect(find.text('Flutter Developer'), findsNothing);
      verify(() => profile(any())).called(1);
      verifyNever(() => startByJob(any()));
      clearInteractions(profile);
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });

  testWidgets(
      'a cv load failure can be retried and does not block manual entry',
      (tester) async {
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
    await pump(
      tester,
      const Locale('en'),
      hosted(const InterviewSetupScreen(initialMode: InterviewStartMode.byJob)),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('interview_cv_titles_error')), findsOneWidget);
    expect(find.text('Unable to load CV job titles'), findsOneWidget);
    expect(find.byKey(const Key('interview_job_input')), findsOneWidget);
    expect(
        find.byKey(const Key('interview_cv_job_titles_empty')), findsNothing);
    await tester.enterText(
        find.byKey(const Key('interview_job_input')), 'Nurse');
    await tester.pump();
    expect(
      tester
          .widget<InterviewActionButton>(
              find.byKey(const Key('interview_start_button')))
          .enabled,
      isTrue,
    );
    await tester.tap(find.byKey(const Key('interview_cv_retry')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('interview_cv_titles_error')), findsNothing);
    expect(find.text('Nurse'), findsOneWidget);
    expect(find.byKey(const Key('interview_cv_job_title')), findsNothing);
    expect(find.byKey(const Key('interview_cv_job_title_from_cv')),
        findsOneWidget);
    verify(() => profile(any())).called(2);
  });

  testWidgets('manual entry replaces the selected cv title and can return',
      (tester) async {
    when(() => profile(any())).thenAnswer(
      (_) async => const Right(CvProfile(
        cvId: 'cv-1',
        status: CvAnalysisStatus.processed,
        jobTitles: ['Flutter Developer'],
      )),
    );
    await pump(
      tester,
      const Locale('en'),
      hosted(const InterviewSetupScreen(initialMode: InterviewStartMode.byJob)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('interview_cv_job_title_other')));
    await tester.pump();
    await tester.enterText(
        find.byKey(const Key('interview_job_input')), 'Nurse');
    await tester.pump();
    await tester.tap(find.byKey(const Key('interview_cv_job_title_from_cv')));
    await tester.pump();
    expect(find.text('Flutter Developer'), findsOneWidget);
    expect(find.byKey(const Key('interview_job_input')), findsNothing);
    await tester.tap(find.byKey(const Key('interview_cv_job_title_other')));
    await tester.pump();
    expect(find.text('Nurse'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('interview_start_button')));
    await tester.tap(find.byKey(const Key('interview_start_button')));
    await tester.pumpAndSettle();
    final params = verify(() => startByJob(captureAny())).captured.single
        as StartInterviewByJobParams;
    expect(params.jobField, 'Nurse');
    expect(params.cvId, 'cv-1');
  });

  testWidgets('a late cv response does not replace a role the user typed',
      (tester) async {
    final gate = Completer<Either<Failure, CvProfile?>>();
    when(() => profile(any())).thenAnswer((_) => gate.future);
    await pump(
      tester,
      const Locale('en'),
      hosted(const InterviewSetupScreen(initialMode: InterviewStartMode.byJob)),
    );
    await tester.pump();
    expect(
      tester
          .widget<InterviewActionButton>(
              find.byKey(const Key('interview_start_button')))
          .enabled,
      isFalse,
    );
    await tester.enterText(
        find.byKey(const Key('interview_job_input')), 'Product Manager');
    await tester.pump();
    gate.complete(const Right(CvProfile(
      cvId: 'cv-1',
      status: CvAnalysisStatus.processed,
      fullName: 'Example Name',
      jobTitles: ['Flutter Developer'],
      skills: ['Flutter'],
    )));
    await tester.pumpAndSettle();
    expect(find.text('Product Manager'), findsOneWidget);
    expect(find.byKey(const Key('interview_job_input')), findsOneWidget);
    expect(find.byKey(const Key('interview_cv_job_title')), findsNothing);
    expect(
        find.byKey(const Key('interview_cv_job_title_dropdown')), findsNothing);
    await tester.ensureVisible(find.byKey(const Key('interview_start_button')));
    await tester.tap(find.byKey(const Key('interview_start_button')));
    await tester.pumpAndSettle();
    final params = verify(() => startByJob(captureAny())).captured.single
        as StartInterviewByJobParams;
    expect(params.jobField, 'Product Manager');
    expect(params.cvId, 'cv-1');
    verify(() => profile(any())).called(1);
  });

  testWidgets('job description mode ignores cv job titles', (tester) async {
    when(() => profile(any())).thenAnswer(
      (_) async => const Right(CvProfile(
        cvId: 'cv-1',
        status: CvAnalysisStatus.processed,
        jobTitles: ['Flutter Developer', 'Mobile Engineer'],
      )),
    );
    await pump(
      tester,
      const Locale('en'),
      hosted(const InterviewSetupScreen(initialMode: InterviewStartMode.byJob)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Flutter Developer'), findsOneWidget);
    await tester.tap(find.text('Job description'));
    await tester.pump();
    final description = tester.widget<TextField>(
      find.byKey(const Key('interview_description_input')),
    );
    expect(description.controller?.text, isEmpty);
    expect(
        find.byKey(const Key('interview_cv_job_title_dropdown')), findsNothing);
    await tester.enterText(
      find.byKey(const Key('interview_description_input')),
      'A role that needs careful clinical judgment.',
    );
    await tester.pump();
    await tester.ensureVisible(find.byKey(const Key('interview_start_button')));
    await tester.tap(find.byKey(const Key('interview_start_button')));
    await tester.pumpAndSettle();
    final params = verify(() => startByDescription(captureAny()))
        .captured
        .single as StartInterviewByJobDescriptionParams;
    expect(
        params.jobDescription, 'A role that needs careful clinical judgment.');
    expect(params.cvId, 'cv-1');
    expect(params.interviewType, 'technical');
    expect(params.numQuestions, 5);
    verifyNever(() => startByJob(any()));
  });

  testWidgets('the selected cv title remains after leaving and returning',
      (tester) async {
    when(() => profile(any())).thenAnswer(
      (_) async => const Right(CvProfile(
        cvId: 'cv-1',
        status: CvAnalysisStatus.processed,
        jobTitles: ['Flutter Developer', 'Mobile Engineer'],
      )),
    );
    await pump(
      tester,
      const Locale('en'),
      hosted(const InterviewSetupScreen(initialMode: InterviewStartMode.byJob)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('interview_cv_job_title_dropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mobile Engineer').last);
    await tester.pumpAndSettle();
    cubit.prepareAnother();
    await tester.pump();
    expect(find.text('Mobile Engineer'), findsOneWidget);
    expect(find.text('Flutter Developer'), findsNothing);
    await tester.ensureVisible(find.byKey(const Key('interview_start_button')));
    await tester.tap(find.byKey(const Key('interview_start_button')));
    await tester.pumpAndSettle();
    final dropdown = tester.widget<DropdownButtonFormField<String>>(
      find.byKey(
        const Key('interview_cv_job_title_dropdown'),
        skipOffstage: false,
      ),
    );
    expect(dropdown.initialValue, 'Mobile Engineer');
  });

  testWidgets('setup requests the cv profile once', (tester) async {
    await cubit.loadCv();
    await pump(
      tester,
      const Locale('en'),
      hosted(const InterviewSetupScreen(initialMode: InterviewStartMode.byJob)),
    );
    await tester.pumpAndSettle();
    verify(() => profile(any())).called(1);
    verifyNever(() => startByJob(any()));
  });

  testWidgets('a single cv title is shown from right to left in Arabic',
      (tester) async {
    when(() => profile(any())).thenAnswer(
      (_) async => const Right(CvProfile(
        cvId: 'cv-1',
        status: CvAnalysisStatus.processed,
        jobTitles: ['مطور فلاتر'],
      )),
    );
    await pump(
      tester,
      const Locale('ar'),
      hosted(const InterviewSetupScreen(initialMode: InterviewStartMode.byJob)),
    );
    await tester.pumpAndSettle();
    final direction = tester.widget<Directionality>(find
        .descendant(
          of: find.byType(InterviewSetupScreen),
          matching: find.byType(Directionality),
        )
        .first);
    expect(direction.textDirection, TextDirection.rtl);
    expect(find.text('المسمى الوظيفي من سيرتك الذاتية'), findsWidgets);
    expect(find.text('أدخل مسمى وظيفيًا آخر'), findsOneWidget);
    expect(find.text('مطور فلاتر'), findsOneWidget);
  });
}
