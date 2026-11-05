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
import 'package:rashed_app/core/storage/secure_storage_service.dart';
import 'package:rashed_app/core/usecases/usecase.dart';
import 'package:rashed_app/features/cv/data/datasources/cv_local_datasource.dart';
import 'package:rashed_app/features/home/presentation/cubit/simulation_history_count_cubit.dart';
import 'package:rashed_app/features/home/presentation/screens/home_screen.dart';
import 'package:rashed_app/features/simulation/domain/entities/simulation_history_count.dart';
import 'package:rashed_app/features/simulation/domain/usecases/get_simulation_history_count_usecase.dart';
import 'package:rashed_app/features/simulation/presentation/interview_navigation.dart';

class MockGetCount extends Mock implements GetSimulationHistoryCountUseCase {}

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

void main() {
  setUpAll(() => registerFallbackValue(NoParams()));

  late MemoryStorage storage;
  late MockGetCount getCount;
  late SimulationHistoryCountCubit cubit;

  setUp(() {
    storage = MemoryStorage()..values['user_id'] = 'user-a';
    getCount = MockGetCount();
    cubit = SimulationHistoryCountCubit(
      getSimulationHistoryCount: getCount,
      secureStorage: storage,
    );
  });

  tearDown(() {
    resetInterviewEntryLock();
    cubit.close();
  });

  testWidgets('the home statistics container follows the simulation count',
      (tester) async {
    final gate = Completer<Either<Failure, SimulationHistoryCount>>();
    final responses = <Either<Failure, SimulationHistoryCount>>[
      const Right(SimulationHistoryCount(totalSimulations: 15)),
      const Right(SimulationHistoryCount(totalSimulations: 0)),
      const Left(ServerFailure('unavailable')),
      const Right(SimulationHistoryCount(totalSimulations: 7)),
    ];
    var calls = 0;
    when(() => getCount(any())).thenAnswer((_) {
      calls++;
      if (calls == 1) return gate.future;
      return Future.value(responses.removeAt(0));
    });

    final ticks = ValueNotifier(0);
    final homeKey = UniqueKey();
    addTearDown(ticks.dispose);
    final sl = GetIt.instance;
    sl.registerSingleton<SecureStorageService>(storage);
    sl.registerSingleton(CvLocalDataSource(storage: storage));
    addTearDown(sl.reset);

    await tester.pumpWidget(
      ValueListenableBuilder<int>(
        valueListenable: ticks,
        builder: (_, __, ___) => MaterialApp(
          locale: const Locale('ar'),
          supportedLocales: const [Locale('ar'), Locale('en')],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          onGenerateRoute: (settings) {
            if (settings.name == RoutesName.simulationSetup) {
              return MaterialPageRoute<void>(
                settings: settings,
                builder: (_) => const Scaffold(body: Text('interview-open')),
              );
            }
            if (settings.name == RoutesName.login) {
              return MaterialPageRoute<void>(
                settings: settings,
                builder: (_) => const Scaffold(body: Text('login-screen')),
              );
            }
            return null;
          },
          home: HomeScreen(
            key: homeKey,
            simulationHistoryCountCubit: cubit,
          ),
        ),
      ),
    );
    for (var frame = 0; frame < 20; frame++) {
      await tester.pump(const Duration(milliseconds: 50));
      if (find
          .byKey(const Key('sim_history_count_loading'))
          .evaluate()
          .isNotEmpty) {
        break;
      }
    }

    expect(find.byKey(const Key('sim_history_count_loading')), findsOneWidget);
    expect(find.text('عدد مرات المحاكاة'), findsOneWidget);
    expect(find.text('0'), findsNothing);
    expect(find.text('4'), findsNothing);
    ticks.value = 1;
    await tester.pump();
    expect(calls, 1);

    gate.complete(const Right(SimulationHistoryCount(totalSimulations: 12)));
    await tester.pumpAndSettle();
    expect(find.text('12'), findsOneWidget);
    expect(find.byKey(const Key('sim_history_count')), findsOneWidget);
    expect(calls, 1);

    await tester.ensureVisible(find.text('ابدأ المحاكاة').first);
    await tester.tap(find.text('ابدأ المحاكاة').first);
    await tester.pumpAndSettle();
    expect(find.text('interview-open'), findsOneWidget);
    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pumpAndSettle();
    expect(find.text('15'), findsOneWidget);
    expect(calls, 2);

    await tester.ensureVisible(find.text('ابدأ المحاكاة').first);
    await tester.tap(find.text('ابدأ المحاكاة').first);
    await tester.pumpAndSettle();
    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pumpAndSettle();
    expect(find.text('0'), findsOneWidget);
    expect(find.text('—'), findsNothing);

    await tester.ensureVisible(find.text('ابدأ المحاكاة').first);
    await tester.tap(find.text('ابدأ المحاكاة').first);
    await tester.pumpAndSettle();
    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pumpAndSettle();
    expect(find.text('—'), findsOneWidget);
    expect(find.text('0'), findsNothing);
    expect(find.text('unavailable'), findsNothing);

    await tester.tap(find.byKey(const Key('sim_history_count_retry')));
    await tester.pumpAndSettle();
    expect(find.text('7'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.logout));
    await tester.pumpAndSettle();
    expect(find.text('login-screen'), findsOneWidget);
    expect(find.text('7'), findsNothing);
    expect(find.text('12'), findsNothing);
    expect(cubit.state, isA<SimulationHistoryCountInitial>());
  });
}
