import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rashed_app/core/error/exceptions.dart';
import 'package:rashed_app/core/network/api_endpoints.dart';
import 'package:rashed_app/core/network/dio_client.dart';
import 'package:rashed_app/core/network/response_interceptor.dart';
import 'package:rashed_app/features/linkedin/data/datasources/linkedin_remote_datasource.dart';

class MockDioClient extends Mock implements DioClient {}

void main() {
  late Dio dio;
  late LinkedInRemoteDataSourceImpl source;
  final requests = <RequestOptions>[];

  setUp(() {
    dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
    final client = MockDioClient();
    when(() => client.dio).thenReturn(dio);
    source = LinkedInRemoteDataSourceImpl(client: client);
    requests.clear();
  });

  void respond({
    int status = 200,
    Object? body,
  }) {
    dio.interceptors
      ..clear()
      ..add(ResponseInterceptor());
    dio.httpClientAdapter = _ScriptedAdapter((options) {
      requests.add(options);
      return Future.value(ResponseBody.fromString(
        jsonEncode(body),
        status,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      ));
    });
  }

  test('status unwraps the publishing connection', () async {
    respond(body: {
      'status': 'success',
      'message': 'LinkedIn status retrieved',
      'data': {
        'connected': true,
        'publishing_enabled': true,
        'reauthorization_required': false,
        'connection_status': 'active',
        'expires_at': '2026-12-31T00:00:00',
        'name': 'Display name',
      },
    });

    final status = await source.getStatus();

    expect(requests.single.method, 'GET');
    expect(requests.single.path, ApiEndpoints.linkedInStatus);
    expect(status.canPublish, isTrue);
    expect(status.name, 'Display name');
  });

  test('oauth start reads an unwrapped authorization url', () async {
    respond(body: {
      'authorization_url':
          'https://www.linkedin.com/oauth/v2/authorization?x=1',
      'expires_at': '2026-12-31T00:00:00',
    });

    final start = await source.startOAuth('sim-1');

    expect(requests.single.method, 'POST');
    expect(requests.single.path, ApiEndpoints.linkedInOAuthStart);
    expect(requests.single.data, {'simulation_id': 'sim-1'});
    expect(start.authorizationUrl, contains('linkedin.com'));
  });

  test('preview keeps the server text and hash', () async {
    respond(body: {
      'status': 'success',
      'data': {
        'preview_id': 'preview-1',
        'simulation_id': 'sim-1',
        'text': 'Exact server text',
        'content_sha256': 'hash-1',
      },
    });

    final preview = await source.previewShare('sim-1');

    expect(requests.single.path, ApiEndpoints.linkedInSharePreview);
    expect(preview.text, 'Exact server text');
    expect(preview.contentSha256, 'hash-1');
  });

  test('publish confirms the unchanged preview', () async {
    respond(body: {
      'status': 'success',
      'data': {
        'post_url': 'https://www.linkedin.com/feed/update/1',
      },
    });

    final result = await source.publish(
      previewId: 'preview-1',
      simulationId: 'sim-1',
      contentSha256: 'hash-1',
    );

    expect(requests.single.path, ApiEndpoints.linkedInPublish);
    expect(requests.single.data, {
      'preview_id': 'preview-1',
      'simulation_id': 'sim-1',
      'content_sha256': 'hash-1',
      'confirmed': true,
    });
    expect(result.postUrl, 'https://www.linkedin.com/feed/update/1');
  });

  test('publish allows a missing post url', () async {
    respond(body: {'status': 'success', 'data': <String, dynamic>{}});

    final result = await source.publish(
      previewId: 'preview-1',
      simulationId: 'sim-1',
      contentSha256: 'hash-1',
    );

    expect(result.postUrl, isNull);
  });

  test('forbidden, conflict, upstream, and unavailable stay typed', () async {
    respond(status: 403, body: {'detail': 'publishing required'});
    await expectLater(source.getStatus(), throwsA(isA<ForbiddenException>()));

    respond(status: 409, body: {'detail': 'preview expired'});
    await expectLater(
      source.previewShare('sim-1'),
      throwsA(isA<ConflictException>()),
    );

    respond(status: 502, body: {'detail': 'not confirmed'});
    await expectLater(
      source.publish(
        previewId: 'preview-1',
        simulationId: 'sim-1',
        contentSha256: 'hash-1',
      ),
      throwsA(isA<UpstreamException>()),
    );

    respond(status: 503, body: {'detail': 'unavailable'});
    await expectLater(
      source.getStatus(),
      throwsA(isA<ServiceUnavailableException>()),
    );

    respond(status: 410, body: {'detail': 'gone'});
    await expectLater(source.disconnect(), throwsA(isA<GoneException>()));
  });

  test('the client never requests the oauth callback', () async {
    respond(body: {
      'connected': false,
      'publishing_enabled': false,
      'reauthorization_required': false,
      'connection_status': 'not_connected',
    });
    await source.getStatus();
    expect(
      requests.every((request) => !request.path.contains('oauth/callback')),
      isTrue,
    );
    expect(
      requests.every((request) => request.path != '/api/v1/linkedin/connect'),
      isTrue,
    );
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
