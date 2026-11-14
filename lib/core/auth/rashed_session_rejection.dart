import '../network/api_endpoints.dart';

/// Rashed bearer failures already returned by the API. Clerk body failures
/// are not in this set, so a LinkedIn sign-in rejection does not match it.
const rashedBearerDetails = {
  'Could not validate credentials',
  'Token has expired',
  'Invalid token',
};

/// Whether an HTTP 401 should end the Rashed session.
///
/// LinkedIn login and registration authenticate the Clerk JWT in the body.
/// Their 401 does not describe the stored Rashed bearer. Account linking
/// can reject either credential: the Rashed bearer is identified by the
/// `WWW-Authenticate: Bearer` challenge or by [rashedBearerDetails].
bool shouldClearRashedSession({
  required int? statusCode,
  required String path,
  String? wwwAuthenticate,
  String? detail,
}) {
  if (statusCode != 401) return false;
  if (path == ApiEndpoints.forgotPassword ||
      path == ApiEndpoints.resendOtp ||
      path == ApiEndpoints.resetPassword ||
      path == ApiEndpoints.loginLinkedIn ||
      path == ApiEndpoints.registerLinkedIn) {
    return false;
  }
  if (path == ApiEndpoints.linkLinkedIn) {
    return _rashedBearerRejected(
      wwwAuthenticate: wwwAuthenticate,
      detail: detail,
    );
  }
  return true;
}

bool _rashedBearerRejected({
  String? wwwAuthenticate,
  String? detail,
}) {
  final challenge = wwwAuthenticate?.toLowerCase() ?? '';
  if (challenge.contains('bearer')) return true;
  return detail != null && rashedBearerDetails.contains(detail);
}

String? responseDetail(Object? body) {
  if (body is Map) {
    final detail = body['detail'];
    if (detail is String) return detail;
  }
  return null;
}
