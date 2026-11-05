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
import 'package:rashed_app/features/simulation/domain/entities/interview_finish_result.dart';
import 'package:rashed_app/features/simulation/domain/entities/interview_question.dart';
import 'package:rashed_app/features/simulation/domain/entities/interview_report.dart';
import 'package:rashed_app/features/simulation/domain/entities/interview_start_response.dart';
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
  ScriptedAdGate({this.finishShow, this.finishError});

  final Completer<void>? finishShow;
  final Object? finishError;
  final List<AdPlacement> placementsShown = <AdPlacement>[];

  @override
  Future<void> preload([
    AdPlacement placement = AdPlacement.interviewStart,
  ]) async {}

  @override
  Future<void> showIfEligible([
    AdPlacement placement = AdPlacement.interviewStart,
  ]) {
    placementsShown.add(placement);
    if (placement == AdPlacement.interviewFinish && finishError != null) {
      return Future<void>.error(finishError!);
    }
    if (placement == AdPlacement.interviewFinish) {
      return finishShow?.future ?? Future<void>.value();
    }
    return Future<void>.value();
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
  const finished = InterviewFinishResult(
    simulationId: 'sim-1',
    score: 82,
    reportSummary: 'Strong examples.',
  );
  const report = InterviewReport(
    simulationId: 'sim-1',
    score: 82,
    questions: [],
  );

  late MockStartByJob startByJob;
  late MockFinish finish;
  late MockReport getReport;
  late MockProfile profile;
  late int reportPushes;

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
    registerFallbackValue(const FinishInterviewParams(simulationId: 'sim'));
    registerFallbackValue(const GetInterviewReportParams(simulationId: 'sim'));
    registerFallbackValue(NoParams());
  });

  setUp(() {
    startByJob = MockStartByJob();
    finish = MockFinish();
    getReport = MockReport();
    profile = MockProfile();
    reportPushes = 0;
    when(() => profile(any())).thenAnswer((_) async => const Right(null));
    when(() => startByJob(any())).thenAnswer((_) async => const Right(started));
    when(() => finish(any())).thenAnswer((_) async => const Right(finished));
    when(() => getReport(any())).thenAnswer((_) async => const Right(report));
  });

  InterviewCubit cubitFor(ScriptedAdGate gate) {
    return InterviewCubit(
      startInterviewByJobUseCase: startByJob,
      startInterviewByJobDescriptionUseCase: MockStartByDescription(),
      retryInterviewGenerationUseCase: MockRetry(),
      submitAnswerUseCase: MockSubmit(),
      finishInterviewUseCase: finish,
      getInterviewReportUseCase: getReport,
      getSimulationsHistoryUseCase: MockHistory(),
      getMyCvProfileUseCase: profile,
      adGate: gate,
    );
  }

  Future<void> openLastQuestion(
    WidgetTester tester,
    InterviewCubit cubit,
  ) async {
    await cubit.start(
      mode: InterviewStartMode.byJob,
      input: 'Nurse',
      interviewType: 'technical',
      difficulty: 'medium',
      language: 'English',
      numQuestions: 5,
    );
    cubit.next();
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
        child: const InterviewEvaluationScreen(),
      ),
      onGenerateRoute: (settings) {
        if (settings.name == RoutesName.simulationResult) {
          reportPushes += 1;
          return MaterialPageRoute<void>(
            settings: settings,
            builder: (_) => const SizedBox(key: Key('interview_report_route')),
          );
        }
        return null;
      },
    ));
    await tester.pumpAndSettle();
  }

  int finishShows(ScriptedAdGate gate) {
    return gate.placementsShown
        .where((placement) => placement == AdPlacement.interviewFinish)
        .length;
  }

  InterviewActionButton finishButton(WidgetTester tester) {
    return tester.widget<InterviewActionButton>(
      find.byKey(const Key('interview_next_button')),
    );
  }

  testWidgets('a saved interview shows the ad before the report, once',
      (tester) async {
    final finishShow = Completer<void>();
    final gate = ScriptedAdGate(finishShow: finishShow);
    final cubit = cubitFor(gate);
    await openLastQuestion(tester, cubit);

    await tester.tap(find.byKey(const Key('interview_next_button')));
    await tester.pump();
    expect(finishShows(gate), 1);
    expect(cubit.state.phase, InterviewPhase.finishing);
    expect(find.byKey(const Key('interview_report_route')), findsNothing);
    verifyNever(() => getReport(any()));
    expect(finishButton(tester).busy, isTrue);

    await tester.tap(find.byKey(const Key('interview_next_button')));
    await tester.pump();
    expect(finishShows(gate), 1);
    verify(() => finish(any())).called(1);

    finishShow.complete();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('interview_report_route')), findsOneWidget);
    expect(reportPushes, 1);
    expect(cubit.state.phase, InterviewPhase.finished);
    verify(() => getReport(any())).called(1);
  });

  testWidgets('an unavailable finish ad opens the report immediately',
      (tester) async {
    final gate = ScriptedAdGate();
    final cubit = cubitFor(gate);
    await openLastQuestion(tester, cubit);
    await tester.tap(find.byKey(const Key('interview_next_button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('interview_report_route')), findsOneWidget);
    expect(reportPushes, 1);
    verify(() => finish(any())).called(1);
    verify(() => getReport(any())).called(1);
  });

  testWidgets('a finish ad that fails to show still opens the report once',
      (tester) async {
    final gate = ScriptedAdGate(finishError: StateError('show'));
    final cubit = cubitFor(gate);
    await openLastQuestion(tester, cubit);
    await tester.tap(find.byKey(const Key('interview_next_button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('interview_report_route')), findsOneWidget);
    expect(reportPushes, 1);
    verify(() => finish(any())).called(1);
    expect(cubit.state.phase, InterviewPhase.finished);
  });

  testWidgets('a failed finish keeps the error and does not show an ad',
      (tester) async {
    when(() => finish(any())).thenAnswer(
      (_) async => const Left(NetworkFailure('No internet connection')),
    );
    final gate = ScriptedAdGate();
    final cubit = cubitFor(gate);
    await openLastQuestion(tester, cubit);
    await tester.tap(find.byKey(const Key('interview_next_button')));
    await tester.pumpAndSettle();
    expect(find.text('No internet connection.'), findsOneWidget);
    expect(find.byKey(const Key('interview_report_route')), findsNothing);
    expect(reportPushes, 0);
    expect(finishShows(gate), 0);
    expect(cubit.state.phase, InterviewPhase.inProgress);
    verify(() => finish(any())).called(1);
    verifyNever(() => getReport(any()));
  });

  testWidgets('disposal during the finish ad does not open the report',
      (tester) async {
    final finishShow = Completer<void>();
    final gate = ScriptedAdGate(finishShow: finishShow);
    final cubit = cubitFor(gate);
    await openLastQuestion(tester, cubit);
    await tester.tap(find.byKey(const Key('interview_next_button')));
    await tester.pump();
    expect(finishShows(gate), 1);
    verify(() => finish(any())).called(1);

    await tester.pumpWidget(const SizedBox.shrink());
    finishShow.complete();
    await tester.pump();
    verifyNever(() => getReport(any()));
    expect(find.byKey(const Key('interview_report_route')), findsNothing);
    expect(reportPushes, 0);
  });
}
