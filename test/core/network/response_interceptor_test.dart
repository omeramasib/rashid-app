import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
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
}
