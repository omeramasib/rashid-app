import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:rashed_app/app/routes_name.dart';

import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/register_screen.dart';
import '../features/home/presentation/screens/home_screen.dart';

class Routes {
  static String currentRoute = RoutesName.splash;

  static Route<dynamic> onGenerateRouted(RouteSettings routeSettings) {
    currentRoute = routeSettings.name ?? "";
    if (kDebugMode) {
      print("Route: $currentRoute");
    }
    switch (routeSettings.name) {
      // Auth Screens Routes
      // case RoutesName.splash:

      case RoutesName.home:
        {
          return CupertinoPageRoute(
            builder: (_) => const HomeScreen(),
            settings: routeSettings,
          );
        }

      case RoutesName.login:
        {
          return CupertinoPageRoute(
            builder: (_) => const LoginScreen(),
            settings: routeSettings,
          );
        }

      case RoutesName.register:
        {
          return CupertinoPageRoute(
            builder: (_) => const RegisterScreen(),
            settings: routeSettings,
          );
        }

      default:
        {
          return CupertinoPageRoute(builder: (context) => const Scaffold());
        }
    }
  }
}
