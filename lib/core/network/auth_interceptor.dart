import 'package:dio/dio.dart';
import 'api_endpoints.dart';
import '../storage/secure_storage_service.dart';

class AuthInterceptor extends Interceptor {
  final SecureStorageService _storage;

  AuthInterceptor(this._storage);

  static bool _isPasswordResetRequest(String path) =>
      path == ApiEndpoints.forgotPassword ||
      path == ApiEndpoints.resendOtp ||
      path == ApiEndpoints.resetPassword;

  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    if (_isPasswordResetRequest(options.path)) {
      options.headers.remove('Authorization');
      handler.next(options);
      return;
    }
    final token = await _storage.read(key: 'token');
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401 &&
        !_isPasswordResetRequest(err.requestOptions.path)) {
      // Clear stale session
      await _storage.deleteAll();
      // Optionally fire an event on a global auth stream if needed
    }
    handler.next(err); // Let ResponseInterceptor also see it
  }
}
