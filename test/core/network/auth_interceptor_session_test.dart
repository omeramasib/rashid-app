import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rashed_app/core/auth/rashed_session.dart';
import 'package:rashed_app/core/network/api_endpoints.dart';
import 'package:rashed_app/core/network/auth_interceptor.dart';
import 'package:rashed_app/core/storage/secure_storage_service.dart';

class MockStorage extends Mock implements SecureStorageService {}

void main() {
  late MockStorage storage;
  late Dio dio;

  setUp(() {
    storage = MockStorage();
    when(() => storage.read(key: any(named: 'key'))).thenAnswer((_) async => null);
    when(() => storage.delete(key: any(named: 'key'))).thenAnswer((_) async {});
    when(() => storage.deleteAll()).thenAnswer((_) async {});
    dio = Dio();
    dio.interceptors.add(AuthInterceptor(RashedSession(storage)));
  });

  void reject(String path, {String? detail, String? wwwAuthenticate}) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.reject(
            DioException(
              requestOptions: options,
              type: DioExceptionType.badResponse,
              response: Response(
                requestOptions: options,
                statusCode: 401,
                data: {'detail': detail},
                headers: Headers.fromMap({
                  if (wwwAuthenticate != null)
                    'www-authenticate': [wwwAuthenticate],
                }),
              ),
            ),
            true,
          );
        },
      ),
    );
  }

  test('LinkedIn login and registration 401s do not clear the session',
      () async {
    for (final path in [
      ApiEndpoints.loginLinkedIn,
      ApiEndpoints.registerLinkedIn,
    ]) {
      reject(path, detail: 'Invalid LinkedIn sign-in');
      await expectLater(dio.post(path), throwsA(isA<DioException>()));
      dio.interceptors.removeLast();
    }
    verifyNever(() => storage.delete(key: any(named: 'key')));
    verifyNever(() => storage.deleteAll());
  });

  test('a Clerk 401 while linking keeps the Rashed token', () async {
    reject(ApiEndpoints.linkLinkedIn, detail: 'Invalid LinkedIn sign-in');
    await expectLater(
      dio.post(ApiEndpoints.linkLinkedIn),
      throwsA(isA<DioException>()),
    );
    verifyNever(() => storage.delete(key: any(named: 'key')));
    verifyNever(() => storage.deleteAll());
  });

  test('a Rashed bearer 401 clears only the authentication keys', () async {
    reject(
      ApiEndpoints.linkLinkedIn,
      detail: 'Token has expired',
      wwwAuthenticate: 'Bearer',
    );
    await expectLater(
      dio.post(ApiEndpoints.linkLinkedIn),
      throwsA(isA<DioException>()),
    );
    verify(() => storage.delete(key: RashedSession.tokenKey)).called(1);
    verify(() => storage.delete(key: RashedSession.userIdKey)).called(1);
    verify(() => storage.delete(key: RashedSession.emailKey)).called(1);
    verifyNever(() => storage.deleteAll());
  });
}
