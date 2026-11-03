import 'package:equatable/equatable.dart';
import 'password_reset_problem.dart';

abstract class Failure extends Equatable {
  final String message;
  const Failure(this.message);

  @override
  List<Object> get props => [message];
}

class PasswordResetFailure extends Failure {
  final PasswordResetProblem problem;
  final Set<String> fields;

  const PasswordResetFailure(this.problem, {this.fields = const {}})
      : super('Password reset request failed');

  @override
  List<Object> get props => [problem, ...(fields.toList()..sort())];
}

class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

class CacheFailure extends Failure {
  const CacheFailure(super.message);
}

class AuthFailure extends Failure {
  const AuthFailure(super.message);
}

class UserNotFoundFailure extends Failure {
  const UserNotFoundFailure(super.message);
}

class BadRequestFailure extends Failure {
  const BadRequestFailure(super.message);
}

class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure(super.message);
}

class ForbiddenFailure extends Failure {
  const ForbiddenFailure(super.message);
}

class NotFoundFailure extends Failure {
  const NotFoundFailure(super.message);
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

class RequestTimeoutFailure extends NetworkFailure {
  const RequestTimeoutFailure(super.message);
}

class RequestCancelledFailure extends Failure {
  const RequestCancelledFailure(super.message);
}

class ConflictFailure extends Failure {
  const ConflictFailure(super.message);
}

class PayloadTooLargeFailure extends Failure {
  const PayloadTooLargeFailure(super.message);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

class RateLimitFailure extends Failure {
  const RateLimitFailure(super.message);
}

class ServiceUnavailableFailure extends Failure {
  const ServiceUnavailableFailure(super.message);
}

class GatewayTimeoutFailure extends Failure {
  const GatewayTimeoutFailure(super.message);
}

class UpstreamFailure extends Failure {
  const UpstreamFailure(super.message);
}
