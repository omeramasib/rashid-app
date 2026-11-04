import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rashed_app/core/localization/accept_language.dart';
import 'package:rashed_app/core/localization/localization_bloc.dart';
import 'package:rashed_app/core/localization/localization_event.dart';
import 'package:rashed_app/core/localization/localization_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  test('defaults to Arabic when nothing is saved', () {
    final bloc = LocalizationBloc(preferences: prefs);
    expect(bloc.state.locale.languageCode, 'ar');
    return bloc.close();
  });

  test('loads a language saved after startup', () async {
    final bloc = LocalizationBloc(preferences: prefs);
    await prefs.setString(LocalizationBloc.languageKey, 'en');
    bloc.add(const LoadLanguage());
    await bloc.stream.first;
    expect(bloc.state.locale, const Locale('en'));
    await bloc.close();
  });

  blocTest<LocalizationBloc, LocalizationState>(
    'saves the latest language change',
    build: () => LocalizationBloc(preferences: prefs),
    act: (bloc) => bloc.add(const ChangeLanguage(Locale('en', 'US'))),
    expect: () => const [LocalizationState(Locale('en'))],
    verify: (bloc) {
      expect(prefs.getString(LocalizationBloc.languageKey), 'en');
      expect(bloc.state.locale.languageCode, 'en');
    },
  );

  blocTest<LocalizationBloc, LocalizationState>(
    'ignores a change to the current language',
    build: () => LocalizationBloc(preferences: prefs),
    act: (bloc) => bloc.add(const ChangeLanguage(Locale('ar'))),
    expect: () => const <LocalizationState>[],
  );

  test('maps locale codes to Accept-Language', () {
    expect(AcceptLanguage.forLanguageCode('ar'), 'ar');
    expect(AcceptLanguage.forLanguageCode('en'), 'en');
    expect(AcceptLanguage.forLanguageCode('fr'), 'en');
  });
}
