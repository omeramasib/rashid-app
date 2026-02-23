import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/linkedin_account.dart';
import '../repositories/linkedin_repository.dart';

class ConnectLinkedInUseCase
    implements UseCase<LinkedInAccount, ConnectLinkedInParams> {
  final LinkedInRepository repository;

  ConnectLinkedInUseCase(this.repository);

  @override
  Future<Either<Failure, LinkedInAccount>> call(
      ConnectLinkedInParams params) async {
    return await repository.connectLinkedIn(params.linkedinAccessToken);
  }
}

class ConnectLinkedInParams extends Equatable {
  final String linkedinAccessToken;

  const ConnectLinkedInParams({required this.linkedinAccessToken});

  @override
  List<Object> get props => [linkedinAccessToken];
}
