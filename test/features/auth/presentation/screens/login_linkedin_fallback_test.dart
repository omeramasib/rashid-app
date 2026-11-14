import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rashed_app/app/routes_name.dart';
import 'package:rashed_app/app_localizations.dart';
import 'package:rashed_app/core/auth/clerk_auth_service.dart';
import 'package:rashed_app/core/auth/rashed_session.dart';
import 'package:rashed_app/core/error/failures.dart';
import 'package:rashed_app/core/storage/secure_storage_service.dart';
import 'package:rashed_app/features/auth/domain/entities/user.dart';
import 'package:rashed_app/features/auth/domain/linkedin_auth_conflicts.dart';
import 'package:rashed_app/features/auth/domain/usecases/login_usecase.dart';
import 'package:rashed_app/features/auth/domain/usecases/register_usecase.dart';
import 'package:rashed_app/features/auth/presentation/cubit/login/login_cubit.dart';
import 'package:rashed_app/features/auth/presentation/screens/login_screen.dart';

class MockLoginWithEmailUseCase extends Mock implements LoginWithEmailUseCase {}

class MockLoginWithLinkedInUseCase extends Mock
    implements LoginWithLinkedInUseCase {}

class MockRegisterWithLinkedInUseCase extends Mock
    implements RegisterWithLinkedInUseCase {}

class MockClerkAuthService extends Mock implements ClerkAuthService {}

class MockStorage extends Mock implements SecureStorageService {}

class MockContext extends Mock implements BuildContext {}

void main() {
  late LoginCubit cubit;
  late MockLoginWithLinkedInUseCase loginLinkedIn;
  late MockRegisterWithLinkedInUseCase registerLinkedIn;
  late MockClerkAuthService clerk;
  late MockStorage storage;

  setUpAll(() {
    registerFallbackValue(
      const LoginWithLinkedInParams(clerkSessionJwt: 'token'),
    );
    registerFallbackValue(
      const RegisterWithLinkedInParams(clerkSessionJwt: 'token'),
    );
    registerFallbackValue(MockContext());
  });

  setUp(() {
    loginLinkedIn = MockLoginWithLinkedInUseCase();
    registerLinkedIn = MockRegisterWithLinkedInUseCase();
    clerk = MockClerkAuthService();
    storage = MockStorage();
    when(() => storage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        )).thenAnswer((_) async {});
    cubit = LoginCubit(
      loginWithEmailUseCase: MockLoginWithEmailUseCase(),
      loginWithLinkedInUseCase: loginLinkedIn,
      registerWithLinkedInUseCase: registerLinkedIn,
      clerkAuthService: clerk,
      session: RashedSession(storage),
    );
  });

  tearDown(() => cubit.close());

  Future<void> pumpLogin(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        supportedLocales: const [Locale('en'), Locale('ar')],
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        initialRoute: '/login-under-test',
        onGenerateRoute: (settings) {
          if (settings.name == RoutesName.home) {
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => const Text('home-route'),
            );
          }
          return MaterialPageRoute<void>(
            settings: settings,
            builder: (_) => BlocProvider.value(
              value: cubit,
              child: const LoginScreen(),
            ),
          );
        },
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('a 409 shows the localized message and email sign-in',
      (tester) async {
    when(() => clerk.signInWithLinkedIn(any())).thenAnswer(
      (_) async => const SocialAuthResult(accessToken: 'clerk-session'),
    );
    when(() => loginLinkedIn(any())).thenAnswer(
      (_) async => const Left(
        NotFoundFailure('User not found. Please register first.'),
      ),
    );
    when(() => registerLinkedIn(any())).thenAnswer(
      (_) async => const Left(
        ConflictFailure(LinkedInAuthConflicts.emailAccountExists),
      ),
    );

    await pumpLogin(tester);
    await tester.ensureVisible(find.text('Login with your LinkedIn account'));
    await tester.tap(find.text('Login with your LinkedIn account'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('sign_in_with_email')), findsOneWidget);
    expect(find.text('Sign in with email'), findsOneWidget);
    expect(
      find.text(LinkedInAuthConflicts.emailAccountExists),
      findsOneWidget,
    );
    expect(find.text('home-route'), findsNothing);
    verifyNever(() => storage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        ));

    await tester.tap(find.byKey(const Key('sign_in_with_email')));
    await tester.pump();
    final email = tester.widget<EditableText>(find.byType(EditableText).first);
    expect(email.focusNode.hasFocus, isTrue);
  });

  testWidgets('Home opens only after the Rashed token is stored',
      (tester) async {
    var stored = false;
    when(() => storage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        )).thenAnswer((invocation) async {
      if (invocation.namedArguments[#key] == 'token') stored = true;
    });
    when(() => clerk.signInWithLinkedIn(any())).thenAnswer(
      (_) async => const SocialAuthResult(accessToken: 'clerk-session'),
    );
    when(() => loginLinkedIn(any())).thenAnswer(
      (_) async => const Right(User(
        id: 'user-1',
        email: 'ada@example.com',
        token: 'rashed-token',
      )),
    );

    await pumpLogin(tester);
    expect(find.text('home-route'), findsNothing);
    await tester.ensureVisible(find.text('Login with your LinkedIn account'));
    await tester.tap(find.text('Login with your LinkedIn account'));
    await tester.pump();
    await tester.pump();
    expect(stored, isTrue);
    expect(find.text('home-route'), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
  });
}
