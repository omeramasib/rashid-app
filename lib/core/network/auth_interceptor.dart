import 'package:dio/dio.dart';

import '../auth/rashed_session.dart';
import '../auth/rashed_session_rejection.dart';
import 'api_endpoints.dart';

class AuthInterceptor extends Interceptor {
  final RashedSession _session;

  AuthInterceptor(this._session);

  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    if (_isPasswordResetRequest(options.path)) {
      options.headers.remove('Authorization');
      handler.next(options);
      return;
    }
    final token = await _session.readToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (shouldClearRashedSession(
      statusCode: err.response?.statusCode,
      path: err.requestOptions.path,
      wwwAuthenticate: err.response?.headers.value('www-authenticate'),
      detail: responseDetail(err.response?.data),
    )) {
      await _session.clear();
    }
    handler.next(err);
  }

  static bool _isPasswordResetRequest(String path) =>
      path == ApiEndpoints.forgotPassword ||
      path == ApiEndpoints.resendOtp ||
      path == ApiEndpoints.resetPassword;
}
