import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/linkedin_oauth_start.dart';
import '../repositories/linkedin_repository.dart';

class StartLinkedInOAuthUseCase
    implements UseCase<LinkedInOAuthStart, LinkedInSimulationParams> {
  final LinkedInRepository repository;

  StartLinkedInOAuthUseCase(this.repository);

  @override
  Future<Either<Failure, LinkedInOAuthStart>> call(
    LinkedInSimulationParams params,
  ) {
    return repository.startOAuth(params.simulationId);
  }
}

class LinkedInSimulationParams extends Equatable {
  final String simulationId;

  const LinkedInSimulationParams({required this.simulationId});

  @override
  List<Object> get props => [simulationId];
}
