import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
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
        // A present null `data` must stay null. `data ?? body` would hide
        // "no CV" behind the envelope. Responses that omit `data` keep the
        // envelope so callers can still read `status`.
        response.data = body.containsKey('data') ? body['data'] : body;
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
    if (err.type == DioExceptionType.cancel) {
      handler
          .reject(_reject(err, RequestCancelledException('Request cancelled')));
      return;
    }

    final response = err.response;
    debugPrint('Status Code: ${err.response?.statusCode}');
    debugPrint('Error Body: ${err.response?.data}');
    final code = response?.statusCode;
    final parsed = _apiError(response?.data, err.message ?? 'Unknown error');
    final message = parsed.message;

    switch (code) {
      case 400:
        handler.reject(_reject(err, BadRequestException(message)));
      case 401:
        handler.reject(_reject(err, UnauthorizedException(message)));
      case 403:
        handler.reject(_reject(err, ForbiddenException(message)));
      case 404:
        handler.reject(_reject(err, NotFoundException(message)));
      case 409:
        handler.reject(_reject(
          err,
          ConflictException(
            message,
            code: parsed.code,
            postUrl: parsed.postUrl,
            shareId: parsed.shareId,
          ),
        ));
      case 410:
        handler.reject(_reject(err, GoneException(message)));
      case 413:
        handler.reject(_reject(err, PayloadTooLargeException(message)));
      case 422:
        handler.reject(_reject(err, ValidationException(message)));
      case 429:
        handler.reject(_reject(
          err,
          RateLimitException(
            message,
            code: parsed.code,
            retryAfter: retryAfterFromHeader(
              response?.headers.value('retry-after'),
            ),
          ),
        ));
      case 500:
        handler.reject(
          _reject(err, ServerException(ServerException.readableMessage)),
        );
      case 502:
        handler.reject(_reject(err, UpstreamException(message)));
      case 503:
        handler.reject(_reject(err, ServiceUnavailableException(message)));
      case 504:
        handler.reject(_reject(err, GatewayTimeoutException(message)));
      default:
        if (err.type == DioExceptionType.connectionTimeout ||
            err.type == DioExceptionType.receiveTimeout ||
            err.type == DioExceptionType.sendTimeout) {
          handler.reject(
              _reject(err, RequestTimeoutException('Connection timed out')));
        } else if (err.type == DioExceptionType.connectionError) {
          handler
              .reject(_reject(err, NetworkException('No internet connection')));
        } else {
          handler.reject(_reject(err, ServerException(message)));
        }
    }
  }

  // ── HELPERS ──────────────────────────────────────────────────────────────────
  _ApiError _apiError(dynamic body, String fallback) {
    final decoded = _jsonBody(body);
    if (decoded is Map) {
      final raw = decoded['detail'] ?? decoded['message'] ?? decoded['error'];
      if (raw is Map) {
        final code = raw['code'] is String ? raw['code'] as String : null;
        final postUrl =
            raw['post_url'] is String ? raw['post_url'] as String : null;
        final shareId =
            raw['share_id'] is String ? raw['share_id'] as String : null;
        final message = raw['message'] is String
            ? raw['message'] as String
            : (code ?? fallback);
        return _ApiError(message,
            code: code, postUrl: postUrl, shareId: shareId);
      }
      if (raw is String) return _ApiError(raw);
      if (raw is List && raw.isNotEmpty) {
        final first = raw.first;
        if (first is Map && first['msg'] is String) {
          return _ApiError(first['msg'] as String);
        }
      }
    }
    return _ApiError(fallback);
  }

  /// Byte responses keep error JSON as bytes. Decode it before mapping.
  dynamic _jsonBody(dynamic body) {
    if (body is! List<int>) return body;
    try {
      final decoded = jsonDecode(utf8.decode(body));
      return decoded;
    } catch (_) {
      return null;
    }
  }

  DioException _reject(DioException original, Exception error) => DioException(
        requestOptions: original.requestOptions,
        response: original.response,
        type: original.type,
        error: error,
      );
}

/// `Retry-After` as delta-seconds or an HTTP date. Unknown values are ignored.
Duration? retryAfterFromHeader(String? raw, {DateTime? now}) {
  if (raw == null) return null;
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return null;
  final seconds = int.tryParse(trimmed);
  if (seconds != null) {
    if (seconds <= 0) return Duration.zero;
    return Duration(seconds: seconds);
  }
  try {
    final when = HttpDate.parse(trimmed);
    final delta = when.difference((now ?? DateTime.now()).toUtc());
    if (delta.isNegative) return Duration.zero;
    return delta;
  } catch (_) {
    return null;
  }
}

class _ApiError {
  final String message;
  final String? code;
  final String? postUrl;
  final String? shareId;

  const _ApiError(this.message, {this.code, this.postUrl, this.shareId});
}
