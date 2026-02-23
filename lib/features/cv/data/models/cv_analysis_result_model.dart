import '../../domain/entities/cv_analysis_result.dart';

class CvAnalysisResultModel extends CvAnalysisResult {
  const CvAnalysisResultModel({
    required super.fullName,
    required super.jobTitles,
    required super.skills,
  });

  factory CvAnalysisResultModel.fromJson(Map<String, dynamic> json) {
    return CvAnalysisResultModel(
      fullName: json['full_name'] ?? '',
      jobTitles: List<String>.from(json['job_titles'] ?? []),
      skills: List<String>.from(json['skills'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'full_name': fullName,
      'job_titles': jobTitles,
      'skills': skills,
    };
  }
}
