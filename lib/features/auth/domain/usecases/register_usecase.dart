import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

/// Use case for email registration
class RegisterWithEmailUseCase
    implements UseCase<User, RegisterWithEmailParams> {
  final AuthRepository repository;

  RegisterWithEmailUseCase(this.repository);

  @override
  Future<Either<Failure, User>> call(RegisterWithEmailParams params) async {
    return await repository.registerWithEmail(
      name: params.name,
      email: params.email,
      password: params.password,
    );
  }
}

class RegisterWithEmailParams extends Equatable {
  final String name;
  final String email;
  final String password;

  const RegisterWithEmailParams({
    required this.name,
    required this.email,
    required this.password,
  });

  @override
  List<Object> get props => [name, email, password];
}

/// Use case for LinkedIn registration (Clerk session JWT)
class RegisterWithLinkedInUseCase
    implements UseCase<User, RegisterWithLinkedInParams> {
  final AuthRepository repository;

  RegisterWithLinkedInUseCase(this.repository);

  @override
  Future<Either<Failure, User>> call(RegisterWithLinkedInParams params) async {
    return await repository.registerWithLinkedIn(params.clerkSessionJwt);
  }
}

class RegisterWithLinkedInParams extends Equatable {
  final String clerkSessionJwt;

  const RegisterWithLinkedInParams({required this.clerkSessionJwt});

  @override
  List<Object> get props => [clerkSessionJwt];
}
