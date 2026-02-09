import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:rashed_app/app/app_routes.dart';
import 'package:rashed_app/app/routes_name.dart';
import 'package:rashed_app/app_localizations.dart';
import 'package:rashed_app/core/di/injection_container.dart' as di;

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
    return MultiBlocProvider(
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
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
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
        localeResolutionCallback: (locale, supportedLocales) {
          for (var locale in supportedLocales) {
            if (locale.languageCode == locale.languageCode &&
                locale.countryCode == locale.countryCode) {
              return locale;
            }
          }
          return supportedLocales.first;
        },
        initialRoute: RoutesName.login,
        onGenerateRoute: Routes.onGenerateRouted,
        locale: const Locale('ar'),
      ),
    );
  }
}
