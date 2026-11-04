import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rashed_app/core/error/exceptions.dart';
import 'package:rashed_app/core/network/api_endpoints.dart';
import 'package:rashed_app/core/network/dio_client.dart';
import 'package:rashed_app/core/network/response_interceptor.dart';
import 'package:rashed_app/features/cv/data/datasources/cv_remote_datasource.dart';
import 'package:rashed_app/features/cv/data/models/cv_profile_model.dart';
import 'package:rashed_app/features/cv/domain/entities/cv_profile.dart';

class MockDioClient extends Mock implements DioClient {}

void main() {
  late Dio dio;
  late CvRemoteDataSourceImpl source;
  RequestOptions? request;

  setUp(() {
    dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
    final client = MockDioClient();
    when(() => client.dio).thenReturn(dio);
    source = CvRemoteDataSourceImpl(client: client);
    request = null;
  });

  void respond({
    int status = 200,
    Object? body,
    DioExceptionType? networkError,
  }) {
    dio.interceptors
      ..clear()
      ..add(ResponseInterceptor())
      ..add(InterceptorsWrapper(onRequest: (options, handler) {
        request = options;
        if (networkError != null) {
          handler.reject(
            DioException(requestOptions: options, type: networkError),
          );
          return;
        }
        final response = Response(
          requestOptions: options,
          statusCode: status,
          data: body,
        );
        if (status == 200) {
          handler.resolve(response);
        } else {
          handler.reject(DioException(
            requestOptions: options,
            response: response,
            type: DioExceptionType.badResponse,
          ));
        }
      }));
  }

  Map<String, dynamic> processedBody({
    String? fullName = 'Example Name',
    List<String> jobTitles = const ['Flutter Developer'],
    List<String> skills = const ['Flutter', 'Dart'],
    String status = 'processed',
  }) {
    return {
      'status': 'success',
      'message': 'CV profile retrieved successfully',
      'data': {
        'cv_id': 'cv-1',
        'analysis_status': status,
        'full_name': fullName,
        'job_titles': jobTitles,
        'skills': skills,
      },
    };
  }

  test('parses an already unwrapped processed profile', () {
    final profile = CvProfileModel.parse({
      'cv_id': 'cv-1',
      'analysis_status': 'processed',
      'full_name': 'Example Name',
      'job_titles': ['Flutter Developer'],
      'skills': ['Flutter', 'Dart'],
    });
    expect(profile?.status, CvAnalysisStatus.processed);
    expect(profile?.fullName, 'Example Name');
    expect(profile?.jobTitles, ['Flutter Developer']);
    expect(profile?.skills, ['Flutter', 'Dart']);
  });

  test('parses a still-enveloped profile and a null data envelope', () {
    final profile = CvProfileModel.parse(processedBody());
    expect(profile?.cvId, 'cv-1');
    expect(
      CvProfileModel.parse({
        'status': 'success',
        'message': 'No CV uploaded',
        'data': null,
      }),
      isNull,
    );
    expect(CvProfileModel.parse(null), isNull);
  });

  test('keeps a null name and empty lists', () {
    final profile = CvProfileModel.parse({
      'cv_id': 'cv-1',
      'analysis_status': 'processed',
      'full_name': null,
      'job_titles': <String>[],
      'skills': <String>[],
    });
    expect(profile?.fullName, isNull);
    expect(profile?.jobTitles, isEmpty);
    expect(profile?.skills, isEmpty);
  });

  test('rejects completed and other unknown statuses', () {
    expect(
      () => CvProfileModel.parse({
        'cv_id': 'cv-1',
        'analysis_status': 'completed',
      }),
      throwsA(isA<ServerException>()),
    );
  });

  test('GET /cv/me unwraps a processed envelope', () async {
    respond(body: processedBody());
    final profile = await source.getMyCvProfile();
    expect(request?.method, 'GET');
    expect(request?.path, ApiEndpoints.cvMe);
    expect(profile?.cvId, 'cv-1');
    expect(profile?.status, CvAnalysisStatus.processed);
    expect(profile?.fullName, 'Example Name');
    expect(profile?.skills, ['Flutter', 'Dart']);
  });

  test('a null data envelope is no CV after the response interceptor',
      () async {
    respond(body: const {
      'status': 'success',
      'message': 'No CV uploaded',
      'data': null,
    });
    expect(await source.getMyCvProfile(), isNull);
  });

  test('pending, in progress, and failed statuses are preserved', () async {
    for (final entry in {
      'pending': CvAnalysisStatus.pending,
      'in_progress': CvAnalysisStatus.inProgress,
      'failed': CvAnalysisStatus.failed,
    }.entries) {
      respond(body: processedBody(status: entry.key, fullName: null));
      final profile = await source.getMyCvProfile();
      expect(profile?.status, entry.value);
    }
  });

  test('401, timeout, and connection loss are not an empty profile', () async {
    Future<void> expectFailure(
      Future<ResponseBody> Function(RequestOptions options) fetch,
      Matcher matcher,
    ) async {
      dio.interceptors
        ..clear()
        ..add(ResponseInterceptor());
      dio.httpClientAdapter = _ScriptedAdapter(fetch);
      await expectLater(source.getMyCvProfile(), throwsA(matcher));
    }

    await expectFailure(
      (options) async => ResponseBody.fromString(
        jsonEncode({'detail': 'Unauthorized'}),
        401,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      ),
      isA<UnauthorizedException>(),
    );
    await expectFailure(
      (options) => Future<ResponseBody>.error(DioException(
        requestOptions: options,
        type: DioExceptionType.connectionTimeout,
      )),
      isA<RequestTimeoutException>(),
    );
    await expectFailure(
      (options) => Future<ResponseBody>.error(DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
      )),
      isA<NetworkException>(),
    );
  });

  test('PUT update-skills sends the complete skills list', () async {
    respond(body: const {
      'status': 'success',
      'message': 'Skills updated',
      'data': null,
    });
    await source.updateSkills(const ['Flutter', 'Dart', 'Firebase']);
    expect(request?.method, 'PUT');
    expect(request?.path, ApiEndpoints.cvUpdateSkills);
    expect(request?.data, {
      'skills': ['Flutter', 'Dart', 'Firebase'],
    });
  });

  test('an invalid body is rejected', () async {
    respond(body: const {
      'status': 'success',
      'data': {
        'cv_id': 'cv-1',
        'analysis_status': 'processed',
        'skills': [1]
      },
    });
    expect(source.getMyCvProfile(), throwsA(isA<ServerException>()));
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
