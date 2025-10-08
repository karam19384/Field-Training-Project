
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  static const _keyTheme = 'app_theme_mode';
  static const _keyLocale = 'app_locale';
  static const _keyCurrency = 'app_currency';

  SettingsCubit()
      : super(const SettingsState(
          themeMode: ThemeMode.light,
          locale: Locale('ar'),
          currency: 'شيكل إسرائيلي (₪)',
        ));

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final themeStr = prefs.getString(_keyTheme);
    final locStr = prefs.getString(_keyLocale);
    final curStr = prefs.getString(_keyCurrency);

    ThemeMode tm = ThemeMode.light;
    if (themeStr == 'dark') tm = ThemeMode.dark;
    if (themeStr == 'system') tm = ThemeMode.system;

    Locale loc;
    if (locStr == 'en') {
      loc = const Locale('en');
    } else {
      loc = const Locale('ar');
    }

    emit(state.copyWith(
      themeMode: tm,
      locale: loc,
      currency: curStr ?? state.currency,
    ));
  }

  Future<void> setDarkMode(bool enabled) async {
    final tm = enabled ? ThemeMode.dark : ThemeMode.light;
    emit(state.copyWith(themeMode: tm));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyTheme, enabled ? 'dark' : 'light');
  }

  Future<void> setLocale(Locale locale) async {
    emit(state.copyWith(locale: locale));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLocale, locale.languageCode);
  }

  Future<void> setCurrency(String code) async {
    emit(state.copyWith(currency: code));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCurrency, code);
  }
}
