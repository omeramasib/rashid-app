import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rashed_app/core/error/failures.dart';
import 'package:rashed_app/core/error/password_reset_problem.dart';
import 'package:rashed_app/features/auth/domain/usecases/forgot_password_usecase.dart';
import 'package:rashed_app/features/auth/domain/usecases/resend_otp_usecase.dart';
import 'package:rashed_app/features/auth/domain/usecases/reset_password_usecase.dart';
import 'package:rashed_app/features/auth/presentation/cubit/password/password_cubit.dart';

class MockForgot extends Mock implements ForgotPasswordUseCase {}

class MockResend extends Mock implements ResendOtpUseCase {}

class MockReset extends Mock implements ResetPasswordUseCase {}

void main() {
  setUpAll(() {
    registerFallbackValue(
        const ForgotPasswordParams(email: 'test@example.com'));
    registerFallbackValue(const ResetPasswordParams(
      email: 'test@example.com',
      otp: '012345',
      newPassword: 'password123',
      confirmPassword: 'password123',
    ));
  });

  late MockForgot forgot;
  late MockResend resend;
  late MockReset reset;
  late PasswordCubit cubit;
  late DateTime clock;

  setUp(() {
    forgot = MockForgot();
    resend = MockResend();
    reset = MockReset();
    clock = DateTime(2026);
    when(() => forgot(any())).thenAnswer((_) async => const Right(null));
    when(() => resend(any())).thenAnswer((_) async => const Right(null));
    when(() => reset(any())).thenAnswer((_) async => const Right(null));
    cubit = PasswordCubit(
      forgotPasswordUseCase: forgot,
      resendOtpUseCase: resend,
      resetPasswordUseCase: reset,
      now: () => clock,
    );
  });

  tearDown(() async => cubit.close());

  test('initial state and invalid email do not call the backend', () async {
    expect(cubit.state.status, PasswordStatus.initial);
    await cubit.requestCode('invalid');
    expect(cubit.state.failure!.problem, PasswordResetProblem.invalidEmail);
    verifyNever(() => forgot(any()));
  });

  test('request transitions through loading and acceptance with trimmed email',
      () async {
    final statuses = <PasswordStatus>[];
    final subscription = cubit.stream.listen((s) => statuses.add(s.status));
    await cubit.requestCode('  test@example.com  ');
    await Future<void>.delayed(Duration.zero);
    expect(statuses.first, PasswordStatus.submittingEmail);
    expect(statuses.last, PasswordStatus.emailAccepted);
    expect(cubit.state.email, 'test@example.com');
    expect(cubit.state.remainingSeconds, 60);
    verify(() => forgot(const ForgotPasswordParams(email: 'test@example.com')))
        .called(1);
    await subscription.cancel();
  });

  test('prevents duplicate requests and honors the 60 second resend cooldown',
      () async {
    final pending = Completer<Either<Failure, void>>();
    when(() => forgot(any())).thenAnswer((_) => pending.future);
    final first = cubit.requestCode('test@example.com');
    await cubit.requestCode('test@example.com');
    verify(() => forgot(any())).called(1);
    pending.complete(const Right(null));
    await first;
    await cubit.resendCode();
    verifyNever(() => resend(any()));
    clock = clock.add(const Duration(seconds: 60));
    cubit.refreshCooldown();
    expect(cubit.state.remainingSeconds, 0);
    await cubit.resendCode();
    expect(cubit.state.status, PasswordStatus.resendAccepted);
    expect(cubit.state.remainingSeconds, 60);
    verify(() => resend('test@example.com')).called(1);
  });

  test('abandoning the flow ignores a late request response', () async {
    final pending = Completer<Either<Failure, void>>();
    when(() => forgot(any())).thenAnswer((_) => pending.future);
    final request = cubit.requestCode('test@example.com');
    cubit.clearFlow();
    pending.complete(const Right(null));
    await request;
    expect(cubit.state, const PasswordState());
  });

  test('reset sends exact credentials and clears them after success', () async {
    await cubit.requestCode('test@example.com');
    cubit.setOtp('012345');
    await cubit.resetPassword(' password123 ', ' password123 ');
    verify(() => reset(const ResetPasswordParams(
          email: 'test@example.com',
          otp: '012345',
          newPassword: ' password123 ',
          confirmPassword: ' password123 ',
        ))).called(1);
    expect(cubit.state.status, PasswordStatus.resetSuccess);
    expect(cubit.state.email, isEmpty);
    expect(cubit.state.otp, isEmpty);
  });

  test('rejects short password and mismatch without a request', () async {
    await cubit.requestCode('test@example.com');
    cubit.setOtp('012345');
    await cubit.resetPassword('short', 'short');
    expect(cubit.state.failure!.fields, {'new_password'});
    await cubit.resetPassword('password123', 'different123');
    expect(cubit.state.failure!.problem,
        PasswordResetProblem.confirmationMismatch);
    verifyNever(() => reset(any()));
  });

  for (final problem in [
    PasswordResetProblem.invalidOtp,
    PasswordResetProblem.expiredOtp,
    PasswordResetProblem.timeout,
    PasswordResetProblem.offline,
    PasswordResetProblem.server,
  ]) {
    test('keeps email and code after $problem reset failure', () async {
      when(() => reset(any())).thenAnswer((_) async =>
          Left(PasswordResetFailure(problem, fields: const {'otp'})));
      await cubit.requestCode('test@example.com');
      cubit.setOtp('012345');
      await cubit.resetPassword('password123', 'password123');
      expect(cubit.state.status, PasswordStatus.failure);
      expect(cubit.state.failure!.problem, problem);
      expect(cubit.state.email, 'test@example.com');
      expect(cubit.state.otp, '012345');
    });
  }
}
