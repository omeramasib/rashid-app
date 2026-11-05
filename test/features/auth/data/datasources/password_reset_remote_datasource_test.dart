import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rashed_app/core/error/exceptions.dart';
import 'package:rashed_app/core/error/password_reset_problem.dart';
import 'package:rashed_app/core/network/api_endpoints.dart';
import 'package:rashed_app/core/network/auth_interceptor.dart';
import 'package:rashed_app/core/network/dio_client.dart';
import 'package:rashed_app/core/storage/secure_storage_service.dart';
import 'package:rashed_app/features/auth/data/datasources/auth_remote_datasource.dart';

class MockDioClient extends Mock implements DioClient {}

class MockStorage extends Mock implements SecureStorageService {}

void main() {
  late Dio dio;
  late MockDioClient client;
  late AuthRemoteDataSourceImpl source;
  RequestOptions? request;

  setUp(() {
    dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
    client = MockDioClient();
    when(() => client.dio).thenReturn(dio);
    source = AuthRemoteDataSourceImpl(client: client);
    request = null;
  });

  void respond({
    int status = 200,
    Object? body = const {'status': 'success', 'message': 'Accepted'},
    DioExceptionType? networkError,
  }) {
    dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
      request = options;
      if (networkError != null) {
        handler
            .reject(DioException(requestOptions: options, type: networkError));
      } else if (status == 200) {
        handler.resolve(
            Response(requestOptions: options, statusCode: status, data: body));
      } else {
        handler.reject(DioException(
          requestOptions: options,
          response:
              Response(requestOptions: options, statusCode: status, data: body),
          type: DioExceptionType.badResponse,
        ));
      }
    }));
  }

  test('forgot and resend use the public endpoints and trimmed email payload',
      () async {
    respond();
    await source.forgotPassword('user@example.com');
    expect(request!.path, ApiEndpoints.forgotPassword);
    expect(request!.data, {'email': 'user@example.com'});
    await source.resendOtp('user@example.com');
    expect(request!.path, ApiEndpoints.resendOtp);
    expect(request!.data, {'email': 'user@example.com'});
  });

  test('reset sends all four exact strings, including leading zero', () async {
    respond(body: const {
      'status': 'success',
      'message': 'Password reset successfully',
    });
    await source.resetPassword(
      email: 'user@example.com',
      otp: '012345',
      newPassword: ' password123 ',
      confirmPassword: ' password123 ',
    );
    expect(request!.path, ApiEndpoints.resetPassword);
    expect(request!.data, {
      'email': 'user@example.com',
      'otp': '012345',
      'new_password': ' password123 ',
      'confirm_password': ' password123 ',
    });
  });

  test('a non-success body is not treated as acceptance', () async {
    respond(body: const {'status': 'error', 'message': 'No'});
    expect(
      () => source.forgotPassword('user@example.com'),
      throwsA(isA<PasswordResetApiException>()),
    );
  });

  for (final scenario in [
    (
      'Password confirmation does not match',
      PasswordResetProblem.confirmationMismatch
    ),
    ('Invalid reset code', PasswordResetProblem.invalidOtp),
    ('Invalid or expired reset code', PasswordResetProblem.expiredOtp),
  ]) {
    test('400 maps ${scenario.$1}', () async {
      respond(status: 400, body: {'detail': scenario.$1});
      await expectLater(
        source.resetPassword(
          email: 'user@example.com',
          otp: '012345',
          newPassword: 'password123',
          confirmPassword: 'password123',
        ),
        throwsA(isA<PasswordResetApiException>()
            .having((e) => e.problem, 'problem', scenario.$2)),
      );
    });
  }

  test('422 maps FastAPI validation locations without showing raw details',
      () async {
    respond(status: 422, body: const {
      'detail': [
        {
          'loc': ['body', 'email'],
          'msg': 'Sensitive backend detail'
        },
        {
          'loc': ['body', 'otp'],
          'msg': 'Another backend detail'
        },
      ]
    });
    await expectLater(
      source.resetPassword(
        email: 'user@example.com',
        otp: '012345',
        newPassword: 'password123',
        confirmPassword: 'password123',
      ),
      throwsA(isA<PasswordResetApiException>()
          .having((e) => e.problem, 'problem', PasswordResetProblem.validation)
          .having((e) => e.fields, 'fields', {'email', 'otp'})),
    );
  });

  test('empty 422 details and 500 are safe', () async {
    respond(status: 422, body: const {'detail': []});
    await expectLater(source.forgotPassword('user@example.com'),
        throwsA(isA<PasswordResetApiException>()));
    dio.interceptors.clear();
    respond(status: 500, body: const {'detail': 'Failed to reset password'});
    await expectLater(
      source.forgotPassword('user@example.com'),
      throwsA(isA<PasswordResetApiException>()
          .having((e) => e.problem, 'problem', PasswordResetProblem.server)),
    );
  });

  for (final scenario in [
    (DioExceptionType.connectionTimeout, PasswordResetProblem.timeout),
    (DioExceptionType.connectionError, PasswordResetProblem.offline),
  ]) {
    test('maps network error ${scenario.$1}', () async {
      respond(networkError: scenario.$1);
      await expectLater(
        source.resendOtp('user@example.com'),
        throwsA(isA<PasswordResetApiException>()
            .having((e) => e.problem, 'problem', scenario.$2)),
      );
    });
  }

  test('password requests discard stale Authorization credentials', () async {
    final storage = MockStorage();
    dio.interceptors.add(AuthInterceptor(storage));
    respond();
    await dio.post(ApiEndpoints.resetPassword,
        options: Options(headers: {'Authorization': 'Bearer stale'}),
        data: const {});
    expect(request!.headers.containsKey('Authorization'), isFalse);
    verifyNever(() => storage.read(key: 'token'));
  });

  test('public endpoint 401 does not clear an existing session', () async {
    final storage = MockStorage();
    dio.interceptors.add(AuthInterceptor(storage));
    respond(status: 401, body: const {'detail': 'Unauthenticated'});
    await expectLater(dio.post(ApiEndpoints.forgotPassword, data: const {}),
        throwsA(isA<DioException>()));
    verifyNever(() => storage.deleteAll());
  });

  test('authenticated requests use the token key written by login', () async {
    final storage = MockStorage();
    when(() => storage.read(key: 'token'))
        .thenAnswer((_) async => 'saved-token');
    dio.interceptors.add(AuthInterceptor(storage));
    respond();
    await dio.get(ApiEndpoints.currentUser);
    expect(request!.headers['Authorization'], 'Bearer saved-token');
  });
}
