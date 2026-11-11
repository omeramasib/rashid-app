import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rashed_app/app/routes_name.dart';
import 'package:rashed_app/core/di/injection_container.dart' as di;
import 'package:rashed_app/features/cv/presentation/cubit/cv_cubit.dart';
import 'package:rashed_app/features/auth/presentation/screens/reset_password_screen.dart';
import 'package:rashed_app/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:rashed_app/features/auth/presentation/screens/password_reset_success_screen.dart';

import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/register_screen.dart';
import '../features/auth/presentation/screens/otp_verification_screen.dart';
import '../features/home/presentation/screens/home_screen.dart';
import '../features/home/presentation/screens/more_screen.dart';
import '../features/items/presentation/screens/item_detail_screen.dart';
import '../features/items/presentation/screens/item_list_screen.dart';
import '../features/linkedin/presentation/screens/linkedin_share_screen.dart';
import '../features/notifications/presentation/screens/notifications_screen.dart';
import '../features/profile/presentation/screens/complete_profile_screen.dart';
import '../features/profile/presentation/screens/linkedin_import_screen.dart';
import '../features/profile/presentation/screens/profile_screen.dart';
import '../features/simulation/domain/interview_options.dart';
import '../features/simulation/presentation/cubit/interview_cubit.dart';
import '../features/simulation/presentation/cubit/speech_input_cubit.dart';
import '../features/simulation/presentation/screens/interview_evaluation_screen.dart';
import '../features/simulation/presentation/screens/interview_question_screen.dart';
import '../features/simulation/presentation/screens/interview_result_screen.dart';
import '../features/simulation/presentation/screens/interview_entry_screen.dart';
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

      case RoutesName.forgotPassword:
        {
          return CupertinoPageRoute(
            builder: (_) => ForgotPasswordScreen(
              initialEmail: routeSettings.arguments as String? ?? '',
            ),
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

      case RoutesName.resetPassword:
        {
          return CupertinoPageRoute(
            builder: (_) => const ResetPasswordScreen(),
            settings: routeSettings,
          );
        }

      case RoutesName.passwordResetSuccess:
        {
          return CupertinoPageRoute(
            builder: (_) => const PasswordResetSuccessScreen(),
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
          final resume = routeSettings.arguments is InterviewStartMode
              ? routeSettings.arguments as InterviewStartMode
              : null;
          return CupertinoPageRoute(
            builder: (_) => BlocProvider(
              create: (_) => di.sl<CvCubit>(),
              child: CompleteProfileScreen(resumeInterview: resume),
            ),
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

      case RoutesName.simulationSetup:
        {
          final mode = routeSettings.arguments is InterviewStartMode
              ? routeSettings.arguments as InterviewStartMode
              : InterviewStartMode.byJob;
          return CupertinoPageRoute(
            builder: (_) => InterviewEntryScreen(mode: mode),
            settings: routeSettings,
          );
        }

      case RoutesName.simulationQuestion:
        {
          return _interviewRoute(
            routeSettings,
            BlocProvider(
              create: (_) => di.sl<SpeechInputCubit>(),
              child: const InterviewQuestionScreen(),
            ),
          );
        }

      case RoutesName.simulationEvaluation:
        {
          return _interviewRoute(
            routeSettings,
            const InterviewEvaluationScreen(),
          );
        }

      case RoutesName.simulationResult:
        {
          final cubit = routeSettings.arguments;
          if (cubit is! InterviewCubit) {
            return CupertinoPageRoute(
              builder: (_) => const Scaffold(),
              settings: routeSettings,
            );
          }
          return CupertinoPageRoute(
            builder: (_) => BlocProvider.value(
              value: cubit,
              child: const InterviewResultScreen(),
            ),
            settings: routeSettings,
          );
        }

      case RoutesName.linkedinShare:
        {
          return CupertinoPageRoute(
            builder: (_) => const LinkedInShareScreen(),
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

  static Route<dynamic> _interviewRoute(RouteSettings settings, Widget child) {
    final cubit = settings.arguments;
    if (cubit is! InterviewCubit) {
      return CupertinoPageRoute(
        builder: (_) => const Scaffold(),
        settings: settings,
      );
    }
    return CupertinoPageRoute(
      builder: (_) => BlocProvider.value(value: cubit, child: child),
      settings: settings,
    );
  }
}
