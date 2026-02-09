import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rashed_app/core/error/failures.dart';
import 'package:rashed_app/core/storage/secure_storage_service.dart';
import 'package:rashed_app/features/auth/domain/entities/user.dart';
import 'package:rashed_app/features/auth/domain/usecases/register_usecase.dart';
import 'package:rashed_app/features/auth/presentation/cubit/register/register_cubit.dart';

class MockRegisterUseCase extends Mock implements RegisterUseCase {}

class MockSecureStorageService extends Mock implements SecureStorageService {}

void main() {
  late RegisterCubit cubit;
  late MockRegisterUseCase mockRegisterUseCase;
  late MockSecureStorageService mockSecureStorageService;

  setUp(() {
    mockRegisterUseCase = MockRegisterUseCase();
    mockSecureStorageService = MockSecureStorageService();
    cubit = RegisterCubit(
      registerUseCase: mockRegisterUseCase,
      secureStorageService: mockSecureStorageService,
    );
  });

  setUpAll(() {
    registerFallbackValue(const RegisterParams(
      email: 'test',
      password: 'password',
      name: 'name',
      phone: 'phone',
    ));
  });

  const tUser = User(token: 'test_token');

  test('initial state should be RegisterInitial', () {
    expect(cubit.state, equals(RegisterInitial()));
  });

  blocTest<RegisterCubit, RegisterState>(
    'emits [RegisterLoading, RegisterSuccess] when registration is successful',
    build: () {
      when(() => mockRegisterUseCase(any()))
          .thenAnswer((_) async => const Right(tUser));
      when(() => mockSecureStorageService.write(
          key: any(named: 'key'),
          value: any(named: 'value'))).thenAnswer((_) async => {});
      return cubit;
    },
    act: (cubit) => cubit.register(
      email: 'test@test.com',
      password: 'password',
      name: 'test',
      phone: '123',
    ),
    expect: () => [
      RegisterLoading(),
      const RegisterSuccess(tUser),
    ],
    verify: (_) {
      verify(() =>
              mockSecureStorageService.write(key: 'token', value: tUser.token))
          .called(1);
    },
  );

  blocTest<RegisterCubit, RegisterState>(
    'emits [RegisterLoading, RegisterFailure] when registration fails',
    build: () {
      when(() => mockRegisterUseCase(any()))
          .thenAnswer((_) async => const Left(ServerFailure('Server Failure')));
      return cubit;
    },
    act: (cubit) => cubit.register(
      email: 'test@test.com',
      password: 'password',
      name: 'test',
      phone: '123',
    ),
    expect: () => [
      RegisterLoading(),
      const RegisterFailure('Server Failure'),
    ],
  );
}
