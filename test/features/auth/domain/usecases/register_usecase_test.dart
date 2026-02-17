import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rashed_app/core/error/failures.dart';
import 'package:rashed_app/features/auth/domain/entities/user.dart';
import 'package:rashed_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:rashed_app/features/auth/domain/usecases/register_usecase.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late RegisterWithEmailUseCase registerWithEmailUseCase;
  late RegisterWithLinkedInUseCase registerWithLinkedInUseCase;
  late MockAuthRepository mockAuthRepository;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    registerWithEmailUseCase = RegisterWithEmailUseCase(mockAuthRepository);
    registerWithLinkedInUseCase = RegisterWithLinkedInUseCase(mockAuthRepository);
  });

  const tEmail = 'test@test.com';
  const tPassword = 'password';
  const tName = 'Test User';
  const tLinkedInToken = 'linkedin_access_token';
  const tUser = User(
    id: 'test_id',
    name: 'Test User',
    email: 'test@test.com',
    token: 'test_token',
  );

  group('RegisterWithEmailUseCase', () {
    test(
      'should get user from the repository when email registration is successful',
      () async {
        // arrange
        when(() => mockAuthRepository.registerWithEmail(
              name: any(named: 'name'),
              email: any(named: 'email'),
              password: any(named: 'password'),
            )).thenAnswer((_) async => const Right(tUser));

        // act
        final result = await registerWithEmailUseCase(
          const RegisterWithEmailParams(
            name: tName,
            email: tEmail,
            password: tPassword,
          ),
        );

        // assert
        expect(result, const Right(tUser));
        verify(() => mockAuthRepository.registerWithEmail(
              name: tName,
              email: tEmail,
              password: tPassword,
            ));
        verifyNoMoreInteractions(mockAuthRepository);
      },
    );

    test(
      'should return a Failure when email registration fails',
      () async {
        // arrange
        const tFailure = ServerFailure('Registration failed');
        when(() => mockAuthRepository.registerWithEmail(
              name: any(named: 'name'),
              email: any(named: 'email'),
              password: any(named: 'password'),
            )).thenAnswer((_) async => const Left(tFailure));

        // act
        final result = await registerWithEmailUseCase(
          const RegisterWithEmailParams(
            name: tName,
            email: tEmail,
            password: tPassword,
          ),
        );

        // assert
        expect(result, const Left(tFailure));
        verify(() => mockAuthRepository.registerWithEmail(
              name: tName,
              email: tEmail,
              password: tPassword,
            ));
        verifyNoMoreInteractions(mockAuthRepository);
      },
    );
  });

  group('RegisterWithLinkedInUseCase', () {
    test(
      'should get user from the repository when LinkedIn registration is successful',
      () async {
        // arrange
        when(() => mockAuthRepository.registerWithLinkedIn(any()))
            .thenAnswer((_) async => const Right(tUser));

        // act
        final result = await registerWithLinkedInUseCase(
          const RegisterWithLinkedInParams(linkedinToken: tLinkedInToken),
        );

        // assert
        expect(result, const Right(tUser));
        verify(() => mockAuthRepository.registerWithLinkedIn(tLinkedInToken));
        verifyNoMoreInteractions(mockAuthRepository);
      },
    );

    test(
      'should return a Failure when LinkedIn registration fails',
      () async {
        // arrange
        const tFailure = ServerFailure('LinkedIn registration failed');
        when(() => mockAuthRepository.registerWithLinkedIn(any()))
            .thenAnswer((_) async => const Left(tFailure));

        // act
        final result = await registerWithLinkedInUseCase(
          const RegisterWithLinkedInParams(linkedinToken: tLinkedInToken),
        );

        // assert
        expect(result, const Left(tFailure));
        verify(() => mockAuthRepository.registerWithLinkedIn(tLinkedInToken));
        verifyNoMoreInteractions(mockAuthRepository);
      },
    );
  });
}
