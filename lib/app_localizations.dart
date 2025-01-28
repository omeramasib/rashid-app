import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppLocalizations {
  final Locale? locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      AppLocalizationsDelegate();

  late Map<String, String> _localizedString;

  Future<bool> loadJsonLanguage() async {
    final jsonString = await rootBundle.loadString(
      'assets/lang/${locale!.languageCode}.json',
    );
    Map<String, dynamic> jsonMap = json.decode(jsonString);
    _localizedString =
        jsonMap.map((key, value) {
          return MapEntry(key, value.toString());
        });
    return true;
  }

  String translate(String key) {
    return _localizedString[key] ?? "";
  }
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'ar'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    AppLocalizations localizations = AppLocalizations(locale);
    await localizations.loadJsonLanguage();
    return localizations;
  }

  @override bool shouldReload(AppLocalizationsDelegate old) => false;
}