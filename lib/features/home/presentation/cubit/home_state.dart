part of 'home_cubit.dart';

abstract class HomeState extends Equatable {
  const HomeState();

  @override
  List<Object?> get props => [];
}

class HomeInitial extends HomeState {}

class HomeSharing extends HomeState {}

class HomeShared extends HomeState {
  final String postUrl;
  const HomeShared(this.postUrl);

  @override
  List<Object?> get props => [postUrl];
}

class HomeError extends HomeState {
  final String message;
  const HomeError(this.message);

  @override
  List<Object?> get props => [message];
}
