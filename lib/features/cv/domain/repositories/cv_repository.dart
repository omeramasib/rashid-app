import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/cv.dart';
import '../entities/cv_analysis_result.dart';

abstract class CvRepository {
  Future<Either<Failure, Cv>> uploadCv(String filePath, String fileName);

  Future<Either<Failure, CvAnalysisResult>> analyzeCv(String cvId);

  Future<Either<Failure, void>> updateSkills(List<String> skills);

  Future<Either<Failure, void>> deleteSkill(String skill);
}
