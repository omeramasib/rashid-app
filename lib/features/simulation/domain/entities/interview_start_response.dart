import 'package:equatable/equatable.dart';
import 'interview_question.dart';

class InterviewStartResponse extends Equatable {
  final String simulationId;
  final String interviewSettingId;
  final List<InterviewQuestion> questions;

  const InterviewStartResponse({
    required this.simulationId,
    required this.interviewSettingId,
    required this.questions,
  });

  @override
  List<Object> get props => [simulationId, interviewSettingId, questions];
}
