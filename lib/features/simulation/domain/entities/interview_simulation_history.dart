import 'package:equatable/equatable.dart';

class InterviewSimulationHistory extends Equatable {
  final String id;
  final String jobField;
  final String createdAt;

  const InterviewSimulationHistory({
    required this.id,
    required this.jobField,
    required this.createdAt,
  });

  @override
  List<Object> get props => [id, jobField, createdAt];
}
