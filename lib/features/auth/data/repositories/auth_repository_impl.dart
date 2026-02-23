import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

/// Implementation of [AuthRepository] that delegates to remote data source.
///
/// Maps data layer exceptions to domain layer failures.
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, User>> loginWithEmail(
    String email,
    String password,
  ) async {
    return _handleAuthRequest(
      () => remoteDataSource.loginWithEmail(email, password),
    );
  }

  @override
  Future<Either<Failure, User>> registerWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    return _handleAuthRequest(
      () => remoteDataSource.registerWithEmail(
        name: name,
        email: email,
        password: password,
      ),
    );
  }

  @override
  Future<Either<Failure, User>> loginWithLinkedIn(
      String clerkSessionJwt) async {
    return _handleAuthRequest(
      () => remoteDataSource.loginWithLinkedIn(clerkSessionJwt),
    );
  }

  @override
  Future<Either<Failure, User>> registerWithLinkedIn(
    String clerkSessionJwt,
  ) async {
    return _handleAuthRequest(
      () => remoteDataSource.registerWithLinkedIn(clerkSessionJwt),
    );
  }

  @override
  Future<Either<Failure, void>> forgotPassword(String email) async {
    return _handleVoidAuthRequest(
      () => remoteDataSource.forgotPassword(email),
    );
  }

  @override
  Future<Either<Failure, void>> resetPassword(
      String token, String newPassword) async {
    return _handleVoidAuthRequest(
      () => remoteDataSource.resetPassword(token, newPassword),
    );
  }

  @override
  Future<Either<Failure, void>> changePassword(
      String currentPassword, String newPassword) async {
    return _handleVoidAuthRequest(
      () => remoteDataSource.changePassword(currentPassword, newPassword),
    );
  }

  @override
  Future<Either<Failure, void>> logout() async {
    return _handleVoidAuthRequest(
      () => remoteDataSource.logout(),
    );
  }

  @override
  Future<Either<Failure, User>> getCurrentUser() async {
    return _handleAuthRequest(
      () => remoteDataSource.getCurrentUser(),
    );
  }

  /// Generic handler for auth requests that maps exceptions to failures
  Future<Either<Failure, T>> _handle<T>(Future<T> Function() request) async {
    try {
      final result = await request();
      return Right(result);
    } on UserNotFoundException catch (e) {
      return Left(UserNotFoundFailure(e.message));
    } on BadRequestException catch (e) {
      return Left(BadRequestFailure(e.message));
    } on UnauthorizedException catch (e) {
      return Left(UnauthorizedFailure(e.message));
    } on ForbiddenException catch (e) {
      return Left(ForbiddenFailure(e.message));
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on UpstreamException catch (e) {
      return Left(UpstreamFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      print('DEBUG: AuthRepository - Unexpected error: $e');
      return Left(ServerFailure('Unexpected Error: $e'));
    }
  }

  Future<Either<Failure, User>> _handleAuthRequest(
    Future<User> Function() request,
  ) async {
    return _handle<User>(request);
  }

  Future<Either<Failure, void>> _handleVoidAuthRequest(
    Future<void> Function() request,
  ) async {
    return _handle<void>(request);
  }
}
