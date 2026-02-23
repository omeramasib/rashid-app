import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/linkedin_repository.dart';

class DisconnectLinkedInUseCase implements UseCase<void, NoParams> {
  final LinkedInRepository repository;

  DisconnectLinkedInUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(NoParams params) async {
    return await repository.disconnectLinkedIn();
  }
}
