part of 'register_cubit.dart';


abstract class RegisterState extends Equatable {}

class RegisterInitial extends RegisterState {
  @override
  List<Object> get props => [];
}

// OnProgress state
class RegisterOnProgress extends RegisterState {
  @override
  List<Object> get props => [];
}

// OnSuccess state
class RegisterSuccess extends RegisterState {
  final String message;
  final String token;
  RegisterSuccess({required this.message, required this.token});

  @override
  List<Object> get props => [message];
}

// OnFailure state
class RegisterFailure extends RegisterState {
  final String errorMessage;
  RegisterFailure({required this.errorMessage});
  @override
  List<Object> get props => [errorMessage];
}

class ViewPasswordState extends RegisterState {
  final bool enabled;

  ViewPasswordState({required this.enabled});
  @override
  List<Object> get props => [enabled];
}