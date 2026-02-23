import '../../domain/entities/cv.dart';

class CvModel extends Cv {
  const CvModel({
    required super.cvId,
    required super.fileUrl,
  });

  factory CvModel.fromJson(Map<String, dynamic> json) {
    return CvModel(
      cvId: json['cv_id'] ?? '',
      fileUrl: json['file_url'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cv_id': cvId,
      'file_url': fileUrl,
    };
  }
}
