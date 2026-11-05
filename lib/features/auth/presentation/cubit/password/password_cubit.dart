import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../../core/error/failures.dart';
import '../../../../../core/error/password_reset_problem.dart';
import '../../../domain/password_reset_validation.dart';
import '../../../domain/usecases/forgot_password_usecase.dart';
import '../../../domain/usecases/resend_otp_usecase.dart';
import '../../../domain/usecases/reset_password_usecase.dart';

part 'password_state.dart';

class PasswordCubit extends Cubit<PasswordState> {
  final ForgotPasswordUseCase forgotPasswordUseCase;
  final ResendOtpUseCase resendOtpUseCase;
  final ResetPasswordUseCase resetPasswordUseCase;
  final Duration cooldown;
  final DateTime Function() _now;
  Timer? _timer;
  DateTime? _cooldownEndsAt;
  int _generation = 0;

  PasswordCubit({
    required this.forgotPasswordUseCase,
    required this.resendOtpUseCase,
    required this.resetPasswordUseCase,
    this.cooldown = const Duration(seconds: 60),
    DateTime Function()? now,
  })  : _now = now ?? DateTime.now,
        super(const PasswordState());

  Future<void> requestCode(String email) async {
    if (state.isBusy) return;
    final trimmed = email.trim();
    if (!PasswordResetValidation.isValidEmail(trimmed)) {
      _fail(PasswordResetProblem.invalidEmail, fields: {'email'});
      return;
    }
    emit(state.copyWith(
      status: PasswordStatus.submittingEmail,
      email: trimmed,
      otp: '',
      clearFailure: true,
    ));
    final generation = _generation;
    final result =
        await forgotPasswordUseCase(ForgotPasswordParams(email: trimmed));
    if (isClosed || generation != _generation) return;
    result.fold(
      (failure) => _handleFailure(failure),
      (_) {
        _startCooldown();
        emit(state.copyWith(status: PasswordStatus.emailAccepted));
      },
    );
  }

  Future<void> resendCode() async {
    refreshCooldown();
    if (state.isBusy || state.remainingSeconds > 0 || state.email.isEmpty) {
      return;
    }
    emit(state.copyWith(status: PasswordStatus.resending, clearFailure: true));
    final generation = _generation;
    final result = await resendOtpUseCase(state.email);
    if (isClosed || generation != _generation) return;
    result.fold(
      (failure) => _handleFailure(failure),
      (_) {
        _startCooldown();
        emit(state.copyWith(status: PasswordStatus.resendAccepted, otp: ''));
      },
    );
  }

  void setOtp(String otp) {
    if (state.isBusy) return;
    emit(state.copyWith(
      otp: otp,
      status: PasswordStatus.initial,
      clearFailure: true,
    ));
  }

  Future<void> resetPassword(String newPassword, String confirmPassword) async {
    if (state.isBusy) return;
    if (!PasswordResetValidation.isValidEmail(state.email)) {
      _fail(PasswordResetProblem.invalidEmail, fields: {'email'});
      return;
    }
    if (!PasswordResetValidation.isValidOtp(state.otp)) {
      _fail(PasswordResetProblem.invalidOtp, fields: {'otp'});
      return;
    }
    if (!PasswordResetValidation.isValidPassword(newPassword)) {
      _fail(PasswordResetProblem.validation, fields: {'new_password'});
      return;
    }
    if (!PasswordResetValidation.passwordsMatch(newPassword, confirmPassword)) {
      _fail(PasswordResetProblem.confirmationMismatch,
          fields: {'confirm_password'});
      return;
    }
    emit(state.copyWith(status: PasswordStatus.resetting, clearFailure: true));
    final generation = _generation;
    final result = await resetPasswordUseCase(ResetPasswordParams(
      email: state.email,
      otp: state.otp,
      newPassword: newPassword,
      confirmPassword: confirmPassword,
    ));
    if (isClosed || generation != _generation) return;
    result.fold(
      (failure) => _handleFailure(failure),
      (_) {
        _stopCooldown();
        emit(const PasswordState(status: PasswordStatus.resetSuccess));
      },
    );
  }

  void refreshCooldown() {
    final endsAt = _cooldownEndsAt;
    if (endsAt == null || isClosed) return;
    final milliseconds = endsAt.difference(_now()).inMilliseconds;
    final remaining = milliseconds <= 0 ? 0 : (milliseconds / 1000).ceil();
    if (remaining != state.remainingSeconds) {
      emit(state.copyWith(remainingSeconds: remaining));
    }
    if (remaining == 0) _stopCooldown();
  }

  void clearFlow() {
    _generation++;
    _stopCooldown();
    if (!isClosed) emit(const PasswordState());
  }

  void _startCooldown() {
    _stopCooldown();
    _cooldownEndsAt = _now().add(cooldown);
    _timer =
        Timer.periodic(const Duration(seconds: 1), (_) => refreshCooldown());
    refreshCooldown();
  }

  void _stopCooldown() {
    _timer?.cancel();
    _timer = null;
    _cooldownEndsAt = null;
  }

  void _handleFailure(Failure failure) {
    if (failure is PasswordResetFailure) {
      emit(state.copyWith(status: PasswordStatus.failure, failure: failure));
    } else {
      _fail(PasswordResetProblem.unknown);
    }
  }

  void _fail(PasswordResetProblem problem, {Set<String> fields = const {}}) {
    emit(state.copyWith(
      status: PasswordStatus.failure,
      failure: PasswordResetFailure(problem, fields: fields),
    ));
  }

  @override
  Future<void> close() {
    _stopCooldown();
    return super.close();
  }
}
