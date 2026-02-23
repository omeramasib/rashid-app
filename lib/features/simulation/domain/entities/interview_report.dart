import 'package:equatable/equatable.dart';

class InterviewReport extends Equatable {
  final num score;
  final List<String> strengths;
  final List<String> weaknesses;
  final String? overallFeedback;

  const InterviewReport({
    required this.score,
    required this.strengths,
    required this.weaknesses,
    this.overallFeedback,
  });

  @override
  List<Object?> get props => [score, strengths, weaknesses, overallFeedback];
}
