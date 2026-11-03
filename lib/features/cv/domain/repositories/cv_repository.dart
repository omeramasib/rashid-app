import 'dart:typed_data';

import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/cv.dart';
import '../entities/cv_analysis_result.dart';

abstract class CvRepository {
  Future<Either<Failure, Cv>> uploadCv({
    required Uint8List bytes,
    required String fileName,
    required void Function(int sent, int total) onProgress,
  });

  void cancelUpload();

  Future<Either<Failure, CvAnalysisResult>> analyzeCv(String cvId);

  void cancelAnalysis();

  Future<Either<Failure, void>> updateSkills(List<String> skills);

  Future<Either<Failure, void>> deleteSkill(String skill);
}
