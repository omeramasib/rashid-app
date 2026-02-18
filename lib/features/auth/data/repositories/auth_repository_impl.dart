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

  /// Generic handler for auth requests that maps exceptions to failures
  Future<Either<Failure, User>> _handleAuthRequest(
    Future<User> Function() request,
  ) async {
    try {
      final user = await request();
      return Right(user);
    } on UserNotFoundException catch (e) {
      return Left(UserNotFoundFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      print('DEBUG: AuthRepository - Unexpected error: $e');
      return Left(ServerFailure('Unexpected Error: $e'));
    }
  }
}
