import 'package:equatable/equatable.dart';

import 'interview_question.dart';

class InterviewStartResponse extends Equatable {
  final String simulationId;
  final String interviewSettingId;
  final String? status;
  final String? reportStatus;
  final List<InterviewQuestion> questions;

  const InterviewStartResponse({
    required this.simulationId,
    required this.interviewSettingId,
    required this.questions,
    this.status,
    this.reportStatus,
  });

  @override
  List<Object?> get props =>
      [simulationId, interviewSettingId, status, reportStatus, questions];
}
