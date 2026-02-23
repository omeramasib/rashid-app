part of 'password_cubit.dart';

abstract class PasswordState extends Equatable {
  const PasswordState();

  @override
  List<Object?> get props => [];
}

class PasswordInitial extends PasswordState {}

class PasswordLoading extends PasswordState {}

class PasswordError extends PasswordState {
  final String message;

  const PasswordError(this.message);

  @override
  List<Object?> get props => [message];
}

class ForgotPasswordSuccess extends PasswordState {}

class ResetPasswordSuccess extends PasswordState {}
