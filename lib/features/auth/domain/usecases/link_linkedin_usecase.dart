import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/auth_repository.dart';

class LinkLinkedInUseCase implements UseCase<void, LinkLinkedInParams> {
  final AuthRepository repository;

  LinkLinkedInUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(LinkLinkedInParams params) {
    return repository.linkLinkedIn(
      clerkSessionJwt: params.clerkSessionJwt,
      currentPassword: params.currentPassword,
    );
  }
}

class LinkLinkedInParams extends Equatable {
  final String clerkSessionJwt;
  final String currentPassword;

  const LinkLinkedInParams({
    required this.clerkSessionJwt,
    required this.currentPassword,
  });

  @override
  List<Object> get props => [clerkSessionJwt, currentPassword];
}
