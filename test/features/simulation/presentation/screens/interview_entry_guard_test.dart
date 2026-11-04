import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rashed_app/app/app_routes.dart';
import 'package:rashed_app/app/routes_name.dart';
import 'package:rashed_app/app_localizations.dart';
import 'package:rashed_app/core/error/failures.dart';
import 'package:rashed_app/core/storage/secure_storage_service.dart';
import 'package:rashed_app/core/usecases/usecase.dart';
import 'package:rashed_app/features/auth/presentation/screens/login_screen.dart';
import 'package:rashed_app/features/cv/data/datasources/cv_local_datasource.dart';
import 'package:rashed_app/features/cv/data/models/cv_model.dart';
import 'package:rashed_app/features/cv/domain/entities/cv_analysis_result.dart';
import 'package:rashed_app/features/cv/domain/entities/cv_profile.dart';
import 'package:rashed_app/features/cv/domain/entities/selected_cv_file.dart';
import 'package:rashed_app/features/cv/domain/usecases/analyze_cv_usecase.dart';
import 'package:rashed_app/features/cv/domain/usecases/delete_skill_usecase.dart';
import 'package:rashed_app/features/cv/domain/usecases/get_my_cv_profile_usecase.dart';
import 'package:rashed_app/features/cv/domain/usecases/update_skills_usecase.dart';
import 'package:rashed_app/features/cv/domain/usecases/upload_cv_usecase.dart';
import 'package:rashed_app/features/cv/presentation/cubit/cv_cubit.dart';
import 'package:rashed_app/features/home/presentation/screens/home_screen.dart';
import 'package:rashed_app/features/profile/presentation/screens/complete_profile_screen.dart';
import 'package:rashed_app/features/simulation/domain/entities/interview_question.dart';
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
import 'package:rashed_app/features/simulation/presentation/cubit/interview_entry_cubit.dart';
import 'package:rashed_app/features/simulation/presentation/interview_navigation.dart';
import 'package:rashed_app/features/simulation/presentation/screens/interview_entry_screen.dart';
import 'package:rashed_app/features/simulation/presentation/screens/interview_setup_screen.dart';
import 'package:rashed_app/features/splash/presentation/screens/splash_screen.dart';

class MockProfile extends Mock implements GetMyCvProfileUseCase {}

class MockUpload extends Mock implements UploadCvUseCase {}

class MockAnalyze extends Mock implements AnalyzeCvUseCase {}

class MockUpdateSkills extends Mock implements UpdateSkillsUseCase {}

class MockStartByJob extends Mock implements StartInterviewByJobUseCase {}

class MockStartByDescription extends Mock
    implements StartInterviewByJobDescriptionUseCase {}

class MockRetry extends Mock implements RetryInterviewGenerationUseCase {}

class MockSubmit extends Mock implements SubmitAnswerUseCase {}

class MockFinish extends Mock implements FinishInterviewUseCase {}

class MockReport extends Mock implements GetInterviewReportUseCase {}

class MockHistory extends Mock implements GetSimulationsHistoryUseCase {}

class MemoryStorage extends Fake implements SecureStorageService {
  final values = <String, String>{};

  @override
  Future<String?> read({required String key}) async => values[key];

  @override
  Future<void> write({required String key, required String? value}) async {
    if (value == null) {
      values.remove(key);
    } else {
      values[key] = value;
    }
  }

  @override
  Future<void> delete({required String key}) async => values.remove(key);

  @override
  Future<void> deleteAll() async => values.clear();
}

class LoadedLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const LoadedLocalizationsDelegate(this.loaded);

  final Map<String, AppLocalizations> loaded;

  @override
  bool isSupported(Locale locale) => loaded.containsKey(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) =>
      SynchronousFuture(loaded[locale.languageCode]!);

  @override
  bool shouldReload(LoadedLocalizationsDelegate old) => false;
}

void ignoreProgress(int sent, int total) {}

void main() {
  final loaded = <String, AppLocalizations>{};
  const processed = CvProfile(
    cvId: 'cv-1',
    status: CvAnalysisStatus.processed,
    fullName: 'Example User',
    jobTitles: ['Flutter Developer', 'Mobile Engineer'],
    skills: ['Flutter', 'Dart'],
  );
  const started = InterviewStartResponse(
    simulationId: 'sim-1',
    interviewSettingId: 'setting-1',
    questions: [
      InterviewQuestion(id: 'q-1', questionText: 'Tell me more.', position: 1),
    ],
  );
  final pdf = SelectedCvFile(
    name: 'resume.pdf',
    sizeBytes: 12,
    bytes: Uint8List.fromList('%PDF-1.4\n'.codeUnits),
  );

  late MockProfile profile;
  late MockUpload upload;
  late MockAnalyze analyze;
  late MockStartByJob startByJob;
  late MemoryStorage storage;
  late CvCubit cvCubit;
  late List<InterviewEntryCubit> entryCubits;
  late int setupCount;
  late int entryRoutes;

  setUpAll(() async {
    for (final code in ['en', 'ar']) {
      final strings = AppLocalizations(Locale(code));
      await strings.loadJsonLanguage();
      loaded[code] = strings;
    }
    registerFallbackValue(NoParams());
    registerFallbackValue(UploadCvParams(
      bytes: Uint8List(0),
      fileName: 'a.pdf',
      onProgress: ignoreProgress,
    ));
    registerFallbackValue(const AnalyzeCvParams(cvId: 'cv'));
    registerFallbackValue(const UpdateSkillsParams(skills: []));
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
  });

  setUp(() {
    resetInterviewEntryLock();
    profile = MockProfile();
    upload = MockUpload();
    analyze = MockAnalyze();
    startByJob = MockStartByJob();
    storage = MemoryStorage()..values['user_id'] = 'user-a';
    entryCubits = [];
    setupCount = 0;
    entryRoutes = 0;
    when(() => profile(any())).thenAnswer((_) async => const Right(null));
    when(() => upload.cancel()).thenAnswer((_) {});
    when(() => analyze.cancel()).thenAnswer((_) {});
    when(() => startByJob(any())).thenAnswer((_) async => const Right(started));
    cvCubit = CvCubit(
      uploadCvUseCase: upload,
      analyzeCvUseCase: analyze,
      updateSkillsUseCase: MockUpdateSkills(),
      deleteSkillUseCase: _UnusedDelete(),
      getMyCvProfileUseCase: profile,
      localDataSource: CvLocalDataSource(storage: storage),
      secureStorage: storage,
    );
  });

  tearDown(() async {
    resetInterviewEntryLock();
    for (final cubit in entryCubits) {
      await cubit.close();
    }
    await cvCubit.close();
  });

  InterviewCubit buildInterview() {
    return InterviewCubit(
      startInterviewByJobUseCase: startByJob,
      startInterviewByJobDescriptionUseCase: MockStartByDescription(),
      retryInterviewGenerationUseCase: MockRetry(),
      submitAnswerUseCase: MockSubmit(),
      finishInterviewUseCase: MockFinish(),
      getInterviewReportUseCase: MockReport(),
      getSimulationsHistoryUseCase: MockHistory(),
      getMyCvProfileUseCase: profile,
    );
  }

  Future<void> pumpUntil(WidgetTester tester, Finder finder) async {
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      if (finder.evaluate().isNotEmpty) return;
    }
  }

  Future<void> pumpHome(WidgetTester tester, {Widget? home}) {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    return tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        supportedLocales: const [Locale('en'), Locale('ar')],
        localizationsDelegates: [
          LoadedLocalizationsDelegate(loaded),
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: home ?? const HomeScreen(),
        onGenerateRoute: (settings) {
          if (settings.name == RoutesName.simulationSetup) {
            entryRoutes++;
            final mode = settings.arguments is InterviewStartMode
                ? settings.arguments as InterviewStartMode
                : InterviewStartMode.byJob;
            final cubit = InterviewEntryCubit(getMyCvProfileUseCase: profile);
            entryCubits.add(cubit);
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => InterviewEntryScreen(
                mode: mode,
                entryCubit: cubit,
                createSetupCubit: (cv) {
                  setupCount++;
                  final interview = buildInterview();
                  interview.adoptProcessedProfile(cv);
                  return interview;
                },
              ),
            );
          }
          if (settings.name == RoutesName.completeProfile) {
            final mode = settings.arguments is InterviewStartMode
                ? settings.arguments as InterviewStartMode
                : null;
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => BlocProvider.value(
                value: cvCubit,
                child: CompleteProfileScreen(resumeInterview: mode),
              ),
            );
          }
          if (settings.name == RoutesName.login) {
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => const Scaffold(body: Text('signed-out')),
            );
          }
          return MaterialPageRoute<void>(
            settings: settings,
            builder: (_) => const Scaffold(body: Text('unexpected-route')),
          );
        },
      ),
    );
  }

  Future<void> openField(WidgetTester tester) async {
    await pumpHome(tester);
    await tester.tap(find.text('Simulation by career field'));
    await tester.pumpAndSettle();
  }

  testWidgets('opening home does not check the CV or leave home',
      (tester) async {
    await pumpHome(tester);
    await tester.pumpAndSettle();
    expect(find.text('Home'), findsOneWidget);
    expect(find.byType(InterviewEntryScreen), findsNothing);
    expect(find.byType(CompleteProfileScreen), findsNothing);
    expect(find.byType(InterviewSetupScreen), findsNothing);
    verifyNever(() => profile(any()));
    verifyNever(() => analyze(any()));
  });

  testWidgets('no CV shows a loader and then the completion screen',
      (tester) async {
    final gate = Completer<Either<Failure, CvProfile?>>();
    when(() => profile(any())).thenAnswer((_) => gate.future);
    await pumpHome(tester);
    await tester.tap(find.text('Simulation by career field'));
    await pumpUntil(tester, find.byKey(const Key('interview_entry_loading')));
    expect(find.byKey(const Key('interview_entry_loading')), findsOneWidget);
    expect(find.byType(CompleteProfileScreen), findsNothing);
    expect(find.byType(InterviewSetupScreen), findsNothing);
    gate.complete(const Right(null));
    await tester.pumpAndSettle();
    expect(find.byType(CompleteProfileScreen), findsOneWidget);
    expect(find.byType(InterviewSetupScreen), findsNothing);
    expect(find.byType(InterviewEntryScreen), findsNothing);
    verifyNever(() => analyze(any()));
  });

  testWidgets('a processed CV opens setup with the saved job titles',
      (tester) async {
    when(() => profile(any())).thenAnswer((_) async => const Right(processed));
    await openField(tester);
    expect(find.byType(InterviewSetupScreen), findsOneWidget);
    expect(
      tester
          .widget<InterviewSetupScreen>(find.byType(InterviewSetupScreen))
          .initialMode,
      InterviewStartMode.byJob,
    );
    expect(find.byType(CompleteProfileScreen), findsNothing);
    expect(find.byKey(const Key('interview_cv_job_title_dropdown')),
        findsOneWidget);
    expect(find.text('Flutter Developer'), findsWidgets);
    expect(
        find.byKey(const Key('interview_cv_job_title_other')), findsOneWidget);
    expect(setupCount, 1);
    await tester.ensureVisible(find.byKey(const Key('interview_start_button')));
    await tester.tap(find.byKey(const Key('interview_start_button')));
    await tester.pumpAndSettle();
    final params = verify(() => startByJob(captureAny())).captured.single
        as StartInterviewByJobParams;
    expect(params.jobField, 'Flutter Developer');
    expect(params.cvId, 'cv-1');
    verify(() => profile(any())).called(1);
    verifyNever(() => analyze(any()));
  });

  testWidgets('pending, in-progress, and failed CVs open completion',
      (tester) async {
    for (final status in [
      CvAnalysisStatus.pending,
      CvAnalysisStatus.inProgress,
      CvAnalysisStatus.failed,
    ]) {
      resetInterviewEntryLock();
      await tester.pumpWidget(const SizedBox.shrink());
      final gate = Completer<Either<Failure, CvProfile?>>();
      when(() => profile(any())).thenAnswer((_) => gate.future);
      await pumpHome(tester);
      await tester.pump();
      await tester.tap(find.text('Simulation by career field'));
      await tester.pump();
      gate.complete(Right(CvProfile(
        cvId: 'cv-1',
        status: status,
        jobTitles: const ['Flutter Developer'],
      )));
      await pumpUntil(tester, find.byType(CompleteProfileScreen));
      expect(find.byType(CompleteProfileScreen), findsOneWidget);
      expect(find.byType(InterviewSetupScreen), findsNothing);
      expect(setupCount, 0);
      verifyNever(() => analyze(any()));
    }
  });

  testWidgets('a network failure offers retry and does not redirect',
      (tester) async {
    var calls = 0;
    when(() => profile(any())).thenAnswer((_) async {
      calls++;
      if (calls == 1) {
        return const Left(NetworkFailure('No internet connection'));
      }
      return const Right(processed);
    });
    await pumpHome(tester);
    await tester.tap(find.text('Simulation by career field'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('interview_entry_error')), findsOneWidget);
    expect(find.byKey(const Key('interview_entry_retry')), findsOneWidget);
    expect(find.text('No internet connection.'), findsOneWidget);
    expect(find.byType(CompleteProfileScreen), findsNothing);
    expect(find.byType(InterviewSetupScreen), findsNothing);

    await tester.tap(find.byKey(const Key('interview_entry_retry')));
    await tester.pumpAndSettle();
    expect(find.byType(InterviewSetupScreen), findsOneWidget);
    expect(calls, 2);
    expect(setupCount, 1);
    verifyNever(() => analyze(any()));
  });

  testWidgets('401 leaves the interview flow for login', (tester) async {
    when(() => profile(any())).thenAnswer(
      (_) async => const Left(UnauthorizedFailure('unauthorized')),
    );
    await pumpHome(tester);
    await tester.tap(find.text('Simulation by career field'));
    await tester.pumpAndSettle();
    expect(find.text('signed-out'), findsOneWidget);
    expect(find.byType(HomeScreen), findsNothing);
    expect(find.byType(CompleteProfileScreen), findsNothing);
    expect(find.byType(InterviewSetupScreen), findsNothing);
    verify(() => profile(any())).called(1);
    verifyNever(() => analyze(any()));
  });

  testWidgets('two quick taps start one CV check', (tester) async {
    final gate = Completer<Either<Failure, CvProfile?>>();
    when(() => profile(any())).thenAnswer((_) => gate.future);
    await pumpHome(
      tester,
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () {
            openInterviewSimulation(context, InterviewStartMode.byJob);
            openInterviewSimulation(
              context,
              InterviewStartMode.byJobDescription,
            );
          },
          child: const Text('open-twice'),
        ),
      ),
    );
    await tester.tap(find.text('open-twice'));
    expect(entryRoutes, 1);
    await tester.pump();
    verify(() => profile(any())).called(1);
    gate.complete(const Right(null));
    await tester.pumpAndSettle();
    expect(find.byType(CompleteProfileScreen), findsOneWidget);
    expect(
      tester
          .widget<CompleteProfileScreen>(find.byType(CompleteProfileScreen))
          .resumeInterview,
      InterviewStartMode.byJob,
    );
    expect(entryRoutes, 1);
  });

  testWidgets('a later entry checks the signed-in account again',
      (tester) async {
    when(() => profile(any())).thenAnswer((_) async => const Right(processed));
    await openField(tester);
    expect(find.text('Flutter Developer'), findsWidgets);
    when(() => profile(any())).thenAnswer((_) async => const Right(null));
    await tester.tap(find.byKey(const Key('interview_back_button')));
    await tester.pumpAndSettle();
    expect(find.text('Home'), findsOneWidget);
    await tester.tap(find.text('Simulation by career field'));
    await tester.pumpAndSettle();
    expect(find.byType(CompleteProfileScreen), findsOneWidget);
    expect(find.byType(InterviewSetupScreen), findsNothing);
    expect(setupCount, 1);
  });

  testWidgets('successful analysis returns to setup on the career field',
      (tester) async {
    var reads = 0;
    when(() => profile(any())).thenAnswer((_) async {
      reads++;
      if (reads < 3) return const Right(null);
      return const Right(processed);
    });
    when(() => upload(any())).thenAnswer((invocation) async {
      final params = invocation.positionalArguments.first as UploadCvParams;
      params.onProgress(params.bytes.length, params.bytes.length);
      return const Right(
        CvModel(cvId: 'cv-1', fileUrl: 'https://signed.example'),
      );
    });
    when(() => analyze(any())).thenAnswer(
      (_) async => const Right(CvAnalysisResult(
        fullName: 'Example User',
        jobTitles: ['Flutter Developer'],
        skills: ['Flutter'],
      )),
    );
    await pumpHome(tester);
    await tester.tap(find.text('Simulation for a specific job description'));
    await tester.pumpAndSettle();
    expect(find.byType(CompleteProfileScreen), findsOneWidget);
    expect(
      tester
          .widget<CompleteProfileScreen>(find.byType(CompleteProfileScreen))
          .resumeInterview,
      InterviewStartMode.byJobDescription,
    );

    await cvCubit.selectFile(pdf);
    await cvCubit.startAnalysis();
    await tester.pumpAndSettle();

    expect(find.byType(InterviewSetupScreen), findsOneWidget);
    expect(
      tester
          .widget<InterviewSetupScreen>(find.byType(InterviewSetupScreen))
          .initialMode,
      InterviewStartMode.byJob,
    );
    expect(find.byKey(const Key('interview_description_input')), findsNothing);
    final careerField = tester.widget<ChoiceChip>(
      find.widgetWithText(ChoiceChip, 'Career field'),
    );
    expect(careerField.selected, isTrue);
    expect(find.byKey(const Key('interview_cv_used')), findsOneWidget);
    expect(setupCount, 1);
    expect(reads, 4);
    verify(() => analyze(any())).called(1);
    verify(() => upload(any())).called(1);
  });

  testWidgets('a normal profile screen does not leave for interview setup',
      (tester) async {
    when(() => profile(any())).thenAnswer((_) async => const Right(processed));
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        supportedLocales: const [Locale('en'), Locale('ar')],
        localizationsDelegates: [
          LoadedLocalizationsDelegate(loaded),
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: BlocProvider.value(
          value: cvCubit,
          child: const CompleteProfileScreen(),
        ),
        onGenerateRoute: (settings) {
          return MaterialPageRoute<void>(
            builder: (_) => Text('unexpected ${settings.name}'),
          );
        },
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Example User'), findsOneWidget);
    expect(find.byType(CompleteProfileScreen), findsOneWidget);
    expect(find.byType(InterviewSetupScreen), findsNothing);
    expect(find.textContaining('unexpected'), findsNothing);
    verifyNever(() => analyze(any()));
    verifyNever(() => upload(any()));
  });

  testWidgets('home, login, and splash routes do not run the interview guard',
      (tester) async {
    late BuildContext context;
    await tester.pumpWidget(MaterialApp(
      home: Builder(builder: (value) {
        context = value;
        return const SizedBox();
      }),
    ));

    Widget built(String name, [Object? arguments]) {
      final route = Routes.onGenerateRouted(
        RouteSettings(name: name, arguments: arguments),
      ) as CupertinoPageRoute<dynamic>;
      return route.builder(context);
    }

    expect(built(RoutesName.home), isA<HomeScreen>());
    expect(built(RoutesName.login), isA<LoginScreen>());
    expect(built(RoutesName.splash), isA<SplashScreen>());
    final entry = built(
      RoutesName.simulationSetup,
      InterviewStartMode.byJobDescription,
    );
    expect(entry, isA<InterviewEntryScreen>());
    expect(
      (entry as InterviewEntryScreen).mode,
      InterviewStartMode.byJobDescription,
    );
    expect(built(RoutesName.completeProfile), isA<BlocProvider<CvCubit>>());
    verifyNever(() => profile(any()));
  });
}

class _UnusedDelete extends Fake implements DeleteSkillUseCase {}
