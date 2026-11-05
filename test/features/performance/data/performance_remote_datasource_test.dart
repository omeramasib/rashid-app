import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rashed_app/core/error/exceptions.dart';
import 'package:rashed_app/core/network/api_endpoints.dart';
import 'package:rashed_app/core/network/dio_client.dart';
import 'package:rashed_app/core/network/response_interceptor.dart';
import 'package:rashed_app/features/performance/data/datasources/performance_remote_datasource.dart';
import 'package:rashed_app/features/performance/domain/entities/performance_summary.dart';

class MockDioClient extends Mock implements DioClient {}

void main() {
  late Dio dio;
  late PerformanceRemoteDataSourceImpl source;
  RequestOptions? request;

  setUp(() {
    dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
    final client = MockDioClient();
    when(() => client.dio).thenReturn(dio);
    source = PerformanceRemoteDataSourceImpl(client: client);
    request = null;
  });

  void respond({
    int status = 200,
    Object? body,
    DioExceptionType? networkError,
  }) {
    dio.interceptors
      ..clear()
      ..add(ResponseInterceptor());
    dio.httpClientAdapter = _ScriptedAdapter((options) {
      request = options;
      if (networkError != null) {
        return Future<ResponseBody>.error(DioException(
          requestOptions: options,
          type: networkError,
        ));
      }
      return Future.value(ResponseBody.fromString(
        jsonEncode(body),
        status,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      ));
    });
  }

  test('unwraps the success envelope', () async {
    respond(body: {
      'status': 'success',
      'message': 'Performance summary retrieved successfully',
      'data': {
        'total_simulations': 3,
        'average_score': 72,
        'best_score': 85,
        'recent_interviews': [
          {
            'simulation_id': 'sim-1',
            'job_field': 'برمجة',
            'completed_at': '2026-11-05T08:30:00',
            'score': 85,
            'performance_status': 'excellent',
          },
        ],
      },
    });

    final summary = await source.getSummary();

    expect(request?.method, 'GET');
    expect(request?.path, ApiEndpoints.interviewPerformanceSummary);
    expect(summary.totalSimulations, 3);
    expect(summary.averageScore, 72);
    expect(summary.bestScore, 85);
    expect(summary.recentInterviews.single.simulationId, 'sim-1');
    expect(
      summary.recentInterviews.single.performanceStatus,
      PerformanceStatus.excellent,
    );
    expect(
      summary.recentInterviews.single.completedAt,
      DateTime.utc(2026, 11, 5, 8, 30),
    );
  });

  test('an unauthorized response stays unauthorized', () async {
    respond(status: 401, body: {'detail': 'Unauthorized'});

    expect(source.getSummary(), throwsA(isA<UnauthorizedException>()));
  });

  test('a connection error stays a network exception', () async {
    respond(networkError: DioExceptionType.connectionError);

    expect(source.getSummary(), throwsA(isA<NetworkException>()));
  });
}

class _ScriptedAdapter implements HttpClientAdapter {
  _ScriptedAdapter(this._fetch);

  final Future<ResponseBody> Function(RequestOptions options) _fetch;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    return _fetch(options);
  }
}
