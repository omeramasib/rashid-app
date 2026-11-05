part of 'simulation_history_count_cubit.dart';

abstract class SimulationHistoryCountState extends Equatable {
  const SimulationHistoryCountState();

  @override
  List<Object?> get props => [];
}

class SimulationHistoryCountInitial extends SimulationHistoryCountState {
  const SimulationHistoryCountInitial();
}

class SimulationHistoryCountLoading extends SimulationHistoryCountState {
  const SimulationHistoryCountLoading();
}

class SimulationHistoryCountSuccess extends SimulationHistoryCountState {
  final int totalSimulations;

  const SimulationHistoryCountSuccess(this.totalSimulations);

  @override
  List<Object?> get props => [totalSimulations];
}

class SimulationHistoryCountFailure extends SimulationHistoryCountState {
  const SimulationHistoryCountFailure();
}
