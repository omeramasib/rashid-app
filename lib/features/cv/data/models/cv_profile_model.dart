import '../../../../core/error/exceptions.dart';
import '../../domain/entities/cv_profile.dart';

class CvProfileModel extends CvProfile {
  const CvProfileModel({
    required super.cvId,
    required super.status,
    super.fullName,
    super.jobTitles,
    super.skills,
  });

  /// Accepts a Dio body that is already unwrapped, still enveloped, or null.
  ///
  /// An HTTP 200 envelope with `"data": null` is no CV. The interceptor keeps
  /// that null, and an envelope that still arrives here is not a profile.
  static CvProfile? parse(dynamic data) {
    if (data == null) return null;
    final map = _map(data);
    if (map.containsKey('status') && map.containsKey('data')) {
      final inner = map['data'];
      if (inner == null) return null;
      return _fromMap(_map(inner));
    }
    return _fromMap(map);
  }

  static CvProfileModel _fromMap(Map<String, dynamic> json) {
    final cvId = json['cv_id'];
    if (cvId is! String || cvId.isEmpty) {
      throw ServerException('Unexpected CV profile response');
    }
    final name = json['full_name'];
    if (name != null && name is! String) {
      throw ServerException('Unexpected CV profile response');
    }
    return CvProfileModel(
      cvId: cvId,
      status: _status(json['analysis_status']),
      fullName: name,
      jobTitles: _strings(json['job_titles']),
      skills: _strings(json['skills']),
    );
  }

  static CvAnalysisStatus _status(dynamic raw) {
    switch (raw) {
      case 'pending':
        return CvAnalysisStatus.pending;
      case 'in_progress':
        return CvAnalysisStatus.inProgress;
      case 'processed':
        return CvAnalysisStatus.processed;
      case 'failed':
        return CvAnalysisStatus.failed;
      default:
        throw ServerException('Unexpected CV profile response');
    }
  }

  static List<String> _strings(dynamic raw) {
    if (raw == null) return const [];
    if (raw is! List) {
      throw ServerException('Unexpected CV profile response');
    }
    final values = <String>[];
    for (final item in raw) {
      if (item is! String) {
        throw ServerException('Unexpected CV profile response');
      }
      values.add(item);
    }
    return values;
  }

  static Map<String, dynamic> _map(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    throw ServerException('Unexpected CV profile response');
  }
}
