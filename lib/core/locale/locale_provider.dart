import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App locale (UI + default for AI output). Stored as BCP-47 language code: en, zh.
class LocaleNotifier extends StateNotifier<({Locale locale, String outputLocale})> {
  static const String _key = 'app_locale_code';

  LocaleNotifier() : super((locale: const Locale('en'), outputLocale: 'en')) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_key) ?? 'en';
    state = _fromCode(code);
  }

  ({Locale locale, String outputLocale}) _fromCode(String code) {
    switch (code) {
      case 'zh':
        return (locale: const Locale('zh'), outputLocale: 'zh');
      case 'en':
      default:
        return (locale: const Locale('en'), outputLocale: 'en');
    }
  }

  /// BCP-style code for job payload / prompts: 'en' | 'zh'
  String get outputLocale => state.outputLocale;

  Locale get locale => state.locale;

  Future<void> setLocaleCode(String code) async {
    state = _fromCode(code);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, state.outputLocale);
  }

  Future<void> setLocale(Locale locale) async {
    final code = locale.languageCode == 'zh' ? 'zh' : 'en';
    await setLocaleCode(code);
  }
}

final localeProvider =
    StateNotifierProvider<LocaleNotifier, ({Locale locale, String outputLocale})>((ref) {
  return LocaleNotifier();
});
