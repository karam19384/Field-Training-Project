
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class SettingsState extends Equatable {
  final ThemeMode themeMode;
  final Locale locale;
  final String currency;

  const SettingsState({
    required this.themeMode,
    required this.locale,
    required this.currency,
  });

  SettingsState copyWith({
    ThemeMode? themeMode,
    Locale? locale,
    String? currency,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      locale: locale ?? this.locale,
      currency: currency ?? this.currency,
    );
  }

  @override
  List<Object?> get props => [themeMode, locale, currency];
}
