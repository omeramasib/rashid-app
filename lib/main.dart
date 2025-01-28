import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:rashed_app/app_localizations.dart';

import 'Presentation/Auth/login_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rashed App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
       localizationsDelegates: const[
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
            ],
      supportedLocales: const[
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
      } ,
      locale: const Locale('ar'),
      home: const LoginScreen(),
    );
  }
}
