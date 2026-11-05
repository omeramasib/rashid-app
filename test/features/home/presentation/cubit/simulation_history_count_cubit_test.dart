import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rashed_app/core/error/failures.dart';
import 'package:rashed_app/core/storage/secure_storage_service.dart';
import 'package:rashed_app/core/usecases/usecase.dart';
import 'package:rashed_app/features/home/presentation/cubit/simulation_history_count_cubit.dart';
import 'package:rashed_app/features/simulation/domain/entities/simulation_history_count.dart';
import 'package:rashed_app/features/simulation/domain/usecases/get_simulation_history_count_usecase.dart';

class MockGetCount extends Mock implements GetSimulationHistoryCountUseCase {}

class MemoryStorage extends Fake implements SecureStorageService {
  final values = <String, String>{};

  @override
  Future<String?> read({required String key}) async => values[key];

  @override
  Future<void> delete({required String key}) async => values.remove(key);
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

  tearDown(() => cubit.close());

  test('stores a successful count and ignores a repeated load', () async {
    when(() => getCount(any())).thenAnswer(
      (_) async => const Right(SimulationHistoryCount(totalSimulations: 12)),
    );
    await cubit.load();
    await cubit.load();
    expect(cubit.state, const SimulationHistoryCountSuccess(12));
    verify(() => getCount(any())).called(1);
  });

  test('keeps zero as a successful count', () async {
    when(() => getCount(any())).thenAnswer(
      (_) async => const Right(SimulationHistoryCount(totalSimulations: 0)),
    );
    await cubit.load();
    expect(cubit.state, const SimulationHistoryCountSuccess(0));
  });

  test('an API failure is not a zero count', () async {
    when(() => getCount(any())).thenAnswer(
      (_) async => const Left(ServerFailure('unavailable')),
    );
    await cubit.load();
    expect(cubit.state, isA<SimulationHistoryCountFailure>());
    expect(cubit.state, isNot(isA<SimulationHistoryCountSuccess>()));
  });

  test('a late response from the previous session is ignored', () async {
    final first = Completer<Either<Failure, SimulationHistoryCount>>();
    when(() => getCount(any())).thenAnswer((_) => first.future);
    final pending = cubit.load();
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state, isA<SimulationHistoryCountLoading>());

    cubit.clearSession();
    storage.values['user_id'] = 'user-b';
    when(() => getCount(any())).thenAnswer(
      (_) async => const Right(SimulationHistoryCount(totalSimulations: 0)),
    );
    final next = cubit.load();
    first.complete(const Right(SimulationHistoryCount(totalSimulations: 12)));
    await pending;
    await next;
    expect(cubit.state, const SimulationHistoryCountSuccess(0));
    expect(cubit.state, isNot(const SimulationHistoryCountSuccess(12)));
  });

  test('switching accounts replaces the previous count', () async {
    when(() => getCount(any())).thenAnswer(
      (_) async => const Right(SimulationHistoryCount(totalSimulations: 12)),
    );
    await cubit.load();
    storage.values['user_id'] = 'user-b';
    when(() => getCount(any())).thenAnswer(
      (_) async => const Right(SimulationHistoryCount(totalSimulations: 3)),
    );
    await cubit.load();
    expect(cubit.state, const SimulationHistoryCountSuccess(3));
  });
}
