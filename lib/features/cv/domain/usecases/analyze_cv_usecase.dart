import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/cv_analysis_result.dart';
import '../repositories/cv_repository.dart';

class AnalyzeCvUseCase implements UseCase<CvAnalysisResult, AnalyzeCvParams> {
  final CvRepository repository;

  AnalyzeCvUseCase(this.repository);

  @override
  Future<Either<Failure, CvAnalysisResult>> call(AnalyzeCvParams params) async {
    return await repository.analyzeCv(params.cvId);
  }
}

class AnalyzeCvParams extends Equatable {
  final String cvId;

  const AnalyzeCvParams({required this.cvId});

  @override
  List<Object> get props => [cvId];
}
