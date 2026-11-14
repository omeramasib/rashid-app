import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rashed_app/core/auth/clerk_auth_service.dart';
import 'package:rashed_app/core/error/failures.dart';
import 'package:rashed_app/core/usecases/usecase.dart';
import 'package:rashed_app/features/auth/domain/entities/user.dart';
import 'package:rashed_app/features/auth/domain/linkedin_auth_conflicts.dart';
import 'package:rashed_app/features/auth/domain/usecases/change_password_usecase.dart';
import 'package:rashed_app/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:rashed_app/features/auth/domain/usecases/link_linkedin_usecase.dart';
import 'package:rashed_app/features/auth/domain/usecases/logout_usecase.dart';
import 'package:rashed_app/features/auth/presentation/cubit/profile/auth_profile_cubit.dart';
import 'package:rashed_app/features/auth/presentation/cubit/profile/auth_profile_state.dart';

class MockGetCurrentUserUseCase extends Mock implements GetCurrentUserUseCase {}

class MockChangePasswordUseCase extends Mock implements ChangePasswordUseCase {}

class MockLogoutUseCase extends Mock implements LogoutUseCase {}

class MockLinkLinkedInUseCase extends Mock implements LinkLinkedInUseCase {}

class MockClerkAuthService extends Mock implements ClerkAuthService {}

class MockBuildContext extends Mock implements BuildContext {}

void main() {
  late AuthProfileCubit cubit;
  late MockLinkLinkedInUseCase mockLinkLinkedInUseCase;
  late MockGetCurrentUserUseCase mockGetCurrentUserUseCase;
  late MockClerkAuthService mockClerkAuthService;

  setUpAll(() {
    registerFallbackValue(
      const LinkLinkedInParams(
        clerkSessionJwt: 'clerk-session',
        currentPassword: 'current-password',
      ),
    );
    registerFallbackValue(NoParams());
    registerFallbackValue(MockBuildContext());
  });

  setUp(() {
    mockLinkLinkedInUseCase = MockLinkLinkedInUseCase();
    mockGetCurrentUserUseCase = MockGetCurrentUserUseCase();
    mockClerkAuthService = MockClerkAuthService();
    cubit = AuthProfileCubit(
      getCurrentUserUseCase: mockGetCurrentUserUseCase,
      changePasswordUseCase: MockChangePasswordUseCase(),
      logoutUseCase: MockLogoutUseCase(),
      linkLinkedInUseCase: mockLinkLinkedInUseCase,
      clerkAuthService: mockClerkAuthService,
    );
  });

  blocTest<AuthProfileCubit, AuthProfileState>(
    'blank password does not call the link use case',
    build: () => cubit,
    act: (cubit) => cubit.linkLinkedIn(
      clerkSessionJwt: 'clerk-session',
      currentPassword: '   ',
    ),
    expect: () => const [
      AuthProfileError('Current password is required'),
    ],
    verify: (_) {
      verifyNever(() => mockLinkLinkedInUseCase(any()));
    },
  );

  blocTest<AuthProfileCubit, AuthProfileState>(
    'a blank password does not start Clerk or the link request',
    build: () => cubit,
    act: (cubit) => cubit.connectLinkedIn(MockBuildContext(), '  '),
    expect: () => const [
      AuthProfileError('Current password is required'),
    ],
    verify: (_) {
      verifyNever(() => mockClerkAuthService.signInWithLinkedIn(any()));
      verifyNever(() => mockLinkLinkedInUseCase(any()));
    },
  );

  blocTest<AuthProfileCubit, AuthProfileState>(
    'link 409 keeps the identity conflict detail',
    build: () {
      when(() => mockLinkLinkedInUseCase(any())).thenAnswer(
        (_) async => const Left(
          ConflictFailure(LinkedInAuthConflicts.identityConflict),
        ),
      );
      return cubit;
    },
    act: (cubit) => cubit.linkLinkedIn(
      clerkSessionJwt: 'clerk-session',
      currentPassword: 'current-password',
    ),
    expect: () => [
      AuthProfileLoading(),
      const AuthProfileError(LinkedInAuthConflicts.identityConflict),
    ],
    verify: (_) {
      final params = verify(() => mockLinkLinkedInUseCase(captureAny()))
          .captured
          .single as LinkLinkedInParams;
      expect(params.clerkSessionJwt, 'clerk-session');
      expect(params.currentPassword, 'current-password');
      expect(
        (cubit.state as AuthProfileError).message,
        isNot(contains("Instance of 'ConflictException'")),
      );
    },
  );

  blocTest<AuthProfileCubit, AuthProfileState>(
    'canceled Clerk authentication leaves an error and does not link',
    build: () {
      when(() => mockClerkAuthService.signInWithLinkedIn(any())).thenAnswer(
        (_) async => const SocialAuthResult(error: 'cancelled'),
      );
      return cubit;
    },
    act: (cubit) => cubit.connectLinkedIn(MockBuildContext(), 'current-password'),
    expect: () => [
      AuthProfileLoading(),
      const AuthProfileError('cancelled'),
    ],
    verify: (_) {
      verifyNever(() => mockLinkLinkedInUseCase(any()));
      expect(cubit.state, isNot(isA<AuthProfileLoading>()));
    },
  );

  blocTest<AuthProfileCubit, AuthProfileState>(
    'successful linking reloads linkedin_linked from the current user',
    build: () {
      when(() => mockClerkAuthService.signInWithLinkedIn(any())).thenAnswer(
        (_) async => const SocialAuthResult(accessToken: 'clerk-session'),
      );
      when(() => mockLinkLinkedInUseCase(any()))
          .thenAnswer((_) async => const Right(null));
      when(() => mockGetCurrentUserUseCase(any())).thenAnswer(
        (_) async => const Right(User(
          id: 'user-1',
          email: 'ada@example.com',
          linkedinLinked: true,
        )),
      );
      return cubit;
    },
    act: (cubit) => cubit.connectLinkedIn(MockBuildContext(), 'current-password'),
    expect: () => [
      AuthProfileLoading(),
      const AuthProfileLoaded(User(
        id: 'user-1',
        email: 'ada@example.com',
        linkedinLinked: true,
      )),
    ],
  );
}
