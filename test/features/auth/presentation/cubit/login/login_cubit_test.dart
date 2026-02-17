import 'package:flutter/widgets.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rashed_app/core/auth/clerk_auth_service.dart';
import 'package:rashed_app/core/error/failures.dart';
import 'package:rashed_app/core/storage/secure_storage_service.dart';
import 'package:rashed_app/features/auth/domain/entities/user.dart';
import 'package:rashed_app/features/auth/domain/usecases/login_usecase.dart';
import 'package:rashed_app/features/auth/presentation/cubit/login/login_cubit.dart';

class MockLoginWithEmailUseCase extends Mock implements LoginWithEmailUseCase {}

class MockLoginWithLinkedInUseCase extends Mock
    implements LoginWithLinkedInUseCase {}

class MockClerkAuthService extends Mock implements ClerkAuthService {}

class MockSecureStorageService extends Mock implements SecureStorageService {}

class MockBuildContext extends Mock implements BuildContext {}

void main() {
  late LoginCubit cubit;
  late MockLoginWithEmailUseCase mockLoginWithEmailUseCase;
  late MockLoginWithLinkedInUseCase mockLoginWithLinkedInUseCase;
  late MockClerkAuthService mockClerkAuthService;
  late MockSecureStorageService mockSecureStorageService;

  late MockBuildContext mockBuildContext;

  setUp(() {
    mockLoginWithEmailUseCase = MockLoginWithEmailUseCase();
    mockLoginWithLinkedInUseCase = MockLoginWithLinkedInUseCase();
    mockClerkAuthService = MockClerkAuthService();
    mockSecureStorageService = MockSecureStorageService();
    mockBuildContext = MockBuildContext();

    // Register fallback values
    registerFallbackValue(mockBuildContext);

    cubit = LoginCubit(
      loginWithEmailUseCase: mockLoginWithEmailUseCase,
      loginWithLinkedInUseCase: mockLoginWithLinkedInUseCase,
      clerkAuthService: mockClerkAuthService,
      secureStorageService: mockSecureStorageService,
    );
  });

  setUpAll(() {
    registerFallbackValue(const LoginWithEmailParams(
      email: 'test',
      password: 'password',
    ));
    registerFallbackValue(
      const LoginWithLinkedInParams(linkedinToken: 'token'),
    );
  });

  const tUser = User(
    id: 'test_id',
    name: 'Test User',
    email: 'test@test.com',
    token: 'test_token',
  );

  group('loginWithLinkedIn', () {
    blocTest<LoginCubit, LoginState>(
      'emits [LoginLinkedInLoading, LoginSuccess] when LinkedIn login is successful',
      build: () {
        when(() => mockClerkAuthService.signInWithLinkedIn(any())).thenAnswer(
          (_) async => const SocialAuthResult(accessToken: 'linkedin_token'),
        );
        when(() => mockLoginWithLinkedInUseCase(any()))
            .thenAnswer((_) async => const Right(tUser));
        when(() => mockSecureStorageService.write(
            key: any(named: 'key'),
            value: any(named: 'value'))).thenAnswer((_) async => {});
        return cubit;
      },
      act: (cubit) => cubit.loginWithLinkedIn(mockBuildContext),
      expect: () => [
        LoginLinkedInLoading(),
        const LoginSuccess(tUser),
      ],
      verify: (_) {
        verify(() => mockClerkAuthService.signInWithLinkedIn(any())).called(1);
      },
    );

    blocTest<LoginCubit, LoginState>(
      'emits [LoginLinkedInLoading, LoginFailure] when Clerk OAuth fails',
      build: () {
        when(() => mockClerkAuthService.signInWithLinkedIn(any())).thenAnswer(
          (_) async => const SocialAuthResult(error: 'OAuth failed'),
        );
        return cubit;
      },
      act: (cubit) => cubit.loginWithLinkedIn(mockBuildContext),
      expect: () => [
        LoginLinkedInLoading(),
        isA<LoginFailure>(),
      ],
    );

    blocTest<LoginCubit, LoginState>(
      'emits [LoginLinkedInLoading, LoginFailure] when backend LinkedIn login fails',
      build: () {
        when(() => mockClerkAuthService.signInWithLinkedIn(any())).thenAnswer(
          (_) async => const SocialAuthResult(accessToken: 'linkedin_token'),
        );
        when(() => mockLoginWithLinkedInUseCase(any())).thenAnswer(
            (_) async => const Left(ServerFailure('LinkedIn login failed')));
        return cubit;
      },
      act: (cubit) => cubit.loginWithLinkedIn(mockBuildContext),
      expect: () => [
        LoginLinkedInLoading(),
        isA<LoginFailure>(),
      ],
    );
  });
}
