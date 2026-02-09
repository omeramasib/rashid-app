import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rashed_app/core/error/failures.dart';
import 'package:rashed_app/features/auth/domain/entities/user.dart';
import 'package:rashed_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:rashed_app/features/auth/domain/usecases/register_usecase.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late RegisterUseCase usecase;
  late MockAuthRepository mockAuthRepository;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    usecase = RegisterUseCase(mockAuthRepository);
  });

  const tEmail = 'test@test.com';
  const tPassword = 'password';
  const tName = 'Teest User';
  const tPhone = '1234567890';
  const tUser = User(token: 'test_token');

  test(
    'should get user from the repository when registration is successful',
    () async {
      // arrange
      when(() => mockAuthRepository.register(
            email: any(named: 'email'),
            password: any(named: 'password'),
            name: any(named: 'name'),
            phone: any(named: 'phone'),
          )).thenAnswer((_) async => const Right(tUser));

      // act
      final result = await usecase(const RegisterParams(
        email: tEmail,
        password: tPassword,
        name: tName,
        phone: tPhone,
      ));

      // assert
      expect(result, const Right(tUser));
      verify(() => mockAuthRepository.register(
            email: tEmail,
            password: tPassword,
            name: tName,
            phone: tPhone,
          ));
      verifyNoMoreInteractions(mockAuthRepository);
    },
  );

  test(
    'should return a Failure from the repository when registration fails',
    () async {
      // arrange
      const tFailure = ServerFailure('Server Failure');
      when(() => mockAuthRepository.register(
            email: any(named: 'email'),
            password: any(named: 'password'),
            name: any(named: 'name'),
            phone: any(named: 'phone'),
          )).thenAnswer((_) async => const Left(tFailure));

      // act
      final result = await usecase(const RegisterParams(
        email: tEmail,
        password: tPassword,
        name: tName,
        phone: tPhone,
      ));

      // assert
      expect(result, const Left(tFailure));
      verify(() => mockAuthRepository.register(
            email: tEmail,
            password: tPassword,
            name: tName,
            phone: tPhone,
          ));
      verifyNoMoreInteractions(mockAuthRepository);
    },
  );
}
