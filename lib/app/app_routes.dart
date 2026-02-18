import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:rashed_app/app/routes_name.dart';

import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/register_screen.dart';
import '../features/auth/presentation/screens/otp_verification_screen.dart';
import '../features/home/presentation/screens/home_screen.dart';
import '../features/home/presentation/screens/more_screen.dart';
import '../features/items/presentation/screens/item_detail_screen.dart';
import '../features/items/presentation/screens/item_list_screen.dart';
import '../features/notifications/presentation/screens/notifications_screen.dart';
import '../features/profile/presentation/screens/complete_profile_screen.dart';
import '../features/profile/presentation/screens/linkedin_import_screen.dart';
import '../features/profile/presentation/screens/profile_screen.dart';
import '../features/simulation/presentation/screens/interview_evaluation_screen.dart';
import '../features/simulation/presentation/screens/interview_question_screen.dart';
import '../features/simulation/presentation/screens/interview_result_screen.dart';
import '../features/splash/presentation/screens/splash_screen.dart';

class Routes {
  static String currentRoute = RoutesName.splash;

  static Route<dynamic> onGenerateRouted(RouteSettings routeSettings) {
    currentRoute = routeSettings.name ?? "";
    if (kDebugMode) {
      print("Route: $currentRoute");
    }
    switch (routeSettings.name) {
      case RoutesName.splash:
        {
          return CupertinoPageRoute(
            builder: (_) => const SplashScreen(),
            settings: routeSettings,
          );
        }

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

      case RoutesName.otpVerification:
        {
          return CupertinoPageRoute(
            builder: (_) => const OTPVerificationScreen(),
            settings: routeSettings,
          );
        }

      case RoutesName.profile:
        {
          return CupertinoPageRoute(
            builder: (_) => const ProfileScreen(),
            settings: routeSettings,
          );
        }

      case RoutesName.completeProfile:
        {
          return CupertinoPageRoute(
            builder: (_) => const CompleteProfileScreen(),
            settings: routeSettings,
          );
        }

      case RoutesName.linkedinImport:
        {
          return CupertinoPageRoute(
            builder: (_) => const LinkedinImportScreen(),
            settings: routeSettings,
          );
        }

      case RoutesName.simulationQuestion:
        {
          final simulationType = routeSettings.arguments as String?;
          return CupertinoPageRoute(
            builder: (_) =>
                InterviewQuestionScreen(simulationType: simulationType),
            settings: routeSettings,
          );
        }

      case RoutesName.simulationEvaluation:
        {
          return CupertinoPageRoute(
            builder: (_) => const InterviewEvaluationScreen(),
            settings: routeSettings,
          );
        }

      case RoutesName.simulationResult:
        {
          return CupertinoPageRoute(
            builder: (_) => const InterviewResultScreen(),
            settings: routeSettings,
          );
        }

      case RoutesName.items:
        {
          return CupertinoPageRoute(
            builder: (_) => const ItemListScreen(),
            settings: routeSettings,
          );
        }

      case RoutesName.itemDetail:
        {
          return CupertinoPageRoute(
            builder: (_) => const ItemDetailScreen(),
            settings: routeSettings,
          );
        }

      case RoutesName.notifications:
        {
          return CupertinoPageRoute(
            builder: (_) => const NotificationsScreen(),
            settings: routeSettings,
          );
        }

      case RoutesName.moreTab:
        {
          return CupertinoPageRoute(
            builder: (_) => const MoreScreen(),
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
