import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider extends ChangeNotifier {
  static const String _key = 'selected_language';
  static LocaleProvider? _instance;

  static LocaleProvider get instance => _instance ??= LocaleProvider();

  Locale _locale = const Locale('fr');

  Locale get locale => _locale;
  String get languageCode => _locale.languageCode;
  bool get isRTL => _locale.languageCode == 'ar';

  LocaleProvider() {
    _instance = this;
  }

  Future<void> loadSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCode = prefs.getString(_key);
    if (savedCode != null && ['fr', 'ar', 'en'].contains(savedCode)) {
      _locale = Locale(savedCode);
      notifyListeners();
    }
  }

  Future<void> initLocale() => loadSavedLocale();

  Future<void> setLocale(String langCode) async {
    if (!['fr', 'ar', 'en'].contains(langCode)) return;
    _locale = Locale(langCode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, langCode);
    notifyListeners();
  }

  static Future<bool> isFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    return !prefs.containsKey(_key);
  }
}
