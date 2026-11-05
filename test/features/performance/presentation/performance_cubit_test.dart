import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rashed_app/core/error/failures.dart';
import 'package:rashed_app/core/usecases/usecase.dart';
import 'package:rashed_app/features/performance/domain/entities/performance_summary.dart';
import 'package:rashed_app/features/performance/domain/usecases/get_performance_summary_usecase.dart';
import 'package:rashed_app/features/performance/presentation/cubit/performance_cubit.dart';

class MockGetPerformanceSummary extends Mock
    implements GetPerformanceSummaryUseCase {}

void main() {
  const summary = PerformanceSummary(
    totalSimulations: 3,
    averageScore: 72,
    bestScore: 85,
    recentInterviews: [
      RecentInterview(
        simulationId: 'sim-1',
        jobField: 'برمجة',
        score: 85,
        performanceStatus: PerformanceStatus.excellent,
      ),
    ],
  );
  const refreshed = PerformanceSummary(
    totalSimulations: 4,
    averageScore: 74,
    bestScore: 90,
  );

  late MockGetPerformanceSummary getSummary;

  setUpAll(() {
    registerFallbackValue(NoParams());
  });

  setUp(() {
    getSummary = MockGetPerformanceSummary();
  });

  PerformanceCubit build() {
    return PerformanceCubit(getPerformanceSummaryUseCase: getSummary);
  }

  blocTest<PerformanceCubit, PerformanceState>(
    'emits loading then success',
    build: build,
    setUp: () {
      when(() => getSummary(any()))
          .thenAnswer((_) async => const Right(summary));
    },
    act: (cubit) => cubit.load(),
    expect: () => const [
      PerformanceLoading(),
      PerformanceSuccess(summary),
    ],
  );

  blocTest<PerformanceCubit, PerformanceState>(
    'emits failure when the summary cannot be loaded',
    build: build,
    setUp: () {
      when(() => getSummary(any())).thenAnswer(
        (_) async => const Left(NetworkFailure('No internet connection')),
      );
    },
    act: (cubit) => cubit.load(),
    expect: () => const [
      PerformanceLoading(),
      PerformanceFailure(NetworkFailure('No internet connection')),
    ],
  );

  blocTest<PerformanceCubit, PerformanceState>(
    'emits failure for an unauthorized response',
    build: build,
    setUp: () {
      when(() => getSummary(any())).thenAnswer(
        (_) async => const Left(UnauthorizedFailure('Not authenticated')),
      );
    },
    act: (cubit) => cubit.load(),
    expect: () => const [
      PerformanceLoading(),
      PerformanceFailure(UnauthorizedFailure('Not authenticated')),
    ],
  );

  blocTest<PerformanceCubit, PerformanceState>(
    'refreshes a visible summary without emitting loading',
    build: build,
    seed: () => const PerformanceSuccess(summary),
    setUp: () {
      when(() => getSummary(any()))
          .thenAnswer((_) async => const Right(refreshed));
    },
    act: (cubit) => cubit.load(),
    expect: () => const [
      PerformanceSuccess(refreshed),
    ],
    verify: (_) => verify(() => getSummary(any())).called(1),
  );

  blocTest<PerformanceCubit, PerformanceState>(
    'does not send a second request while one is in flight',
    build: build,
    act: (cubit) async {
      final gate = Completer<Either<Failure, PerformanceSummary>>();
      when(() => getSummary(any())).thenAnswer((_) => gate.future);
      final first = cubit.load();
      final second = cubit.load();
      expect(identical(first, second), isTrue);
      gate.complete(const Right(summary));
      await Future.wait([first, second]);
    },
    expect: () => const [
      PerformanceLoading(),
      PerformanceSuccess(summary),
    ],
    verify: (_) => verify(() => getSummary(any())).called(1),
  );
}
