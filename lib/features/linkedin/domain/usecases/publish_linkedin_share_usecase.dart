import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/linkedin_publish_result.dart';
import '../repositories/linkedin_repository.dart';

class PublishLinkedInShareUseCase
    implements UseCase<LinkedInPublishResult, PublishLinkedInParams> {
  final LinkedInRepository repository;

  PublishLinkedInShareUseCase(this.repository);

  @override
  Future<Either<Failure, LinkedInPublishResult>> call(
    PublishLinkedInParams params,
  ) {
    return repository.publish(
      previewId: params.previewId,
      simulationId: params.simulationId,
      contentSha256: params.contentSha256,
    );
  }
}

class PublishLinkedInParams extends Equatable {
  final String previewId;
  final String simulationId;
  final String contentSha256;

  const PublishLinkedInParams({
    required this.previewId,
    required this.simulationId,
    required this.contentSha256,
  });

  @override
  List<Object> get props => [previewId, simulationId, contentSha256];
}
