import 'package:equatable/equatable.dart';

import 'cv_analysis_result.dart';

enum CvAnalysisStatus { pending, inProgress, processed, failed }

/// The authenticated user's CV as returned by GET /api/v1/cv/me.
///
/// Personal fields are display data only and are never written to secure storage.
class CvProfile extends Equatable {
  final String cvId;
  final CvAnalysisStatus status;
  final String? fullName;
  final List<String> jobTitles;
  final List<String> skills;

  const CvProfile({
    required this.cvId,
    required this.status,
    this.fullName,
    this.jobTitles = const [],
    this.skills = const [],
  });

  CvAnalysisResult toAnalysisResult() {
    return CvAnalysisResult(
      fullName: fullName ?? '',
      jobTitles: List<String>.from(jobTitles),
      skills: List<String>.from(skills),
    );
  }

  @override
  List<Object?> get props => [cvId, status, fullName, jobTitles, skills];
}
