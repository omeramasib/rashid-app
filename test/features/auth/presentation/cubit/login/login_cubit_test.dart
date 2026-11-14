import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rashed_app/core/auth/clerk_auth_service.dart';
import 'package:rashed_app/core/auth/rashed_session.dart';
import 'package:rashed_app/core/error/failures.dart';
import 'package:rashed_app/core/storage/secure_storage_service.dart';
import 'package:rashed_app/features/auth/domain/entities/user.dart';
import 'package:rashed_app/features/auth/domain/linkedin_auth_conflicts.dart';
import 'package:rashed_app/features/auth/domain/usecases/login_usecase.dart';
import 'package:rashed_app/features/auth/domain/usecases/register_usecase.dart';
import 'package:rashed_app/features/auth/presentation/cubit/login/login_cubit.dart';

class MockLoginWithEmailUseCase extends Mock implements LoginWithEmailUseCase {}

class MockLoginWithLinkedInUseCase extends Mock
    implements LoginWithLinkedInUseCase {}

class MockRegisterWithLinkedInUseCase extends Mock
    implements RegisterWithLinkedInUseCase {}

class MockClerkAuthService extends Mock implements ClerkAuthService {}

class MockSecureStorageService extends Mock implements SecureStorageService {}

class MockBuildContext extends Mock implements BuildContext {}

void main() {
  late LoginCubit cubit;
  late MockLoginWithEmailUseCase mockLoginWithEmailUseCase;
  late MockLoginWithLinkedInUseCase mockLoginWithLinkedInUseCase;
  late MockRegisterWithLinkedInUseCase mockRegisterWithLinkedInUseCase;
  late MockClerkAuthService mockClerkAuthService;
  late MockSecureStorageService mockSecureStorageService;

  late MockBuildContext mockBuildContext;

  setUp(() {
    mockLoginWithEmailUseCase = MockLoginWithEmailUseCase();
    mockLoginWithLinkedInUseCase = MockLoginWithLinkedInUseCase();
    mockRegisterWithLinkedInUseCase = MockRegisterWithLinkedInUseCase();
    mockClerkAuthService = MockClerkAuthService();
    mockSecureStorageService = MockSecureStorageService();
    mockBuildContext = MockBuildContext();

    // Register fallback values
    registerFallbackValue(mockBuildContext);

    cubit = LoginCubit(
      loginWithEmailUseCase: mockLoginWithEmailUseCase,
      loginWithLinkedInUseCase: mockLoginWithLinkedInUseCase,
      registerWithLinkedInUseCase: mockRegisterWithLinkedInUseCase,
      clerkAuthService: mockClerkAuthService,
      session: RashedSession(mockSecureStorageService),
    );
  });

  setUpAll(() {
    registerFallbackValue(const LoginWithEmailParams(
      email: 'test',
      password: 'password',
    ));
    registerFallbackValue(
      const LoginWithLinkedInParams(clerkSessionJwt: 'token'),
    );
    registerFallbackValue(
      const RegisterWithLinkedInParams(clerkSessionJwt: 'token'),
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
      verify: (_) {
        verifyNever(() => mockSecureStorageService.write(
              key: any(named: 'key'),
              value: any(named: 'value'),
            ));
        expect(cubit.state, isNot(isA<LoginSuccess>()));
      },
    );

    blocTest<LoginCubit, LoginState>(
      'existing email conflict offers email sign-in and does not link',
      build: () {
        when(() => mockClerkAuthService.signInWithLinkedIn(any())).thenAnswer(
          (_) async => const SocialAuthResult(accessToken: 'clerk-session'),
        );
        when(() => mockLoginWithLinkedInUseCase(any())).thenAnswer(
          (_) async => const Left(
            NotFoundFailure('User not found. Please register first.'),
          ),
        );
        when(() => mockRegisterWithLinkedInUseCase(any())).thenAnswer(
          (_) async => const Left(
            ConflictFailure(LinkedInAuthConflicts.emailAccountExists),
          ),
        );
        return cubit;
      },
      act: (cubit) => cubit.loginWithLinkedIn(mockBuildContext),
      expect: () => [
        LoginLinkedInLoading(),
        const LoginFailure(
          LinkedInAuthConflicts.emailAccountExists,
          offerEmailSignIn: true,
        ),
      ],
      verify: (_) {
        verify(() => mockRegisterWithLinkedInUseCase(any())).called(1);
        verifyNever(() => mockSecureStorageService.write(
              key: any(named: 'key'),
              value: any(named: 'value'),
            ));
        expect(
          (cubit.state as LoginFailure).message,
          isNot(contains("Instance of 'ConflictException'")),
        );
      },
    );

    blocTest<LoginCubit, LoginState>(
      '404 registers once and persists the token before success',
      build: () {
        when(() => mockClerkAuthService.signInWithLinkedIn(any())).thenAnswer(
          (_) async => const SocialAuthResult(accessToken: 'clerk-session'),
        );
        when(() => mockLoginWithLinkedInUseCase(any())).thenAnswer(
          (_) async => const Left(
            NotFoundFailure('User not found. Please register first.'),
          ),
        );
        when(() => mockRegisterWithLinkedInUseCase(any()))
            .thenAnswer((_) async => const Right(tUser));
        when(() => mockSecureStorageService.write(
              key: any(named: 'key'),
              value: any(named: 'value'),
            )).thenAnswer((_) async {});
        return cubit;
      },
      act: (cubit) => cubit.loginWithLinkedIn(mockBuildContext),
      expect: () => [
        LoginLinkedInLoading(),
        const LoginSuccess(tUser),
      ],
      verify: (_) {
        verify(() => mockRegisterWithLinkedInUseCase(any())).called(1);
        verify(() => mockSecureStorageService.write(
              key: 'token',
              value: 'test_token',
            )).called(1);
      },
    );

    blocTest<LoginCubit, LoginState>(
      'canceled Clerk authentication does not stay loading or call Rashed',
      build: () {
        when(() => mockClerkAuthService.signInWithLinkedIn(any())).thenAnswer(
          (_) async => const SocialAuthResult(error: 'cancelled'),
        );
        return cubit;
      },
      act: (cubit) => cubit.loginWithLinkedIn(mockBuildContext),
      expect: () => [
        LoginLinkedInLoading(),
        const LoginFailure('cancelled'),
      ],
      verify: (_) {
        verifyNever(() => mockLoginWithLinkedInUseCase(any()));
        verifyNever(() => mockRegisterWithLinkedInUseCase(any()));
        expect(cubit.state, isNot(isA<LoginLinkedInLoading>()));
      },
    );

    test('a second tap does not register twice', () async {
      final gate = Completer<Either<Failure, User>>();
      when(() => mockClerkAuthService.signInWithLinkedIn(any())).thenAnswer(
        (_) async => const SocialAuthResult(accessToken: 'clerk-session'),
      );
      when(() => mockLoginWithLinkedInUseCase(any()))
          .thenAnswer((_) => gate.future);
      when(() => mockRegisterWithLinkedInUseCase(any()))
          .thenAnswer((_) async => const Right(tUser));
      when(() => mockSecureStorageService.write(
            key: any(named: 'key'),
            value: any(named: 'value'),
          )).thenAnswer((_) async {});

      final first = cubit.loginWithLinkedIn(mockBuildContext);
      final second = cubit.loginWithLinkedIn(mockBuildContext);
      await Future<void>.delayed(Duration.zero);
      verifyNever(() => mockRegisterWithLinkedInUseCase(any()));
      gate.complete(const Left(
        NotFoundFailure('User not found. Please register first.'),
      ));
      await Future.wait([first, second]);
      verify(() => mockRegisterWithLinkedInUseCase(any())).called(1);
      verify(() => mockClerkAuthService.signInWithLinkedIn(any())).called(1);
      expect(cubit.state, const LoginSuccess(tUser));
    });

    test('persists the Rashed token before LoginSuccess', () async {
      var stored = false;
      when(() => mockClerkAuthService.signInWithLinkedIn(any())).thenAnswer(
        (_) async => const SocialAuthResult(accessToken: 'clerk-session'),
      );
      when(() => mockLoginWithLinkedInUseCase(any()))
          .thenAnswer((_) async => const Right(tUser));
      when(() => mockSecureStorageService.write(
            key: any(named: 'key'),
            value: any(named: 'value'),
          )).thenAnswer((invocation) async {
        if (invocation.namedArguments[#key] == 'token') stored = true;
      });
      final states = <LoginState>[];
      final sub = cubit.stream.listen((state) {
        if (state is LoginSuccess) {
          expect(stored, isTrue);
          states.add(state);
        }
      });
      await cubit.loginWithLinkedIn(mockBuildContext);
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();
      expect(cubit.state, const LoginSuccess(tUser));
      expect(states, [const LoginSuccess(tUser)]);
    });
  });

  test('email login 404 does not register a LinkedIn account', () async {
    when(() => mockLoginWithEmailUseCase(any())).thenAnswer(
      (_) async => const Left(NotFoundFailure('missing')),
    );
    await cubit.loginWithEmail(email: 'test@test.com', password: 'password');
    verifyNever(() => mockRegisterWithLinkedInUseCase(any()));
    expect(cubit.state, const LoginFailure('missing'));
  });
}
