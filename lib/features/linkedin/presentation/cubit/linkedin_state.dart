part of 'linkedin_cubit.dart';

abstract class LinkedInState extends Equatable {
  const LinkedInState();

  @override
  List<Object?> get props => [];
}

class LinkedInInitial extends LinkedInState {}

class LinkedInLoading extends LinkedInState {}

class LinkedInConnected extends LinkedInState {
  final LinkedInAccount account;

  const LinkedInConnected(this.account);

  @override
  List<Object?> get props => [account];
}

class LinkedInDisconnected extends LinkedInState {}

class LinkedInError extends LinkedInState {
  final String message;

  const LinkedInError(this.message);

  @override
  List<Object?> get props => [message];
}
