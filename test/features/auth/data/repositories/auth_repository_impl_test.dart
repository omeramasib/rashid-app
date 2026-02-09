import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rashed_app/core/error/exceptions.dart';
import 'package:rashed_app/core/error/failures.dart';
import 'package:rashed_app/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:rashed_app/features/auth/data/models/user_model.dart';
import 'package:rashed_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:rashed_app/features/auth/domain/entities/user.dart';

class MockAuthRemoteDataSource extends Mock implements AuthRemoteDataSource {}

void main() {
  late AuthRepositoryImpl repository;
  late MockAuthRemoteDataSource mockRemoteDataSource;

  setUp(() {
    mockRemoteDataSource = MockAuthRemoteDataSource();
    repository = AuthRepositoryImpl(remoteDataSource: mockRemoteDataSource);
  });

  const tUserModel = UserModel(token: 'test_token');
  const tUser = tUserModel;
  const tEmail = 'test@test.com';
  const tPassword = 'password';

  group('login', () {
    test(
      'should return remote data when the call to remote data source is successful',
      () async {
        // arrange
        when(() => mockRemoteDataSource.login(any(), any()))
            .thenAnswer((_) async => tUserModel);
        // act
        final result = await repository.login(tEmail, tPassword);
        // assert
        verify(() => mockRemoteDataSource.login(tEmail, tPassword));
        expect(result, equals(const Right(tUser)));
      },
    );

    test(
      'should return server failure when the call to remote data source is unsuccessful',
      () async {
        // arrange
        when(() => mockRemoteDataSource.login(any(), any()))
            .thenThrow(ServerException('Server Error'));
        // act
        final result = await repository.login(tEmail, tPassword);
        // assert
        verify(() => mockRemoteDataSource.login(tEmail, tPassword));
        expect(result, equals(const Left(ServerFailure('Server Error'))));
      },
    );
  });
}
