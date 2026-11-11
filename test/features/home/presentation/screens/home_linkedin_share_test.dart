import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rashed_app/app/routes_name.dart';
import 'package:rashed_app/app_localizations.dart';
import 'package:rashed_app/core/error/failures.dart';
import 'package:rashed_app/core/usecases/usecase.dart';
import 'package:rashed_app/features/home/presentation/screens/home_screen.dart';
import 'package:rashed_app/features/linkedin/presentation/linkedin_share_request.dart';
import 'package:rashed_app/features/performance/domain/entities/performance_summary.dart';
import 'package:rashed_app/features/performance/domain/usecases/get_performance_summary_usecase.dart';
import 'package:rashed_app/features/performance/presentation/cubit/performance_cubit.dart';

class MockGetSummary extends Mock implements GetPerformanceSummaryUseCase {}

void main() {
  late MockGetSummary getSummary;

  setUpAll(() {
    registerFallbackValue(NoParams());
  });

  setUp(() {
    getSummary = MockGetSummary();
    GetIt.instance.registerFactory(
      () => PerformanceCubit(getPerformanceSummaryUseCase: getSummary),
    );
  });

  tearDown(() async {
    await GetIt.instance.reset();
  });

  final newest = RecentInterview(
    simulationId: 'sim-newest',
    jobField: 'Programming',
    completedAt: DateTime.utc(2026, 11, 9),
    score: 70,
  );
  const older = RecentInterview(
    simulationId: 'sim-older',
    jobField: 'Support',
    completedAt: null,
    score: 99,
  );
  final datedOlder = RecentInterview(
    simulationId: 'sim-older',
    jobField: 'Support',
    completedAt: DateTime.utc(2026, 11, 1),
    score: 99,
  );

  Future<List<LinkedInShareRequest>> pumpHome(
    WidgetTester tester, {
    required Locale locale,
    bool openPerformance = false,
  }) async {
    final requests = <LinkedInShareRequest>[];
    await tester.pumpWidget(MaterialApp(
      key: ValueKey(locale.languageCode),
      locale: locale,
      supportedLocales: const [Locale('en'), Locale('ar')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const HomeScreen(),
      onGenerateRoute: (settings) {
        final arguments = settings.arguments;
        if (settings.name == RoutesName.linkedinShare &&
            arguments is LinkedInShareRequest) {
          requests.add(arguments);
        }
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const Scaffold(body: Text('share-screen')),
        );
      },
    ));
    await tester.pumpAndSettle();
    if (openPerformance) {
      await tester.tap(find.byIcon(Icons.show_chart_rounded));
      await tester.pumpAndSettle();
    }
    return requests;
  }

  test('a second share launch is ignored until the first finishes', () async {
    final guard = LinkedInShareLaunchGuard();
    final gate = Completer<void>();
    var calls = 0;

    final first = guard.run(() {
      calls++;
      return gate.future;
    });
    await guard.run(() async => calls++);

    expect(calls, 1);
    gate.complete();
    await first;
    await guard.run(() async => calls++);
    expect(calls, 2);
  });

  testWidgets('home stays disabled when no scored interview exists',
      (tester) async {
    when(() => getSummary(any())).thenAnswer(
      (_) async => const Right(PerformanceSummary(
        bestScore: 90,
        recentInterviews: [
          RecentInterview(simulationId: 'sim-unscored'),
        ],
      )),
    );

    await pumpHome(tester, locale: const Locale('en'));

    expect(find.byKey(const Key('home_share_loading')), findsNothing);
    expect(
      tester
          .widget<IgnorePointer>(
            find.byKey(const Key('home_share_card_disabled')),
          )
          .ignoring,
      isTrue,
    );
    expect(find.byKey(const Key('home_share_button')), findsNothing);
  });

  testWidgets('home shares the latest scored interview in English and Arabic',
      (tester) async {
    when(() => getSummary(any())).thenAnswer(
      (_) async => Right(PerformanceSummary(
        bestScore: 99,
        recentInterviews: [datedOlder, newest],
      )),
    );

    final english = await pumpHome(tester, locale: const Locale('en'));
    expect(find.text('Share your latest result'), findsOneWidget);
    expect(find.text('Share my result'), findsOneWidget);
    await tester.tap(find.byKey(const Key('home_share_button')));
    await tester.pumpAndSettle();

    expect(english, hasLength(1));
    expect(english.single.simulationId, 'sim-newest');
    expect(english.single.resultLabel, 'Programming · 70%');
    expect(find.text('share-screen'), findsOneWidget);

    final arabic = await pumpHome(tester, locale: const Locale('ar'));
    expect(find.text('شارك آخر نتيجة لك'), findsOneWidget);
    expect(find.text('مشاركة نتيجتي'), findsOneWidget);
    await tester.tap(find.byKey(const Key('home_share_button')));
    await tester.pumpAndSettle();
    expect(arabic.single.simulationId, 'sim-newest');
  });

  testWidgets('home shows a loading indicator and can retry a failure',
      (tester) async {
    final gate = Completer<Either<Failure, PerformanceSummary>>();
    when(() => getSummary(any())).thenAnswer((_) => gate.future);

    await tester.pumpWidget(_app());
    await tester.pump();

    expect(find.byKey(const Key('home_share_loading')), findsOneWidget);
    expect(find.byKey(const Key('home_share_button')), findsNothing);

    gate.complete(const Left(NetworkFailure('No internet connection')));
    await tester.pumpAndSettle();

    expect(find.text('No internet connection.'), findsOneWidget);
    expect(find.byKey(const Key('home_share_retry')), findsOneWidget);
    expect(find.byKey(const Key('home_share_button')), findsNothing);

    when(() => getSummary(any())).thenAnswer(
      (_) async => Right(PerformanceSummary(recentInterviews: [newest])),
    );
    await tester.tap(find.byKey(const Key('home_share_retry')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('home_share_button')), findsOneWidget);
    verify(() => getSummary(any())).called(2);
  });

  testWidgets('performance shares the best id and never the latest substitute',
      (tester) async {
    when(() => getSummary(any())).thenAnswer(
      (_) async => Right(PerformanceSummary(
        bestScore: 99,
        recentInterviews: [newest, older],
      )),
    );

    final blocked = await pumpHome(
      tester,
      locale: const Locale('en'),
      openPerformance: true,
    );
    expect(find.text('Share my result'), findsOneWidget);
    expect(find.text('مشاركة نتيجتي'), findsNothing);
    expect(
      tester
          .widget<IgnorePointer>(
            find.byKey(const Key('performance_best_share_disabled')),
          )
          .ignoring,
      isTrue,
    );
    expect(blocked, isEmpty);
    expect(find.text('share-screen'), findsNothing);

    when(() => getSummary(any())).thenAnswer(
      (_) async => Right(PerformanceSummary(
        bestScore: 99,
        bestSimulationId: 'sim-best',
        recentInterviews: [newest, datedOlder],
      )),
    );
    final requests = await pumpHome(
      tester,
      locale: const Locale('ar'),
      openPerformance: true,
    );
    expect(find.text('مشاركة نتيجتي'), findsOneWidget);
    expect(find.text('Share my result'), findsNothing);
    await tester.tap(find.byKey(const Key('performance_best_share')));
    await tester.pumpAndSettle();

    expect(requests, hasLength(1));
    expect(requests.single.simulationId, 'sim-best');
    expect(requests.single.resultLabel, '99%');
  });
}

Widget _app() {
  return const MaterialApp(
    locale: Locale('en'),
    supportedLocales: [Locale('en'), Locale('ar')],
    localizationsDelegates: [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: HomeScreen(),
  );
}
