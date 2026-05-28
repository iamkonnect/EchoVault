import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleNotifier extends StateNotifier<Locale> {
  static const String _localeKey = 'app_locale';
  static const List<Locale> _supportedLocales = [
    Locale('en'),
    Locale('sw'),
    Locale('fr'),
  ];

  LocaleNotifier() : super(const Locale('en')) {
    _loadLocale();
  }

  List<Locale> get supportedLocales => _supportedLocales;

  String get currentLanguage => state.languageCode == 'en' ? 'English' : 
                                state.languageCode == 'sw' ? 'Swahili' : 'French';

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final localeCode = prefs.getString(_localeKey) ?? 'en';
    super.state = Locale(localeCode);
  }

  Future<void> setLocale(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, languageCode);
    state = Locale(languageCode);
  }
}

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) => LocaleNotifier());

