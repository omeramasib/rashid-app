import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/password_reset_problem.dart';
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

  /// POST /auth/resend-otp
  Future<void> resendOtp(String email);

  /// Reset password
  /// POST /auth/reset-password
  Future<void> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
    required String confirmPassword,
  });

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
      final appError = e.error;
      String errorMessage = 'Unknown error';

      if (appError is AppException) {
        errorMessage = appError.message;
      } else if (e.response?.data != null) {
        errorMessage = e.response?.data.toString() ?? 'Unknown error';
      } else {
        errorMessage = e.message ?? 'Unknown error';
      }

      debugPrint('loginWithLinkedIn Error Captured: $errorMessage');
      debugPrint('loginWithLinkedIn DioException details:\n'
          '  - Error: ${e.error}\n'
          '  - Message: ${e.message}\n'
          '  - Type: ${e.type}\n'
          '  - Response statusCode: ${e.response?.statusCode}\n'
          '  - Response statusMessage: ${e.response?.statusMessage}\n'
          '  - Response data: ${e.response?.data}');

      throw appError is AppException ? appError : ServerException(errorMessage);
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
    await _postPasswordRequest(ApiEndpoints.forgotPassword, {'email': email});
  }

  @override
  Future<void> resendOtp(String email) async {
    await _postPasswordRequest(ApiEndpoints.resendOtp, {'email': email});
  }

  @override
  Future<void> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
    required String confirmPassword,
  }) async {
    await _postPasswordRequest(ApiEndpoints.resetPassword, {
      'email': email,
      'otp': otp,
      'new_password': newPassword,
      'confirm_password': confirmPassword,
    });
  }

  Future<void> _postPasswordRequest(
      String path, Map<String, String> payload) async {
    try {
      final response = await _dio.post(path, data: payload);
      final body = response.data;
      if (response.statusCode != 200 ||
          body is! Map<String, dynamic> ||
          body['status'] != 'success') {
        throw PasswordResetApiException(PasswordResetProblem.unknown);
      }
    } on DioException catch (e) {
      throw _passwordException(e);
    }
  }

  PasswordResetApiException _passwordException(DioException error) {
    final code = error.response?.statusCode;
    final data = error.response?.data;
    final detail = data is Map ? data['detail'] : null;

    if (code == 400) {
      final text = detail is String ? detail.toLowerCase() : '';
      if (text.contains('confirm') && text.contains('match')) {
        return PasswordResetApiException(
          PasswordResetProblem.confirmationMismatch,
          fields: {'confirm_password'},
        );
      }
      if (text.contains('expir') &&
          (text.contains('code') || text.contains('otp'))) {
        return PasswordResetApiException(
          PasswordResetProblem.expiredOtp,
          fields: {'otp'},
        );
      }
      if (text.contains('code') || text.contains('otp')) {
        return PasswordResetApiException(
          PasswordResetProblem.invalidOtp,
          fields: {'otp'},
        );
      }
    }
    if (code == 422) {
      final fields = <String>{};
      if (detail is List) {
        for (final item in detail) {
          if (item is Map && item['loc'] is List) {
            final location = item['loc'] as List;
            for (final field in location) {
              if (field is String &&
                  const {'email', 'otp', 'new_password', 'confirm_password'}
                      .contains(field)) {
                fields.add(field);
              }
            }
          }
        }
      }
      return PasswordResetApiException(
        PasswordResetProblem.validation,
        fields: fields,
      );
    }
    if (code == 500) {
      return PasswordResetApiException(PasswordResetProblem.server);
    }
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return PasswordResetApiException(PasswordResetProblem.timeout);
    }
    if (error.type == DioExceptionType.connectionError) {
      return PasswordResetApiException(PasswordResetProblem.offline);
    }
    return PasswordResetApiException(PasswordResetProblem.unknown);
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
