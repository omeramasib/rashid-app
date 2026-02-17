import 'package:flutter/widgets.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rashed_app/core/auth/clerk_auth_service.dart';
import 'package:rashed_app/core/error/failures.dart';
import 'package:rashed_app/core/storage/secure_storage_service.dart';
import 'package:rashed_app/features/auth/domain/entities/user.dart';
import 'package:rashed_app/features/auth/domain/usecases/register_usecase.dart';
import 'package:rashed_app/features/auth/presentation/cubit/register/register_cubit.dart';

class MockRegisterWithEmailUseCase extends Mock
    implements RegisterWithEmailUseCase {}

class MockRegisterWithLinkedInUseCase extends Mock
    implements RegisterWithLinkedInUseCase {}

class MockClerkAuthService extends Mock implements ClerkAuthService {}

class MockSecureStorageService extends Mock implements SecureStorageService {}

class MockBuildContext extends Mock implements BuildContext {}

void main() {
  late RegisterCubit cubit;
  late MockRegisterWithEmailUseCase mockRegisterWithEmailUseCase;
  late MockRegisterWithLinkedInUseCase mockRegisterWithLinkedInUseCase;
  late MockClerkAuthService mockClerkAuthService;
  late MockSecureStorageService mockSecureStorageService;

  late MockBuildContext mockBuildContext;

  setUp(() {
    mockRegisterWithEmailUseCase = MockRegisterWithEmailUseCase();
    mockRegisterWithLinkedInUseCase = MockRegisterWithLinkedInUseCase();
    mockClerkAuthService = MockClerkAuthService();
    mockSecureStorageService = MockSecureStorageService();
    mockBuildContext = MockBuildContext();

    // Register fallback values
    registerFallbackValue(mockBuildContext);

    cubit = RegisterCubit(
      registerWithEmailUseCase: mockRegisterWithEmailUseCase,
      registerWithLinkedInUseCase: mockRegisterWithLinkedInUseCase,
      clerkAuthService: mockClerkAuthService,
      secureStorageService: mockSecureStorageService,
    );
  });

  setUpAll(() {
    registerFallbackValue(const RegisterWithEmailParams(
      name: 'name',
      email: 'test',
      password: 'password',
    ));
    registerFallbackValue(
      const RegisterWithLinkedInParams(linkedinToken: 'token'),
    );
  });

  const tUser = User(
    id: 'test_id',
    name: 'Test User',
    email: 'test@test.com',
    token: 'test_token',
  );

  group('registerWithLinkedIn', () {
    blocTest<RegisterCubit, RegisterState>(
        'emits [RegisterLinkedInLoading, RegisterSuccess] when LinkedIn registration is successful',
        build: () {
          when(() => mockClerkAuthService.signInWithLinkedIn(any())).thenAnswer(
            (_) async => const SocialAuthResult(accessToken: 'linkedin_token'),
          );
          when(() => mockRegisterWithLinkedInUseCase(any()))
              .thenAnswer((_) async => const Right(tUser));
          when(() => mockSecureStorageService.write(
              key: any(named: 'key'),
              value: any(named: 'value'))).thenAnswer((_) async => {});
          return cubit;
        },
        act: (cubit) => cubit.registerWithLinkedIn(mockBuildContext),
        expect: () => [
              RegisterLinkedInLoading(),
              const RegisterSuccess(tUser),
            ],
        verify: (_) {
          verify(() => mockClerkAuthService.signInWithLinkedIn(any()))
              .called(1);
        });

    blocTest<RegisterCubit, RegisterState>(
      'emits [RegisterLinkedInLoading, RegisterFailure] when Clerk OAuth fails',
      build: () {
        when(() => mockClerkAuthService.signInWithLinkedIn(any())).thenAnswer(
          (_) async => const SocialAuthResult(error: 'OAuth failed'),
        );
        return cubit;
      },
      act: (cubit) => cubit.registerWithLinkedIn(mockBuildContext),
      expect: () => [
        RegisterLinkedInLoading(),
        isA<RegisterFailure>(),
      ],
    );

    blocTest<RegisterCubit, RegisterState>(
      'emits [RegisterLinkedInLoading, RegisterFailure] when backend LinkedIn registration fails',
      build: () {
        when(() => mockClerkAuthService.signInWithLinkedIn(any())).thenAnswer(
          (_) async => const SocialAuthResult(accessToken: 'linkedin_token'),
        );
        when(() => mockRegisterWithLinkedInUseCase(any())).thenAnswer(
            (_) async =>
                const Left(ServerFailure('LinkedIn registration failed')));
        return cubit;
      },
      act: (cubit) => cubit.registerWithLinkedIn(mockBuildContext),
      expect: () => [
        RegisterLinkedInLoading(),
        isA<RegisterFailure>(),
      ],
    );
  });
}
