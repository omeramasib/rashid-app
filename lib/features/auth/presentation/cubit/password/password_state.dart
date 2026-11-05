part of 'password_cubit.dart';

enum PasswordStatus {
  initial,
  submittingEmail,
  emailAccepted,
  resending,
  resendAccepted,
  resetting,
  resetSuccess,
  failure,
}

class PasswordState extends Equatable {
  final PasswordStatus status;
  final String email;
  final String otp;
  final int remainingSeconds;
  final PasswordResetFailure? failure;

  const PasswordState({
    this.status = PasswordStatus.initial,
    this.email = '',
    this.otp = '',
    this.remainingSeconds = 0,
    this.failure,
  });

  bool get isBusy =>
      status == PasswordStatus.submittingEmail ||
      status == PasswordStatus.resending ||
      status == PasswordStatus.resetting;

  PasswordState copyWith({
    PasswordStatus? status,
    String? email,
    String? otp,
    int? remainingSeconds,
    PasswordResetFailure? failure,
    bool clearFailure = false,
  }) {
    return PasswordState(
      status: status ?? this.status,
      email: email ?? this.email,
      otp: otp ?? this.otp,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      failure: clearFailure ? null : failure ?? this.failure,
    );
  }

  @override
  List<Object?> get props => [status, email, otp, remainingSeconds, failure];
}
