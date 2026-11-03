import 'password_reset_problem.dart';

class AppException implements Exception {
  final String message;
  AppException(this.message);
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

class UpstreamException extends AppException {
  UpstreamException(super.message);
}
