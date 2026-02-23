import 'package:equatable/equatable.dart';

class CvAnalysisResult extends Equatable {
  final String fullName;
  final List<String> jobTitles;
  final List<String> skills;

  const CvAnalysisResult({
    required this.fullName,
    required this.jobTitles,
    required this.skills,
  });

  @override
  List<Object> get props => [fullName, jobTitles, skills];
}
