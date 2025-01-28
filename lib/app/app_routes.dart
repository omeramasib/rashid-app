import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:rashed_app/app/routes_name.dart';

import '../Presentation/Auth/login_screen.dart';

class Routes {
  static String currentRoute = RoutesName.splash;

  static Route<dynamic> onGenerateRouted(RouteSettings routeSettings) {
    currentRoute = routeSettings.name ?? "";
    if (kDebugMode) {
      print("Route: $currentRoute");
    }
    switch (routeSettings.name) {
      // Auth Screens Routes
      case RoutesName.splash:
        // {
        //   return SplashScreen.route(routeSettings);
        // }
      case RoutesName.login:
        {
          return LoginScreen.route(routeSettings);
        }
      default:
        {
          return CupertinoPageRoute(builder: (context) => const Scaffold());
        }
    }
  }
}