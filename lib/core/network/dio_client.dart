import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'auth_interceptor.dart';
import 'response_interceptor.dart';
import 'api_endpoints.dart';
import '../auth/rashed_session.dart';
import '../localization/accept_language.dart';

class DioClient {
  late final Dio dio;

  DioClient({
    required RashedSession session,
    String Function()? languageCode,
  }) {
    final resolveLanguage = languageCode ?? () => 'ar';
    dio = Dio(BaseOptions(
      baseUrl: ApiEndpoints.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    dio.interceptors.addAll([
      InterceptorsWrapper(
        onRequest: (options, handler) {
          options.headers['Accept-Language'] =
              AcceptLanguage.forLanguageCode(resolveLanguage());
          handler.next(options);
        },
      ),
      AuthInterceptor(session),
      ResponseInterceptor(),
      if (kDebugMode)
        LogInterceptor(
          requestBody: false,
          responseBody: false,
          requestHeader: false,
          responseHeader: false,
          error: false,
        ),
    ]);
  }
}
