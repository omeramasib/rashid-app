import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:rashed_app/core/auth/clerk_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:rashed_app/app/app_routes.dart';
import 'package:rashed_app/app/root_navigator.dart';
import 'package:rashed_app/app/routes_name.dart';
import 'package:rashed_app/app_localizations.dart';
import 'package:rashed_app/core/ads/ads_bootstrap.dart';
import 'package:rashed_app/core/di/injection_container.dart' as di;
import 'package:rashed_app/core/localization/localization_bloc.dart';
import 'package:rashed_app/core/localization/localization_event.dart';
import 'package:rashed_app/core/localization/localization_state.dart';
import 'package:rashed_app/core/theme/theme.dart';
import 'package:rashed_app/features/auth/presentation/cubit/password/password_cubit.dart';
import 'package:rashed_app/features/linkedin/presentation/cubit/linkedin_share_cubit.dart';
import 'package:rashed_app/features/linkedin/presentation/linkedin_oauth_coordinator.dart';
import 'package:rashed_app/features/linkedin/presentation/linkedin_share_presenter.dart';

import 'features/auth/presentation/cubit/login/login_cubit.dart';
import 'features/auth/presentation/cubit/register/register_cubit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await di.init();
  di.sl<LocalizationBloc>().add(const LoadLanguage());
  di.sl<AdsBootstrap>().start();
  await di.sl<LinkedInOAuthCoordinator>().start();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return ClerkAuth(
      config: ClerkAuthConfig(
        publishableKey: ClerkConfig.publishableKey,
      ),
      child: MultiBlocProvider(
        providers: [
          BlocProvider.value(
            value: di.sl<LocalizationBloc>(),
          ),
          BlocProvider(
            create: (context) => di.sl<LoginCubit>(),
          ),
          BlocProvider(
            create: (context) => di.sl<RegisterCubit>(),
          ),
          BlocProvider(
            create: (context) => di.sl<PasswordCubit>(),
          ),
        ],
        child: BlocBuilder<LocalizationBloc, LocalizationState>(
          builder: (context, state) {
            return MaterialApp(
              navigatorKey: rootNavigatorKey,
              navigatorObservers: [di.sl<LinkedInShareRouteObserver>()],
              builder: (context, child) {
                return LinkedInSharePresenter(
                  observer: di.sl<LinkedInShareRouteObserver>(),
                  cubit: di.sl<LinkedInShareCubit>(),
                  child: child ?? const SizedBox.shrink(),
                );
              },
              locale: state.locale,
              onGenerateTitle: (context) =>
                  AppLocalizations.of(context)?.translate('app_name') ??
                  'Rashed',
              theme: AppTheme.lightTheme,
              debugShowCheckedModeBanner: false,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: const [
                Locale('ar'),
                Locale('en'),
              ],
              initialRoute: RoutesName.splash,
              onGenerateRoute: Routes.onGenerateRouted,
            );
          },
        ),
      ),
    );
  }
}
