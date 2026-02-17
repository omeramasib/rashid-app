part of 'register_cubit.dart';

abstract class RegisterState extends Equatable {
  const RegisterState();

  @override
  List<Object> get props => [];
}

class RegisterInitial extends RegisterState {}

/// Loading state for email registration
class RegisterLoading extends RegisterState {}

/// Loading state for LinkedIn OAuth registration
class RegisterLinkedInLoading extends RegisterState {}

class RegisterSuccess extends RegisterState {
  final User user;
  const RegisterSuccess(this.user);

  @override
  List<Object> get props => [user];
}

class RegisterFailure extends RegisterState {
  final String message;
  const RegisterFailure(this.message);

  @override
  List<Object> get props => [message];
}

class ViewPasswordState extends RegisterState {
  final bool enabled;
  const ViewPasswordState({required this.enabled});

  @override
  List<Object> get props => [enabled];
}
