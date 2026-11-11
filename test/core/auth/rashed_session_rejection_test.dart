import 'package:flutter_test/flutter_test.dart';
import 'package:rashed_app/core/auth/rashed_session_rejection.dart';
import 'package:rashed_app/core/network/api_endpoints.dart';

void main() {
  test('LinkedIn login and registration 401s keep the Rashed session', () {
    for (final path in [
      ApiEndpoints.loginLinkedIn,
      ApiEndpoints.registerLinkedIn,
    ]) {
      expect(
        shouldClearRashedSession(
          statusCode: 401,
          path: path,
          detail: 'Invalid LinkedIn sign-in',
        ),
        isFalse,
      );
    }
  });

  test('a Clerk 401 on account linking keeps the Rashed session', () {
    expect(
      shouldClearRashedSession(
        statusCode: 401,
        path: ApiEndpoints.linkLinkedIn,
        detail: 'Invalid LinkedIn sign-in',
      ),
      isFalse,
    );
  });

  test('a Rashed bearer challenge on account linking clears auth keys', () {
    expect(
      shouldClearRashedSession(
        statusCode: 401,
        path: ApiEndpoints.linkLinkedIn,
        wwwAuthenticate: 'Bearer',
        detail: 'Could not validate credentials',
      ),
      isTrue,
    );
    expect(
      shouldClearRashedSession(
        statusCode: 401,
        path: ApiEndpoints.linkLinkedIn,
        detail: 'Token has expired',
      ),
      isTrue,
    );
  });
}
