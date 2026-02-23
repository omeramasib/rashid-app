import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'auth_interceptor.dart';
import 'response_interceptor.dart';
import 'api_endpoints.dart';
import '../storage/secure_storage_service.dart';

class DioClient {
  late final Dio dio;

  DioClient({required SecureStorageService storage}) {
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
      AuthInterceptor(storage),
      ResponseInterceptor(),
      if (kDebugMode)
        LogInterceptor(
          requestBody: true,
          responseBody: true,
        ),
    ]);
  }
}
