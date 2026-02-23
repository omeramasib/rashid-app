import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/cv_repository.dart';

class DeleteSkillUseCase implements UseCase<void, DeleteSkillParams> {
  final CvRepository repository;

  DeleteSkillUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(DeleteSkillParams params) async {
    return await repository.deleteSkill(params.skill);
  }
}

class DeleteSkillParams extends Equatable {
  final String skill;

  const DeleteSkillParams({required this.skill});

  @override
  List<Object> get props => [skill];
}
