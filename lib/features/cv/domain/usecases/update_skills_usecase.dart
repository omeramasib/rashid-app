import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/cv_repository.dart';

class UpdateSkillsUseCase implements UseCase<void, UpdateSkillsParams> {
  final CvRepository repository;

  UpdateSkillsUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(UpdateSkillsParams params) async {
    return await repository.updateSkills(params.skills);
  }
}

class UpdateSkillsParams extends Equatable {
  final List<String> skills;

  const UpdateSkillsParams({required this.skills});

  @override
  List<Object> get props => [skills];
}
