import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rashed_app/core/error/exceptions.dart';
import 'package:rashed_app/core/error/failures.dart';
import 'package:rashed_app/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:rashed_app/features/auth/data/models/user_model.dart';
import 'package:rashed_app/features/auth/data/repositories/auth_repository_impl.dart';

class MockAuthRemoteDataSource extends Mock implements AuthRemoteDataSource {}

void main() {
  late AuthRepositoryImpl repository;
  late MockAuthRemoteDataSource mockRemoteDataSource;

  setUp(() {
    mockRemoteDataSource = MockAuthRemoteDataSource();
    repository = AuthRepositoryImpl(remoteDataSource: mockRemoteDataSource);
  });

  const tUserModel = UserModel(
    id: 'test_id',
    name: 'Test User',
    email: 'test@test.com',
    token: 'test_token',
  );
  const tEmail = 'test@test.com';
  const tPassword = 'password';
  const tName = 'Test User';
  const tLinkedInToken = 'linkedin_access_token';

  group('loginWithEmail', () {
    test(
      'should return user when the call to remote data source is successful',
      () async {
        // arrange
        when(() => mockRemoteDataSource.loginWithEmail(any(), any()))
            .thenAnswer((_) async => tUserModel);
        // act
        final result = await repository.loginWithEmail(tEmail, tPassword);
        // assert
        verify(() => mockRemoteDataSource.loginWithEmail(tEmail, tPassword));
        expect(result, equals(const Right(tUserModel)));
      },
    );

    test(
      'should return server failure when the call to remote data source fails',
      () async {
        // arrange
        when(() => mockRemoteDataSource.loginWithEmail(any(), any()))
            .thenThrow(ServerException('Server Error'));
        // act
        final result = await repository.loginWithEmail(tEmail, tPassword);
        // assert
        verify(() => mockRemoteDataSource.loginWithEmail(tEmail, tPassword));
        expect(result, equals(const Left(ServerFailure('Server Error'))));
      },
    );
  });

  group('registerWithEmail', () {
    test(
      'should return user when registration is successful',
      () async {
        // arrange
        when(() => mockRemoteDataSource.registerWithEmail(
              name: any(named: 'name'),
              email: any(named: 'email'),
              password: any(named: 'password'),
            )).thenAnswer((_) async => tUserModel);
        // act
        final result = await repository.registerWithEmail(
          name: tName,
          email: tEmail,
          password: tPassword,
        );
        // assert
        verify(() => mockRemoteDataSource.registerWithEmail(
              name: tName,
              email: tEmail,
              password: tPassword,
            ));
        expect(result, equals(const Right(tUserModel)));
      },
    );

    test(
      'should return server failure when registration fails',
      () async {
        // arrange
        when(() => mockRemoteDataSource.registerWithEmail(
              name: any(named: 'name'),
              email: any(named: 'email'),
              password: any(named: 'password'),
            )).thenThrow(ServerException('Registration failed'));
        // act
        final result = await repository.registerWithEmail(
          name: tName,
          email: tEmail,
          password: tPassword,
        );
        // assert
        expect(result, equals(const Left(ServerFailure('Registration failed'))));
      },
    );
  });

  group('loginWithLinkedIn', () {
    test(
      'should return user when LinkedIn login is successful',
      () async {
        // arrange
        when(() => mockRemoteDataSource.loginWithLinkedIn(any()))
            .thenAnswer((_) async => tUserModel);
        // act
        final result = await repository.loginWithLinkedIn(tLinkedInToken);
        // assert
        verify(() => mockRemoteDataSource.loginWithLinkedIn(tLinkedInToken));
        expect(result, equals(const Right(tUserModel)));
      },
    );

    test(
      'should return server failure when LinkedIn login fails',
      () async {
        // arrange
        when(() => mockRemoteDataSource.loginWithLinkedIn(any()))
            .thenThrow(ServerException('LinkedIn login failed'));
        // act
        final result = await repository.loginWithLinkedIn(tLinkedInToken);
        // assert
        expect(result, equals(const Left(ServerFailure('LinkedIn login failed'))));
      },
    );
  });

  group('registerWithLinkedIn', () {
    test(
      'should return user when LinkedIn registration is successful',
      () async {
        // arrange
        when(() => mockRemoteDataSource.registerWithLinkedIn(any()))
            .thenAnswer((_) async => tUserModel);
        // act
        final result = await repository.registerWithLinkedIn(tLinkedInToken);
        // assert
        verify(() => mockRemoteDataSource.registerWithLinkedIn(tLinkedInToken));
        expect(result, equals(const Right(tUserModel)));
      },
    );

    test(
      'should return server failure when LinkedIn registration fails',
      () async {
        // arrange
        when(() => mockRemoteDataSource.registerWithLinkedIn(any()))
            .thenThrow(ServerException('LinkedIn registration failed'));
        // act
        final result = await repository.registerWithLinkedIn(tLinkedInToken);
        // assert
        expect(result, equals(const Left(ServerFailure('LinkedIn registration failed'))));
      },
    );
  });
}
