import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rashed_app/app/app_routes.dart';
import 'package:rashed_app/app/routes_name.dart';

void main() {
  test('password recovery routes are registered', () {
    for (final name in [
      RoutesName.forgotPassword,
      RoutesName.otpVerification,
      RoutesName.resetPassword,
      RoutesName.passwordResetSuccess,
    ]) {
      final route = Routes.onGenerateRouted(RouteSettings(name: name));
      expect(route, isA<CupertinoPageRoute<dynamic>>());
      expect(route.settings.name, name);
    }
  });
}
