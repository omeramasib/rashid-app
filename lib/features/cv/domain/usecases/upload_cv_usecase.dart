import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/cv.dart';
import '../repositories/cv_repository.dart';

class UploadCvUseCase implements UseCase<Cv, UploadCvParams> {
  final CvRepository repository;

  UploadCvUseCase(this.repository);

  void cancel() => repository.cancelUpload();

  @override
  Future<Either<Failure, Cv>> call(UploadCvParams params) {
    return repository.uploadCv(
      bytes: params.bytes,
      fileName: params.fileName,
      onProgress: params.onProgress,
    );
  }
}

class UploadCvParams extends Equatable {
  final Uint8List bytes;
  final String fileName;
  final void Function(int sent, int total) onProgress;

  const UploadCvParams({
    required this.bytes,
    required this.fileName,
    required this.onProgress,
  });

  @override
  List<Object> get props => [fileName, bytes.length];
}
