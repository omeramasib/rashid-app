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
import 'package:rashed_app/core/ads/interview_ad_gate.dart';
import 'package:rashed_app/core/error/failures.dart';
import 'package:rashed_app/core/usecases/usecase.dart';
import 'package:rashed_app/features/cv/domain/usecases/get_my_cv_profile_usecase.dart';
import 'package:rashed_app/features/simulation/domain/entities/interview_question.dart';
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
import 'package:rashed_app/features/simulation/presentation/screens/interview_question_screen.dart';
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

class ScriptedAdGate implements InterviewAdGate {
  ScriptedAdGate({this.show});

  final Completer<void>? show;
  int preloads = 0;
  int shows = 0;

  @override
  Future<void> preload([
    AdPlacement placement = AdPlacement.interviewStart,
  ]) async {
    preloads += 1;
  }

  @override
  Future<void> showIfEligible([
    AdPlacement placement = AdPlacement.interviewStart,
  ]) {
    shows += 1;
    return show?.future ?? Future<void>.value();
  }
}

class LoadedLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const LoadedLocalizationsDelegate(this.loaded);

  final Map<String, AppLocalizations> loaded;

  @override
  bool isSupported(Locale locale) => loaded.containsKey(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture(loaded[locale.languageCode]!);
  }

  @override
  bool shouldReload(LoadedLocalizationsDelegate old) => false;
}

void main() {
  final loaded = <String, AppLocalizations>{};
  const started = InterviewStartResponse(
    simulationId: 'sim-1',
    interviewSettingId: 'setting-1',
    status: 'ready',
    reportStatus: 'pending',
    questions: [
      InterviewQuestion(
        id: 'q-1',
        questionText: 'Tell me about a project.',
        position: 1,
      ),
      InterviewQuestion(
        id: 'q-2',
        questionText: 'How do you handle feedback?',
        position: 2,
      ),
    ],
  );

  late MockStartByJob startByJob;
  late MockProfile profile;

  setUpAll(() async {
    for (final code in <String>['en', 'ar']) {
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
    registerFallbackValue(NoParams());
  });

  setUp(() {
    startByJob = MockStartByJob();
    profile = MockProfile();
    when(() => profile(any())).thenAnswer((_) async => const Right(null));
    when(() => startByJob(any())).thenAnswer((_) async => const Right(started));
  });

  InterviewCubit cubitFor(ScriptedAdGate gate) {
    return InterviewCubit(
      startInterviewByJobUseCase: startByJob,
      startInterviewByJobDescriptionUseCase: MockStartByDescription(),
      retryInterviewGenerationUseCase: MockRetry(),
      submitAnswerUseCase: MockSubmit(),
      finishInterviewUseCase: MockFinish(),
      getInterviewReportUseCase: MockReport(),
      getSimulationsHistoryUseCase: MockHistory(),
      getMyCvProfileUseCase: profile,
      adGate: gate,
    );
  }

  Future<void> pumpSetup(
    WidgetTester tester,
    InterviewCubit cubit,
  ) async {
    tester.view.physicalSize = const Size(900, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('en'),
      supportedLocales: const <Locale>[Locale('en'), Locale('ar')],
      localizationsDelegates: <LocalizationsDelegate<dynamic>>[
        LoadedLocalizationsDelegate(loaded),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: BlocProvider<InterviewCubit>(
        create: (_) => cubit,
        child: const InterviewSetupScreen(
          initialMode: InterviewStartMode.byJob,
        ),
      ),
      onGenerateRoute: (settings) {
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => BlocProvider<InterviewCubit>.value(
            value: cubit,
            child: settings.name == RoutesName.simulationQuestion
                ? const InterviewQuestionScreen()
                : const SizedBox.shrink(),
          ),
        );
      },
    ));
  }

  Future<void> enterRole(WidgetTester tester) async {
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const Key('interview_job_input')), 'Nurse');
    await tester.pump();
    await tester.ensureVisible(find.byKey(const Key('interview_start_button')));
  }

  InterviewActionButton startButton(WidgetTester tester) {
    return tester.widget<InterviewActionButton>(
      find.byKey(const Key('interview_start_button')),
    );
  }

  testWidgets('preloads while configuring and starts once after the ad',
      (tester) async {
    final show = Completer<void>();
    final api = Completer<Either<Failure, InterviewStartResponse>>();
    when(() => startByJob(any())).thenAnswer((_) => api.future);
    final gate = ScriptedAdGate(show: show);
    final cubit = cubitFor(gate);
    await pumpSetup(tester, cubit);
    await enterRole(tester);
    expect(gate.preloads, 1);

    await tester.tap(find.byKey(const Key('interview_start_button')));
    await tester.pump();
    expect(gate.shows, 1);
    expect(startButton(tester).busy, isFalse);
    expect(startButton(tester).label, 'Start interview');
    verifyNever(() => startByJob(any()));

    await tester.tap(find.byKey(const Key('interview_start_button')));
    await tester.pump();
    expect(gate.shows, 1);

    show.complete();
    await tester.pump();
    expect(startButton(tester).busy, isTrue);
    expect(startButton(tester).label, 'Starting');
    verify(() => startByJob(any())).called(1);

    api.complete(const Right(started));
    await tester.pumpAndSettle();
    expect(find.text('Tell me about a project.'), findsOneWidget);
    expect(find.byType(InterviewQuestionScreen), findsOneWidget);
  });

  testWidgets('starts immediately when the ad is unavailable', (tester) async {
    final gate = ScriptedAdGate();
    final cubit = cubitFor(gate);
    await pumpSetup(tester, cubit);
    await enterRole(tester);
    await tester.tap(find.byKey(const Key('interview_start_button')));
    await tester.pumpAndSettle();
    expect(gate.shows, 1);
    verify(() => startByJob(any())).called(1);
    expect(find.byType(InterviewQuestionScreen), findsOneWidget);
  });

  testWidgets(
      'a backend failure keeps the existing error and does not navigate',
      (tester) async {
    final gate = ScriptedAdGate();
    when(() => startByJob(any())).thenAnswer(
      (_) async => const Left(
        InterviewStartFailure(NetworkFailure('No internet connection')),
      ),
    );
    final cubit = cubitFor(gate);
    await pumpSetup(tester, cubit);
    await enterRole(tester);
    await tester.tap(find.byKey(const Key('interview_start_button')));
    await tester.pumpAndSettle();
    expect(find.text('No internet connection.'), findsOneWidget);
    expect(find.byType(InterviewQuestionScreen), findsNothing);
    verify(() => startByJob(any())).called(1);
    expect(startButton(tester).busy, isFalse);
  });

  testWidgets('disposal during the ad does not navigate or start',
      (tester) async {
    final show = Completer<void>();
    final gate = ScriptedAdGate(show: show);
    final cubit = cubitFor(gate);
    await pumpSetup(tester, cubit);
    await enterRole(tester);
    await tester.tap(find.byKey(const Key('interview_start_button')));
    await tester.pump();
    expect(gate.shows, 1);

    await tester.pumpWidget(const SizedBox.shrink());
    show.complete();
    await tester.pump();
    verifyNever(() => startByJob(any()));
    expect(find.byType(InterviewQuestionScreen), findsNothing);
    expect(find.text('Tell me about a project.'), findsNothing);
  });
}
