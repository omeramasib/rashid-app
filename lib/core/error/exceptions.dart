import 'password_reset_problem.dart';

class AppException implements Exception {
  final String message;
  AppException(this.message);

  @override
  String toString() => message;
}

class PasswordResetApiException extends AppException {
  final PasswordResetProblem problem;
  final Set<String> fields;

  PasswordResetApiException(this.problem, {this.fields = const {}})
      : super('Password reset request failed');
}

class ServerException extends AppException {
  ServerException(super.message);
}

class CacheException extends AppException {
  CacheException(super.message);
}

class AuthException extends AppException {
  AuthException(super.message);
}

class UserNotFoundException extends AppException {
  UserNotFoundException(super.message);
}

class BadRequestException extends AppException {
  BadRequestException(super.message);
}

class UnauthorizedException extends AppException {
  UnauthorizedException(super.message);
}

class ForbiddenException extends AppException {
  ForbiddenException(super.message);
}

class NotFoundException extends AppException {
  NotFoundException(super.message);
}

class NetworkException extends AppException {
  NetworkException(super.message);
}

class RequestTimeoutException extends NetworkException {
  RequestTimeoutException(super.message);
}

class RequestCancelledException extends AppException {
  RequestCancelledException(super.message);
}

class ConflictException extends AppException {
  ConflictException(super.message);
}

class GoneException extends AppException {
  GoneException(super.message);
}

class PayloadTooLargeException extends AppException {
  PayloadTooLargeException(super.message);
}

class ValidationException extends AppException {
  ValidationException(super.message);
}

class RateLimitException extends AppException {
  RateLimitException(super.message);
}

class ServiceUnavailableException extends AppException {
  ServiceUnavailableException(super.message);
}

class GatewayTimeoutException extends AppException {
  GatewayTimeoutException(super.message);
}

class UpstreamException extends AppException {
  UpstreamException(super.message);
}

/// A failed interview start. [cause] is the mapped transport error.
/// [simulationId] comes from the `X-Simulation-Id` response header when the
/// backend kept the failed simulation.
class InterviewStartException extends AppException {
  final AppException cause;
  final String? simulationId;

  InterviewStartException(this.cause, {this.simulationId})
      : super(cause.message);
}
