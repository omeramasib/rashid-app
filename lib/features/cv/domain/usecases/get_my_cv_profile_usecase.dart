import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/cv_profile.dart';
import '../repositories/cv_repository.dart';

class GetMyCvProfileUseCase implements UseCase<CvProfile?, NoParams> {
  final CvRepository repository;

  GetMyCvProfileUseCase(this.repository);

  @override
  Future<Either<Failure, CvProfile?>> call(NoParams params) {
    return repository.getMyCvProfile();
  }
}
