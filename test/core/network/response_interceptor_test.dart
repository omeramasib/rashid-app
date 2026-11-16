import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rashed_app/core/error/exceptions.dart';
import 'package:rashed_app/core/network/response_interceptor.dart';

void main() {
  Future<Response<dynamic>> respond(Object? body) {
    final dio = Dio();
    dio.interceptors
      ..add(ResponseInterceptor())
      ..add(InterceptorsWrapper(onRequest: (options, handler) {
        handler.resolve(
          Response(
            requestOptions: options,
            statusCode: 200,
            data: body,
          ),
          true,
        );
      }));
    return dio.get<dynamic>('/probe');
  }

  test('a success envelope with null data stays null', () async {
    final response = await respond(<String, dynamic>{
      'status': 'success',
      'message': 'No CV uploaded',
      'data': null,
    });
    expect(response.data, isNull);
  });

  test('a success envelope without data keeps the status', () async {
    final response = await respond(<String, dynamic>{
      'status': 'success',
      'message': 'Accepted',
    });
    expect(response.data, {
      'status': 'success',
      'message': 'Accepted',
    });
  });

  test('http 500 hides the server body behind a readable message', () async {
    final dio = Dio();
    dio.interceptors
      ..add(ResponseInterceptor())
      ..add(InterceptorsWrapper(onRequest: (options, handler) {
        handler.reject(
          DioException(
            requestOptions: options,
            type: DioExceptionType.badResponse,
            response: Response(
              requestOptions: options,
              statusCode: 500,
              data: const {
                'detail':
                    'Traceback (most recent call last): ValueError: secret',
              },
            ),
          ),
          true,
        );
      }));

    await expectLater(
      dio.get<dynamic>('/probe'),
      throwsA(
        isA<DioException>().having(
          (error) => error.error,
          'error',
          isA<ServerException>().having(
            (error) => error.message,
            'message',
            ServerException.readableMessage,
          ),
        ),
      ),
    );
  });

  test('http 400 still surfaces the server message', () async {
    final dio = Dio();
    dio.interceptors
      ..add(ResponseInterceptor())
      ..add(InterceptorsWrapper(onRequest: (options, handler) {
        handler.reject(
          DioException(
            requestOptions: options,
            type: DioExceptionType.badResponse,
            response: Response(
              requestOptions: options,
              statusCode: 400,
              data: const {'detail': 'job_field is too short'},
            ),
          ),
          true,
        );
      }));

    await expectLater(
      dio.get<dynamic>('/probe'),
      throwsA(
        isA<DioException>().having(
          (error) => error.error,
          'error',
          isA<BadRequestException>().having(
            (error) => error.message,
            'message',
            'job_field is too short',
          ),
        ),
      ),
    );
  });

  test('a success envelope unwraps a profile object', () async {
    final response = await respond(<String, dynamic>{
      'status': 'success',
      'data': <String, dynamic>{
        'cv_id': 'cv-1',
        'analysis_status': 'processed',
      },
    });
    expect(response.data, {
      'cv_id': 'cv-1',
      'analysis_status': 'processed',
    });
  });

  test('byte error bodies keep the 429 code and Retry-After', () async {
    final dio = Dio();
    dio.interceptors
      ..add(ResponseInterceptor())
      ..add(InterceptorsWrapper(onRequest: (options, handler) {
        handler.reject(
          DioException(
            requestOptions: options,
            type: DioExceptionType.badResponse,
            response: Response(
              requestOptions: options,
              statusCode: 429,
              data: Uint8List.fromList(utf8.encode(jsonEncode({
                'detail': {
                  'code': 'spending_limit',
                  'message': 'AI spending limit reached',
                },
              }))),
              headers: Headers.fromMap({
                'retry-after': ['8'],
              }),
            ),
          ),
          true,
        );
      }));

    await expectLater(
      dio.get<dynamic>('/probe'),
      throwsA(
        isA<DioException>().having(
          (error) => error.error,
          'error',
          isA<RateLimitException>()
              .having((error) => error.code, 'code', 'spending_limit')
              .having(
                (error) => error.message,
                'message',
                'AI spending limit reached',
              )
              .having(
                (error) => error.retryAfter,
                'retryAfter',
                const Duration(seconds: 8),
              ),
        ),
      ),
    );
  });
}
