import 'package:dio/dio.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/error/exceptions.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  /// Login with email and password
  /// POST /auth/login/email
  Future<UserModel> loginWithEmail(String email, String password);

  /// Register with email
  /// POST /auth/register/email
  Future<UserModel> registerWithEmail({
    required String name,
    required String email,
    required String password,
  });

  /// Login with LinkedIn via Clerk session JWT
  /// POST /auth/login/linkedin
  Future<UserModel> loginWithLinkedIn(String clerkSessionJwt);

  /// Register with LinkedIn via Clerk session JWT
  /// POST /auth/register/linkedin
  Future<UserModel> registerWithLinkedIn(String clerkSessionJwt);

  /// Forgot password
  /// POST /auth/forgot-password
  Future<void> forgotPassword(String email);

  /// Reset password
  /// POST /auth/reset-password
  Future<void> resetPassword(String token, String newPassword);

  /// Change password
  /// POST /auth/change-password
  Future<void> changePassword(String currentPassword, String newPassword);

  /// Logout
  /// POST /auth/logout
  Future<void> logout();

  /// Get current user
  /// GET /auth/me
  Future<UserModel> getCurrentUser();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final DioClient client;

  AuthRemoteDataSourceImpl({required this.client});

  Dio get _dio => client.dio;

  @override
  Future<UserModel> loginWithEmail(String email, String password) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.loginEmail,
        data: {
          'email': email,
          'password': password,
        },
      );
      return UserModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw e.error is AppException
          ? e.error as AppException
          : ServerException(e.message ?? 'Unknown error');
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<UserModel> registerWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.registerEmail,
        data: {
          'name': name,
          'email': email,
          'password': password,
        },
      );
      return UserModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw e.error is AppException
          ? e.error as AppException
          : ServerException(e.message ?? 'Unknown error');
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<UserModel> loginWithLinkedIn(String clerkSessionJwt) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.loginLinkedIn,
        data: {
          'clerk_session_jwt': clerkSessionJwt,
        },
      );
      return UserModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw e.error is AppException
          ? e.error as AppException
          : ServerException(e.message ?? 'Unknown error');
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<UserModel> registerWithLinkedIn(String clerkSessionJwt) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.registerLinkedIn,
        data: {
          'clerk_session_jwt': clerkSessionJwt,
        },
      );
      return UserModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw e.error is AppException
          ? e.error as AppException
          : ServerException(e.message ?? 'Unknown error');
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> forgotPassword(String email) async {
    try {
      await _dio.post(
        ApiEndpoints.forgotPassword,
        data: {'email': email},
      );
    } on DioException catch (e) {
      throw e.error is AppException
          ? e.error as AppException
          : ServerException(e.message ?? 'Unknown error');
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> resetPassword(String token, String newPassword) async {
    try {
      await _dio.post(
        ApiEndpoints.resetPassword,
        data: {'token': token, 'new_password': newPassword},
      );
    } on DioException catch (e) {
      throw e.error is AppException
          ? e.error as AppException
          : ServerException(e.message ?? 'Unknown error');
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> changePassword(
      String currentPassword, String newPassword) async {
    try {
      await _dio.post(
        ApiEndpoints.changePassword,
        data: {
          'current_password': currentPassword,
          'new_password': newPassword
        },
      );
    } on DioException catch (e) {
      throw e.error is AppException
          ? e.error as AppException
          : ServerException(e.message ?? 'Unknown error');
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _dio.post(ApiEndpoints.logout);
    } on DioException catch (e) {
      throw e.error is AppException
          ? e.error as AppException
          : ServerException(e.message ?? 'Unknown error');
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<UserModel> getCurrentUser() async {
    try {
      final response = await _dio.get(ApiEndpoints.currentUser);
      return UserModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw e.error is AppException
          ? e.error as AppException
          : ServerException(e.message ?? 'Unknown error');
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
