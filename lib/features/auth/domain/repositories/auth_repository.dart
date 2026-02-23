import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/user.dart';

/// Repository contract for authentication operations.
///
/// Defines all auth methods following Clean Architecture principles.
/// Implementation handles data source communication and error mapping.
abstract class AuthRepository {
  /// Login with email and password
  /// Returns User with token on success
  Future<Either<Failure, User>> loginWithEmail(String email, String password);

  /// Register with email
  /// Returns User (may only have user_id, no token)
  Future<Either<Failure, User>> registerWithEmail({
    required String name,
    required String email,
    required String password,
  });

  /// Login with LinkedIn via Clerk session JWT
  /// Returns User with token on success
  Future<Either<Failure, User>> loginWithLinkedIn(String clerkSessionJwt);

  /// Register with LinkedIn via Clerk session JWT
  /// Returns User with token on success
  Future<Either<Failure, User>> registerWithLinkedIn(String clerkSessionJwt);

  /// Forgot password
  Future<Either<Failure, void>> forgotPassword(String email);

  /// Reset password
  Future<Either<Failure, void>> resetPassword(String token, String newPassword);

  /// Change password
  Future<Either<Failure, void>> changePassword(
      String currentPassword, String newPassword);

  /// Logout
  Future<Either<Failure, void>> logout();

  /// Get current user
  Future<Either<Failure, User>> getCurrentUser();
}
