import '../../domain/entities/simulation_history_count.dart';

class SimulationHistoryCountModel extends SimulationHistoryCount {
  const SimulationHistoryCountModel({required super.totalSimulations});

  factory SimulationHistoryCountModel.fromJson(Map<String, dynamic> json) {
    final value = json['total_simulations'];
    if (value is! int || value < 0) {
      throw const FormatException('total_simulations');
    }
    return SimulationHistoryCountModel(totalSimulations: value);
  }
}
