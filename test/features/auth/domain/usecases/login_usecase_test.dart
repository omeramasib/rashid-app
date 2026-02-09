import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rashed_app/core/error/failures.dart';
import 'package:rashed_app/features/auth/domain/entities/user.dart';
import 'package:rashed_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:rashed_app/features/auth/domain/usecases/login_usecase.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late LoginUseCase usecase;
  late MockAuthRepository mockAuthRepository;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    usecase = LoginUseCase(mockAuthRepository);
  });

  const tEmail = 'test@test.com';
  const tPassword = 'password';
  const tUser = User(token: 'test_token');

  test(
    'should get user from the repository when login is successful',
    () async {
      // arrange
      when(() => mockAuthRepository.login(any(), any()))
          .thenAnswer((_) async => const Right(tUser));
      // act
      final result =
          await usecase(const LoginParams(email: tEmail, password: tPassword));
      // assert
      expect(result, const Right(tUser));
      verify(() => mockAuthRepository.login(tEmail, tPassword));
      verifyNoMoreInteractions(mockAuthRepository);
    },
  );

  test(
    'should return a Failure from the repository when login fails',
    () async {
      // arrange
      const tFailure = ServerFailure('Server Failure');
      when(() => mockAuthRepository.login(any(), any()))
          .thenAnswer((_) async => const Left(tFailure));
      // act
      final result =
          await usecase(const LoginParams(email: tEmail, password: tPassword));
      // assert
      expect(result, const Left(tFailure));
      verify(() => mockAuthRepository.login(tEmail, tPassword));
      verifyNoMoreInteractions(mockAuthRepository);
    },
  );
}
