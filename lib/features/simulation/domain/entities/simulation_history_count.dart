import 'package:equatable/equatable.dart';

class SimulationHistoryCount extends Equatable {
  final int totalSimulations;

  const SimulationHistoryCount({required this.totalSimulations});

  @override
  List<Object> get props => [totalSimulations];
}
