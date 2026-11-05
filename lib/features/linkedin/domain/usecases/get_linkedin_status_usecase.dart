import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/linkedin_connection_status.dart';
import '../repositories/linkedin_repository.dart';

class GetLinkedInStatusUseCase
    implements UseCase<LinkedInConnectionStatus, NoParams> {
  final LinkedInRepository repository;

  GetLinkedInStatusUseCase(this.repository);

  @override
  Future<Either<Failure, LinkedInConnectionStatus>> call(NoParams params) {
    return repository.getStatus();
  }
}
