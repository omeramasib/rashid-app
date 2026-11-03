import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rashed_app/app/app_routes.dart';
import 'package:rashed_app/app_localizations.dart';
import 'package:rashed_app/core/error/failures.dart';
import 'package:rashed_app/core/error/password_reset_problem.dart';
import 'package:rashed_app/features/auth/domain/usecases/forgot_password_usecase.dart';
import 'package:rashed_app/features/auth/domain/usecases/resend_otp_usecase.dart';
import 'package:rashed_app/features/auth/domain/usecases/reset_password_usecase.dart';
import 'package:rashed_app/features/auth/presentation/cubit/login/login_cubit.dart';
import 'package:rashed_app/features/auth/presentation/cubit/password/password_cubit.dart';
import 'package:rashed_app/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:rashed_app/features/auth/presentation/screens/login_screen.dart';
import 'package:rashed_app/features/auth/presentation/screens/otp_verification_screen.dart';
import 'package:rashed_app/features/auth/presentation/screens/reset_password_screen.dart';
import 'package:rashed_app/features/auth/presentation/screens/password_reset_success_screen.dart';

class MockLoginCubit extends MockCubit<LoginState> implements LoginCubit {}

class MockForgot extends Mock implements ForgotPasswordUseCase {}

class MockResend extends Mock implements ResendOtpUseCase {}

class MockReset extends Mock implements ResetPasswordUseCase {}

class LoadedLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  final Map<String, AppLocalizations> loaded;
  const LoadedLocalizationsDelegate(this.loaded);

  @override
  bool isSupported(Locale locale) => loaded.containsKey(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) =>
      SynchronousFuture(loaded[locale.languageCode]!);

  @override
  bool shouldReload(LoadedLocalizationsDelegate old) => false;
}

void main() {
  final loaded = <String, AppLocalizations>{};
  setUpAll(() async {
    for (final code in ['en', 'ar']) {
      final strings = AppLocalizations(Locale(code));
      await strings.loadJsonLanguage();
      loaded[code] = strings;
    }
    registerFallbackValue(
        const ForgotPasswordParams(email: 'test@example.com'));
    registerFallbackValue(const ResetPasswordParams(
      email: 'test@example.com',
      otp: '012345',
      newPassword: 'password123',
      confirmPassword: 'password123',
    ));
  });

  late MockLoginCubit login;
  late MockForgot forgot;
  late MockResend resend;
  late MockReset reset;
  late PasswordCubit password;
  late DateTime now;

  setUp(() {
    login = MockLoginCubit();
    when(() => login.state).thenReturn(LoginInitial());
    when(() => login.stream).thenAnswer((_) => const Stream.empty());
    when(() => login.isPasswordVisible).thenReturn(false);
    when(() => login.loginWithEmail(
          email: any(named: 'email'),
          password: any(named: 'password'),
        )).thenAnswer((_) async {});
    forgot = MockForgot();
    resend = MockResend();
    reset = MockReset();
    when(() => forgot(any())).thenAnswer((_) async => const Right(null));
    when(() => resend(any())).thenAnswer((_) async => const Right(null));
    when(() => reset(any())).thenAnswer((_) async => const Right(null));
    now = DateTime(2026);
    password = PasswordCubit(
      forgotPasswordUseCase: forgot,
      resendOtpUseCase: resend,
      resetPasswordUseCase: reset,
      now: () => now,
    );
  });

  tearDown(() async => password.close());

  Widget app({Locale locale = const Locale('en'), Widget? home}) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<LoginCubit>.value(value: login),
        BlocProvider<PasswordCubit>.value(value: password),
      ],
      child: MaterialApp(
        key: UniqueKey(),
        locale: locale,
        supportedLocales: const [Locale('en'), Locale('ar')],
        localizationsDelegates: [
          LoadedLocalizationsDelegate(loaded),
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        onGenerateRoute: Routes.onGenerateRouted,
        home: home ?? const LoginScreen(),
      ),
    );
  }

  Future<void> pumpApp(WidgetTester tester, Widget widget) async {
    await tester.pumpWidget(widget);
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 20));
    });
    await tester.pumpAndSettle();
  }

  Future<void> openCodeEntry(WidgetTester tester) async {
    await pumpApp(tester, app(home: const ForgotPasswordScreen()));
    expect(find.byType(ForgotPasswordScreen), findsOneWidget);
    await tester.enterText(
        find.byKey(const Key('forgotEmail')), 'test@example.com');
    await tester.tap(find.byKey(const Key('requestCode')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(OTPVerificationScreen), findsOneWidget);
  }

  testWidgets('login opens Forgot Password with prefilled email',
      (tester) async {
    await pumpApp(tester, app());
    await tester.enterText(
        find.byType(TextFormField).first, 'prefilled@example.com');
    await tester.tap(find.text('Forgot password ?'));
    await tester.pumpAndSettle();
    expect(find.byType(ForgotPasswordScreen), findsOneWidget);
    final field = tester.widget<TextField>(find.descendant(
      of: find.byKey(const Key('forgotEmail')),
      matching: find.byType(TextField),
    ));
    expect(field.controller!.text, 'prefilled@example.com');
  });

  testWidgets('invalid email stays on form and makes no request',
      (tester) async {
    await pumpApp(tester, app(home: const ForgotPasswordScreen()));
    expect(find.byType(ForgotPasswordScreen), findsOneWidget);
    await tester.enterText(find.byKey(const Key('forgotEmail')), 'invalid');
    await tester.tap(find.byKey(const Key('requestCode')));
    await tester.pump();
    expect(find.text('Enter a valid email address.'), findsOneWidget);
    verifyNever(() => forgot(any()));
  });

  testWidgets('backend email validation marks the email field', (tester) async {
    when(() => forgot(any())).thenAnswer((_) async => const Left(
        PasswordResetFailure(PasswordResetProblem.validation,
            fields: {'email'})));
    await pumpApp(tester, app(home: const ForgotPasswordScreen()));
    await tester.enterText(
        find.byKey(const Key('forgotEmail')), 'test@example.com');
    await tester.tap(find.byKey(const Key('requestCode')));
    await tester.pump();
    final field = tester.widget<TextField>(find.descendant(
      of: find.byKey(const Key('forgotEmail')),
      matching: find.byType(TextField),
    ));
    expect(field.decoration!.errorText, 'Enter a valid email address.');
    expect(find.byType(ForgotPasswordScreen), findsOneWidget);
  });

  testWidgets('OTP paste, cooldown, visibility, and reset success',
      (tester) async {
    await openCodeEntry(tester);
    final resendButton =
        tester.widget<TextButton>(find.byKey(const Key('resendCode')));
    expect(resendButton.onPressed, isNull);
    await tester.enterText(find.byKey(const Key('otpCode')), '012345');
    expect(password.state.otp, '012345');
    now = now.add(const Duration(seconds: 60));
    password.refreshCooldown();
    await tester.pump();
    await tester.tap(find.byKey(const Key('resendCode')));
    await tester.pump();
    verify(() => resend('test@example.com')).called(1);
    expect(password.state.otp, isEmpty);
    await tester.enterText(find.byKey(const Key('otpCode')), '012345');
    await tester.tap(find.byKey(const Key('continueToPassword')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(ResetPasswordScreen), findsOneWidget);
    await tester.enterText(find.byKey(const Key('newPassword')), 'password123');
    await tester.enterText(
        find.byKey(const Key('confirmPassword')), 'mismatch');
    await tester.tap(find.byKey(const Key('submitReset')));
    await tester.pump();
    expect(find.text('The passwords do not match.'), findsWidgets);
    verifyNever(() => reset(any()));
    await tester.tap(find.byKey(const Key('toggleNewPassword')));
    await tester.pump();
    expect(
        tester
            .widget<TextField>(find.descendant(
              of: find.byKey(const Key('newPassword')),
              matching: find.byType(TextField),
            ))
            .obscureText,
        isFalse);
    await tester.enterText(
        find.byKey(const Key('confirmPassword')), 'password123');
    await tester.tap(find.byKey(const Key('submitReset')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(PasswordResetSuccessScreen), findsOneWidget);
    expect(password.state.otp, isEmpty);
    await tester.tap(find.byKey(const Key('backToLogin')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(LoginScreen), findsOneWidget);
    await tester.enterText(
        find.byType(TextFormField).first, 'test@example.com');
    await tester.enterText(find.byType(TextFormField).last, 'password123');
    await tester.tap(find.text('Login').last);
    await tester.pump();
    verify(() => login.loginWithEmail(
          email: 'test@example.com',
          password: 'password123',
        )).called(1);
  });

  testWidgets('invalid backend OTP keeps input and permits editing the code',
      (tester) async {
    when(() => reset(any())).thenAnswer((_) async => const Left(
        PasswordResetFailure(PasswordResetProblem.invalidOtp,
            fields: {'otp'})));
    await openCodeEntry(tester);
    await tester.enterText(find.byKey(const Key('otpCode')), '012345');
    await tester.tap(find.byKey(const Key('continueToPassword')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.enterText(find.byKey(const Key('newPassword')), 'password123');
    await tester.enterText(
        find.byKey(const Key('confirmPassword')), 'password123');
    await tester.tap(find.byKey(const Key('submitReset')));
    await tester.pump();
    expect(find.byKey(const Key('editCode')), findsOneWidget);
    expect(
        tester
            .widget<TextFormField>(find.byKey(const Key('newPassword')))
            .controller!
            .text,
        'password123');
    await tester.tap(find.byKey(const Key('editCode')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(OTPVerificationScreen), findsOneWidget);
    expect(
        tester
            .widget<TextField>(find.byKey(const Key('otpCode')))
            .controller!
            .text,
        '012345');
  });

  for (final locale in [const Locale('en'), const Locale('ar')]) {
    testWidgets('success screen renders in ${locale.languageCode}',
        (tester) async {
      await pumpApp(tester,
          app(locale: locale, home: const PasswordResetSuccessScreen()));
      expect(find.byKey(const Key('backToLogin')), findsOneWidget);
      expect(
          find.text(locale.languageCode == 'ar'
              ? 'تمت إعادة تعيين كلمة المرور'
              : 'Password Reset Successfully'),
          findsOneWidget);
    });
  }
}
