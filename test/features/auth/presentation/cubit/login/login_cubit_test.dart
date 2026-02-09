import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rashed_app/core/error/failures.dart';
import 'package:rashed_app/core/storage/secure_storage_service.dart';
import 'package:rashed_app/features/auth/domain/entities/user.dart';
import 'package:rashed_app/features/auth/domain/usecases/login_usecase.dart';
import 'package:rashed_app/features/auth/presentation/cubit/login/login_cubit.dart';

class MockLoginUseCase extends Mock implements LoginUseCase {}

class MockSecureStorageService extends Mock implements SecureStorageService {}

void main() {
  late LoginCubit cubit;
  late MockLoginUseCase mockLoginUseCase;
  late MockSecureStorageService mockSecureStorageService;

  setUp(() {
    mockLoginUseCase = MockLoginUseCase();
    mockSecureStorageService = MockSecureStorageService();
    cubit = LoginCubit(
      loginUseCase: mockLoginUseCase,
      secureStorageService: mockSecureStorageService,
    );
  });

  setUpAll(() {
    registerFallbackValue(
        const LoginParams(email: 'test', password: 'password'));
  });

  const tUser = User(token: 'test_token');

  test('initial state should be LoginInitial', () {
    expect(cubit.state, equals(LoginInitial()));
  });

  blocTest<LoginCubit, LoginState>(
    'emits [LoginLoading, LoginSuccess] when login is successful',
    build: () {
      when(() => mockLoginUseCase(any()))
          .thenAnswer((_) async => const Right(tUser));
      when(() => mockSecureStorageService.write(
          key: any(named: 'key'),
          value: any(named: 'value'))).thenAnswer((_) async => {});
      return cubit;
    },
    act: (cubit) => cubit.login(email: 'test@test.com', password: 'password'),
    expect: () => [
      LoginLoading(),
      const LoginSuccess(tUser),
    ],
    verify: (_) {
      verify(() =>
              mockSecureStorageService.write(key: 'token', value: tUser.token))
          .called(1);
    },
  );

  blocTest<LoginCubit, LoginState>(
    'emits [LoginLoading, LoginFailure] when login fails',
    build: () {
      when(() => mockLoginUseCase(any()))
          .thenAnswer((_) async => const Left(ServerFailure('Server Failure')));
      return cubit;
    },
    act: (cubit) => cubit.login(email: 'test@test.com', password: 'password'),
    expect: () => [
      LoginLoading(),
      const LoginFailure('Server Failure'),
    ],
  );
}
