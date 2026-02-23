import '../../domain/entities/interview_simulation_history.dart';

class InterviewSimulationHistoryModel extends InterviewSimulationHistory {
  const InterviewSimulationHistoryModel({
    required super.id,
    required super.jobField,
    required super.createdAt,
  });

  factory InterviewSimulationHistoryModel.fromJson(Map<String, dynamic> json) {
    return InterviewSimulationHistoryModel(
      id: json['id'] ?? '',
      jobField: json['job_field'] ?? '',
      createdAt: json['created_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'job_field': jobField,
      'created_at': createdAt,
    };
  }
}
