import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/cv.dart';
import '../repositories/cv_repository.dart';

class UploadCvUseCase implements UseCase<Cv, UploadCvParams> {
  final CvRepository repository;

  UploadCvUseCase(this.repository);

  @override
  Future<Either<Failure, Cv>> call(UploadCvParams params) async {
    return await repository.uploadCv(params.filePath, params.fileName);
  }
}

class UploadCvParams extends Equatable {
  final String filePath;
  final String fileName;

  const UploadCvParams({required this.filePath, required this.fileName});

  @override
  List<Object> get props => [filePath, fileName];
}
