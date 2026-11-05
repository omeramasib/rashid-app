part of 'performance_cubit.dart';

abstract class PerformanceState extends Equatable {
  const PerformanceState();

  @override
  List<Object?> get props => [];
}

class PerformanceInitial extends PerformanceState {
  const PerformanceInitial();
}

class PerformanceLoading extends PerformanceState {
  const PerformanceLoading();
}

class PerformanceSuccess extends PerformanceState {
  final PerformanceSummary summary;

  const PerformanceSuccess(this.summary);

  @override
  List<Object?> get props => [summary];
}

class PerformanceFailure extends PerformanceState {
  final Failure failure;

  const PerformanceFailure(this.failure);

  @override
  List<Object?> get props => [failure];
}
