import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/gym_service.dart';

const _localeKey = 'tapem_locale_v1';

/// Persists and exposes the active app locale.
/// Default: German (de). Stored in SharedPreferences.
final localeNotifierProvider = StateNotifierProvider<LocaleNotifier, Locale>((
  ref,
) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return LocaleNotifier(prefs);
});

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier(this._prefs) : super(_load(_prefs));

  final SharedPreferences _prefs;

  static Locale _load(SharedPreferences prefs) {
    final code = prefs.getString(_localeKey);
    if (code == 'en') return const Locale('en');
    return const Locale('de'); // default
  }

  Future<void> setLocale(Locale locale) async {
    state = locale;
    await _prefs.setString(_localeKey, locale.languageCode);
  }
}
