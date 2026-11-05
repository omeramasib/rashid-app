import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'accept_language.dart';
import 'localization_event.dart';
import 'localization_state.dart';

class LocalizationBloc extends Bloc<LocalizationEvent, LocalizationState> {
  static const String languageKey = 'selected_language';

  LocalizationBloc({SharedPreferences? preferences})
      : _preferences = preferences,
        super(LocalizationState(Locale(_initialCode(preferences)))) {
    // One bucket orders startup loading and user changes, including writes.
    on<LocalizationEvent>((event, emit) async {
      try {
        if (event is LoadLanguage) {
          await _onLoadLanguage(event, emit);
        } else if (event is ChangeLanguage) {
          await _onChangeLanguage(event, emit);
        }
      } catch (error, stackTrace) {
        if (!emit.isDone) addError(error, stackTrace);
      }
    }, transformer: (events, mapper) => events.asyncExpand(mapper));
  }

  final SharedPreferences? _preferences;

  static String _initialCode(SharedPreferences? preferences) {
    final saved = preferences?.getString(languageKey);
    if (saved == null || saved.isEmpty) return 'ar';
    return AcceptLanguage.forLanguageCode(saved);
  }

  Future<SharedPreferences> _prefs() async {
    return _preferences ?? await SharedPreferences.getInstance();
  }

  Future<void> _onLoadLanguage(
    LoadLanguage event,
    Emitter<LocalizationState> emit,
  ) async {
    final prefs = await _prefs();
    if (emit.isDone) return;
    final saved = prefs.getString(languageKey);
    final languageCode = saved == null || saved.isEmpty
        ? 'ar'
        : AcceptLanguage.forLanguageCode(saved);
    emit(LocalizationState(Locale(languageCode)));
  }

  Future<void> _onChangeLanguage(
    ChangeLanguage event,
    Emitter<LocalizationState> emit,
  ) async {
    final languageCode =
        AcceptLanguage.forLanguageCode(event.locale.languageCode);
    if (state.locale.languageCode == languageCode) return;
    final prefs = await _prefs();
    await prefs.setString(languageKey, languageCode);
    if (emit.isDone) return;
    emit(LocalizationState(Locale(languageCode)));
  }
}
