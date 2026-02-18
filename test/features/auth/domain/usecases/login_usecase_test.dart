import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rashed_app/core/error/failures.dart';
import 'package:rashed_app/features/auth/domain/entities/user.dart';
import 'package:rashed_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:rashed_app/features/auth/domain/usecases/login_usecase.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late LoginWithEmailUseCase loginWithEmailUseCase;
  late LoginWithLinkedInUseCase loginWithLinkedInUseCase;
  late MockAuthRepository mockAuthRepository;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    loginWithEmailUseCase = LoginWithEmailUseCase(mockAuthRepository);
    loginWithLinkedInUseCase = LoginWithLinkedInUseCase(mockAuthRepository);
  });

  const tEmail = 'test@test.com';
  const tPassword = 'password';
  const tLinkedInToken = 'linkedin_access_token';
  const tUser = User(
    id: 'test_id',
    name: 'Test User',
    email: 'test@test.com',
    token: 'test_token',
  );

  group('LoginWithEmailUseCase', () {
    test(
      'should get user from the repository when email login is successful',
      () async {
        // arrange
        when(() => mockAuthRepository.loginWithEmail(any(), any()))
            .thenAnswer((_) async => const Right(tUser));
        // act
        final result = await loginWithEmailUseCase(
          const LoginWithEmailParams(email: tEmail, password: tPassword),
        );
        // assert
        expect(result, const Right(tUser));
        verify(() => mockAuthRepository.loginWithEmail(tEmail, tPassword));
        verifyNoMoreInteractions(mockAuthRepository);
      },
    );

    test(
      'should return a Failure when email login fails',
      () async {
        // arrange
        const tFailure = ServerFailure('Server Failure');
        when(() => mockAuthRepository.loginWithEmail(any(), any()))
            .thenAnswer((_) async => const Left(tFailure));
        // act
        final result = await loginWithEmailUseCase(
          const LoginWithEmailParams(email: tEmail, password: tPassword),
        );
        // assert
        expect(result, const Left(tFailure));
        verify(() => mockAuthRepository.loginWithEmail(tEmail, tPassword));
        verifyNoMoreInteractions(mockAuthRepository);
      },
    );
  });

  group('LoginWithLinkedInUseCase', () {
    test(
      'should get user from the repository when LinkedIn login is successful',
      () async {
        // arrange
        when(() => mockAuthRepository.loginWithLinkedIn(any()))
            .thenAnswer((_) async => const Right(tUser));
        // act
        final result = await loginWithLinkedInUseCase(
          const LoginWithLinkedInParams(clerkSessionJwt: tLinkedInToken),
        );
        // assert
        expect(result, const Right(tUser));
        verify(() => mockAuthRepository.loginWithLinkedIn(tLinkedInToken));
        verifyNoMoreInteractions(mockAuthRepository);
      },
    );

    test(
      'should return a Failure when LinkedIn login fails',
      () async {
        // arrange
        const tFailure = ServerFailure('LinkedIn login failed');
        when(() => mockAuthRepository.loginWithLinkedIn(any()))
            .thenAnswer((_) async => const Left(tFailure));
        // act
        final result = await loginWithLinkedInUseCase(
          const LoginWithLinkedInParams(clerkSessionJwt: tLinkedInToken),
        );
        // assert
        expect(result, const Left(tFailure));
        verify(() => mockAuthRepository.loginWithLinkedIn(tLinkedInToken));
        verifyNoMoreInteractions(mockAuthRepository);
      },
    );
  });
}
