import 'package:equatable/equatable.dart';
import '../../../domain/entities/user.dart';

abstract class AuthProfileState extends Equatable {
  const AuthProfileState();

  @override
  List<Object?> get props => [];
}

class AuthProfileInitial extends AuthProfileState {}

class AuthProfileLoading extends AuthProfileState {}

class AuthProfileLoaded extends AuthProfileState {
  final User user;

  const AuthProfileLoaded(this.user);

  @override
  List<Object?> get props => [user];
}

class AuthProfileError extends AuthProfileState {
  final String message;

  const AuthProfileError(this.message);

  @override
  List<Object?> get props => [message];
}

class AuthProfileLoggedOut extends AuthProfileState {}

class PasswordChangeSuccess extends AuthProfileState {}
