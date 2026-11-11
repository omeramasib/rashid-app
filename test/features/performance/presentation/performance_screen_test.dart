import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rashed_app/app/routes_name.dart';
import 'package:rashed_app/app_localizations.dart';
import 'package:rashed_app/core/usecases/usecase.dart';
import 'package:rashed_app/features/home/presentation/screens/home_screen.dart';
import 'package:rashed_app/features/linkedin/presentation/linkedin_share_request.dart';
import 'package:rashed_app/features/performance/domain/entities/performance_summary.dart';
import 'package:rashed_app/features/performance/domain/usecases/get_performance_summary_usecase.dart';
import 'package:rashed_app/features/performance/presentation/cubit/performance_cubit.dart';
import 'package:rashed_app/features/simulation/presentation/cubit/interview_cubit.dart';

class MockGetSummary extends Mock implements GetPerformanceSummaryUseCase {}

class MockInterviewCubit extends Mock implements InterviewCubit {}

void main() {
  late MockGetSummary getSummary;
  late MockInterviewCubit interviewCubit;
  late Object? resultArguments;

  setUpAll(() {
    registerFallbackValue(NoParams());
  });

  setUp(() {
    getSummary = MockGetSummary();
    interviewCubit = MockInterviewCubit();
    resultArguments = null;
    when(() => interviewCubit.openCompletedReport(any()))
        .thenAnswer((_) async {});
    final sl = GetIt.instance;
    sl.registerFactory(
      () => PerformanceCubit(getPerformanceSummaryUseCase: getSummary),
    );
    sl.registerFactory<InterviewCubit>(() => interviewCubit);
  });

  tearDown(() async {
    await GetIt.instance.reset();
  });

  testWidgets(
      'shows empty scores and opens the existing result route from history',
      (tester) async {
    when(() => getSummary(any())).thenAnswer(
      (_) async => const Right(PerformanceSummary(
        totalSimulations: 3,
        recentInterviews: [],
      )),
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          DefaultMaterialLocalizations.delegate,
          DefaultWidgetsLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en'),
          Locale('ar'),
        ],
        home: const HomeScreen(),
        onGenerateRoute: (settings) {
          if (settings.name == RoutesName.simulationResult) {
            resultArguments = settings.arguments;
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => const Scaffold(body: Text('result-screen')),
            );
          }
          return null;
        },
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.show_chart_rounded));
    await tester.pumpAndSettle();

    expect(
      tester.widget<Text>(find.byKey(const Key('performance_total'))).data,
      '3',
    );
    expect(
      tester.widget<Text>(find.byKey(const Key('performance_average'))).data,
      '—',
    );
    expect(
      tester.widget<Text>(find.byKey(const Key('performance_best'))).data,
      '—',
    );
    expect(find.text('No completed interviews yet'), findsOneWidget);
    expect(find.text('72%'), findsNothing);
    expect(find.text('85%'), findsNothing);
    expect(find.text('Programming simulation interview'), findsNothing);

    await tester.tap(find.byIcon(Icons.home_outlined));
    await tester.pumpAndSettle();

    when(() => getSummary(any())).thenAnswer(
      (_) async => const Right(PerformanceSummary(
        totalSimulations: 1,
        averageScore: 72,
        bestScore: 85,
        recentInterviews: [
          RecentInterview(
            simulationId: 'sim-9',
            performanceStatus: PerformanceStatus.excellent,
            score: 85,
          ),
        ],
      )),
    );
    await tester.tap(find.byIcon(Icons.show_chart_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Mock Interview'), findsOneWidget);
    expect(find.text('Excellent'), findsOneWidget);
    expect(find.text('72%'), findsOneWidget);
    expect(find.text('85%'), findsOneWidget);
    await tester.tap(find.byKey(const Key('performance_interview_sim-9')));
    await tester.pumpAndSettle();

    expect(find.text('result-screen'), findsOneWidget);
    expect(resultArguments, same(interviewCubit));
    verify(() => interviewCubit.openCompletedReport('sim-9')).called(1);
  });

  testWidgets('shares the latest home result and not an inferred best result',
      (tester) async {
    when(() => getSummary(any())).thenAnswer(
      (_) async => const Right(PerformanceSummary(
        bestScore: 85,
        recentInterviews: [
          RecentInterview(
            simulationId: 'sim-9',
            jobField: 'Programming',
            score: 85,
            performanceStatus: PerformanceStatus.excellent,
          ),
        ],
      )),
    );
    String? routeName;
    Object? shareArguments;
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('en'),
      initialRoute: '/',
      localizationsDelegates: const [
        AppLocalizations.delegate,
        DefaultMaterialLocalizations.delegate,
        DefaultWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('ar')],
      home: const HomeScreen(),
      onGenerateRoute: (settings) {
        routeName = settings.name;
        shareArguments = settings.arguments;
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const SizedBox.shrink(),
        );
      },
    ));
    await tester.pumpAndSettle();

    expect(find.text('Share your latest result'), findsOneWidget);
    await tester.tap(find.byKey(const Key('home_share_button')));
    await tester.pumpAndSettle();

    expect(routeName, RoutesName.linkedinShare);
    final homeRequest = shareArguments! as LinkedInShareRequest;
    expect(homeRequest.simulationId, 'sim-9');
    expect(homeRequest.resultLabel, 'Programming · 85%');
    verifyNever(() => interviewCubit.openCompletedReport(any()));

    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.show_chart_rounded));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<IgnorePointer>(
            find.byKey(const Key('performance_best_share_disabled')),
          )
          .ignoring,
      isTrue,
    );
    expect(find.text('Share my result'), findsOneWidget);

    await tester.tap(find.byKey(const Key('performance_share_sim-9')));
    await tester.pumpAndSettle();

    expect(routeName, RoutesName.linkedinShare);
    final request = shareArguments! as LinkedInShareRequest;
    expect(request.simulationId, 'sim-9');
    expect(request.resultLabel, 'Programming · 85%');
    verifyNever(() => interviewCubit.openCompletedReport(any()));
  });
}
