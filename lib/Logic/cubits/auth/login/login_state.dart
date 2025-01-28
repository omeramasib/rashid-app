part of 'login_cubit.dart';


abstract class LoginState extends Equatable {}

class LoginInitial extends LoginState {
  @override
  List<Object> get props => [];
}

// OnProgress state
class LoginOnProgress extends LoginState {
  @override
  List<Object> get props => [];
}

// OnSuccess state
class LoginSuccess extends LoginState {
  final String message;
  final String token;
  LoginSuccess({required this.message, required this.token});

  @override
  List<Object> get props => [message];
}

// OnFailure state
class LoginFailure extends LoginState {
  final String errorMessage;
  LoginFailure({required this.errorMessage});
  @override
  List<Object> get props => [errorMessage];
}

class ViewPasswordState extends LoginState {
  final bool enabled;

  ViewPasswordState({required this.enabled});
  @override
  List<Object> get props => [enabled];
}
// sealed class LoginState extends Equatable {
//   const LoginState();

//   @override
//   List<Object> get props => [];
// }

// final class LoginInitial extends LoginState {}


// import 'package:equatable/equatable.dart';
// part of 'login_cubit.dart';
