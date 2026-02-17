import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

/// Use case for email/password login
class LoginWithEmailUseCase implements UseCase<User, LoginWithEmailParams> {
  final AuthRepository repository;

  LoginWithEmailUseCase(this.repository);

  @override
  Future<Either<Failure, User>> call(LoginWithEmailParams params) async {
    return await repository.loginWithEmail(params.email, params.password);
  }
}

class LoginWithEmailParams extends Equatable {
  final String email;
  final String password;

  const LoginWithEmailParams({
    required this.email,
    required this.password,
  });

  @override
  List<Object> get props => [email, password];
}

/// Use case for LinkedIn login (token from Clerk OAuth)
class LoginWithLinkedInUseCase implements UseCase<User, LoginWithLinkedInParams> {
  final AuthRepository repository;

  LoginWithLinkedInUseCase(this.repository);

  @override
  Future<Either<Failure, User>> call(LoginWithLinkedInParams params) async {
    return await repository.loginWithLinkedIn(params.linkedinToken);
  }
}

class LoginWithLinkedInParams extends Equatable {
  final String linkedinToken;

  const LoginWithLinkedInParams({required this.linkedinToken});

  @override
  List<Object> get props => [linkedinToken];
}
