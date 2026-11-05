import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/linkedin_share_preview.dart';
import '../repositories/linkedin_repository.dart';
import 'start_linkedin_oauth_usecase.dart';

class PreviewLinkedInShareUseCase
    implements UseCase<LinkedInSharePreview, LinkedInSimulationParams> {
  final LinkedInRepository repository;

  PreviewLinkedInShareUseCase(this.repository);

  @override
  Future<Either<Failure, LinkedInSharePreview>> call(
    LinkedInSimulationParams params,
  ) {
    return repository.previewShare(params.simulationId);
  }
}
