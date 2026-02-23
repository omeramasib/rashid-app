import 'package:dio/dio.dart';
import '../error/exceptions.dart';

/// Unwraps the standard envelope { "status": "success", "message": "...", "data": {} }
/// and maps HTTP error codes to typed domain exceptions.
class ResponseInterceptor extends Interceptor {
  // ── SUCCESS PATH ────────────────────────────────────────────────────────────
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final body = response.data;

    // Only unwrap when the envelope shape is present.
    if (body is Map<String, dynamic> && body.containsKey('status')) {
      if (body['status'] == 'success') {
        // Replace response.data with just the inner "data" field
        response.data = body['data'] ?? body;
        return handler.next(response);
      } else {
        // status == 'error' / 'fail' returned as HTTP 200 — treat as error
        return handler.reject(
          DioException(
            requestOptions: response.requestOptions,
            response: response,
            type: DioExceptionType.badResponse,
            error: body['message'] ?? 'Unknown error',
          ),
        );
      }
    }

    // No envelope — pass through as-is
    handler.next(response);
  }

  // ── ERROR PATH ───────────────────────────────────────────────────────────────
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final response = err.response;
    final code = response?.statusCode;
    final body = response?.data;

    final message = _extractMessage(body) ?? err.message ?? 'Unknown error';

    switch (code) {
      case 400:
        handler.reject(_reject(err, BadRequestException(message)));
      case 401:
        handler.reject(_reject(err, UnauthorizedException(message)));
      case 403:
        handler.reject(_reject(err, ForbiddenException(message)));
      case 404:
        handler.reject(_reject(err, NotFoundException(message)));
      case 502:
        handler.reject(_reject(err, UpstreamException(message)));
      default:
        if (err.type == DioExceptionType.connectionTimeout ||
            err.type == DioExceptionType.receiveTimeout) {
          handler
              .reject(_reject(err, NetworkException('Connection timed out')));
        } else if (err.type == DioExceptionType.connectionError) {
          handler
              .reject(_reject(err, NetworkException('No internet connection')));
        } else {
          handler.reject(_reject(err, ServerException(message)));
        }
    }
  }

  // ── HELPERS ──────────────────────────────────────────────────────────────────
  String? _extractMessage(dynamic body) {
    if (body is Map<String, dynamic>) {
      final raw = body['detail'] ?? body['message'] ?? body['error'];
      if (raw is String) return raw;
      if (raw is List)
        return (raw.first?['msg'] ?? raw.first?.toString())?.toString();
    }
    return null;
  }

  DioException _reject(DioException original, Exception error) => DioException(
        requestOptions: original.requestOptions,
        response: original.response,
        type: original.type,
        error: error,
      );
}
