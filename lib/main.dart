import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:rashed_app/core/auth/clerk_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:rashed_app/app/app_routes.dart';
import 'package:rashed_app/app/routes_name.dart';
import 'package:rashed_app/app_localizations.dart';
import 'package:rashed_app/core/di/injection_container.dart' as di;
import 'package:rashed_app/core/theme/theme.dart';

import 'features/auth/presentation/cubit/login/login_cubit.dart';
import 'features/auth/presentation/cubit/register/register_cubit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await di.init(); // Initialize Dependency Injection
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
          BlocProvider(
            create: (context) => di.sl<LoginCubit>(),
          ),
          BlocProvider(
            create: (context) => di.sl<RegisterCubit>(),
          ),
        ],
        child: MaterialApp(
          title: 'Rashed App',
          theme: AppTheme.lightTheme,
          debugShowCheckedModeBanner: false,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('ar', 'SA'),
            Locale('en', 'US'),
          ],
          localeResolutionCallback: (deviceLocale, supportedLocales) {
            for (final supportedLocale in supportedLocales) {
              if (supportedLocale.languageCode == deviceLocale?.languageCode &&
                  supportedLocale.countryCode == deviceLocale?.countryCode) {
                return supportedLocale;
              }
            }
            return supportedLocales.first;
          },
          initialRoute: RoutesName.splash,
          onGenerateRoute: Routes.onGenerateRouted,
          locale: const Locale('ar'),
        ),
      ),
    );
  }
}
