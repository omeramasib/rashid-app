import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/linkedin_mark_deleted_result.dart';
import '../repositories/linkedin_repository.dart';

class MarkLinkedInShareDeletedUseCase
    implements
        UseCase<LinkedInMarkDeletedResult, MarkLinkedInShareDeletedParams> {
  final LinkedInRepository repository;

  MarkLinkedInShareDeletedUseCase(this.repository);

  @override
  Future<Either<Failure, LinkedInMarkDeletedResult>> call(
    MarkLinkedInShareDeletedParams params,
  ) {
    return repository.markDeleted(shareId: params.shareId);
  }
}

class MarkLinkedInShareDeletedParams extends Equatable {
  final String shareId;

  const MarkLinkedInShareDeletedParams({required this.shareId});

  @override
  List<Object> get props => [shareId];
}
