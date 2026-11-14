import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rashed_app/core/error/exceptions.dart';
import 'package:rashed_app/core/network/api_endpoints.dart';
import 'package:rashed_app/core/network/dio_client.dart';
import 'package:rashed_app/core/network/response_interceptor.dart';
import 'package:rashed_app/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:rashed_app/features/auth/domain/linkedin_auth_conflicts.dart';

class MockDioClient extends Mock implements DioClient {}

void main() {
  late Dio dio;
  late AuthRemoteDataSourceImpl source;
  final requests = <RequestOptions>[];

  setUp(() {
    dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
    final client = MockDioClient();
    when(() => client.dio).thenReturn(dio);
    source = AuthRemoteDataSourceImpl(client: client);
    requests.clear();
  });

  void respond({required int status, required Object body}) {
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

  test('register linkedin 409 preserves the email conflict detail', () async {
    respond(
      status: 409,
      body: {'detail': LinkedInAuthConflicts.emailAccountExists},
    );

    await expectLater(
      source.registerWithLinkedIn('clerk-session'),
      throwsA(
        isA<ConflictException>()
            .having(
              (error) => error.message,
              'message',
              LinkedInAuthConflicts.emailAccountExists,
            )
            .having(
              (error) => error.toString(),
              'toString',
              LinkedInAuthConflicts.emailAccountExists,
            ),
      ),
    );

    expect(requests.single.method, 'POST');
    expect(requests.single.path, ApiEndpoints.registerLinkedIn);
    expect(requests.single.data, {'clerk_session_jwt': 'clerk-session'});
  });

  test('link linkedin 409 preserves the identity conflict detail', () async {
    respond(
      status: 409,
      body: {'detail': LinkedInAuthConflicts.identityConflict},
    );

    await expectLater(
      source.linkLinkedIn(
        clerkSessionJwt: 'clerk-session',
        currentPassword: 'current-password',
      ),
      throwsA(
        isA<ConflictException>().having(
          (error) => error.message,
          'message',
          LinkedInAuthConflicts.identityConflict,
        ),
      ),
    );

    final body = requests.single.data as Map;
    expect(requests.single.method, 'POST');
    expect(requests.single.path, ApiEndpoints.linkLinkedIn);
    expect(body['clerk_session_jwt'], 'clerk-session');
    expect(body['current_password'], 'current-password');
    expect(body.containsKey('email'), isFalse);
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
