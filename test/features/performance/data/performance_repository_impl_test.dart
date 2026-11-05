import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rashed_app/core/error/exceptions.dart';
import 'package:rashed_app/core/error/failures.dart';
import 'package:rashed_app/features/performance/data/datasources/performance_remote_datasource.dart';
import 'package:rashed_app/features/performance/data/repositories/performance_repository_impl.dart';

class MockPerformanceSource extends Mock
    implements PerformanceRemoteDataSource {}

void main() {
  late MockPerformanceSource source;
  late PerformanceRepositoryImpl repository;

  setUp(() {
    source = MockPerformanceSource();
    repository = PerformanceRepositoryImpl(remoteDataSource: source);
  });

  test('maps a network exception to a network failure', () async {
    when(() => source.getSummary())
        .thenThrow(NetworkException('No internet connection'));

    final result = await repository.getSummary();

    expect(
      result.fold((failure) => failure, (_) => null),
      isA<NetworkFailure>().having(
        (failure) => failure.message,
        'message',
        'No internet connection',
      ),
    );
  });

  test('maps an unauthorized exception to an unauthorized failure', () async {
    when(() => source.getSummary())
        .thenThrow(UnauthorizedException('Not authenticated'));

    final result = await repository.getSummary();

    expect(
      result.fold((failure) => failure, (_) => null),
      isA<UnauthorizedFailure>().having(
        (failure) => failure.message,
        'message',
        'Not authenticated',
      ),
    );
  });
}
