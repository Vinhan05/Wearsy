import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_translations.dart';

class LanguageProvider extends ChangeNotifier {
  static const String _prefLanguageKey = 'selected_app_language_code';
  String _currentLanguage = AppTranslations.vi;

  LanguageProvider() {
    _loadLanguageFromPrefs();
  }

  String get currentLanguage => _currentLanguage;
  Locale get currentLocale => Locale(_currentLanguage);

  bool get isVietnamese => _currentLanguage == AppTranslations.vi;
  bool get isEnglish => _currentLanguage == AppTranslations.en;

  String get currentFlag => isVietnamese ? '🇻🇳' : '🇬🇧';
  String get currentLanguageName => isVietnamese ? 'Tiếng Việt' : 'English';

  String get targetFlag => isVietnamese ? '🇬🇧' : '🇻🇳';
  String get targetLanguageName => isVietnamese ? 'English' : 'Tiếng Việt';

  String get targetShortCode => isVietnamese ? 'EN' : 'VI';
  String get currentShortCode => isVietnamese ? 'VI' : 'EN';

  /// Translate a key with optional dynamic placeholder interpolation
  String tr(String key, {Map<String, dynamic>? params}) {
    return AppTranslations.translate(key, _currentLanguage, params: params);
  }

  Future<void> _loadLanguageFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCode = prefs.getString(_prefLanguageKey);
      if (savedCode != null && AppTranslations.supportedLanguages.contains(savedCode)) {
        _currentLanguage = savedCode;
        notifyListeners();
      }
    } catch (_) {}
  }

  /// Change to a specific language ('vi' or 'en')
  Future<void> setLanguage(String langCode) async {
    if (_currentLanguage == langCode) return;
    if (!AppTranslations.supportedLanguages.contains(langCode)) return;

    _currentLanguage = langCode;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefLanguageKey, langCode);
    } catch (_) {}
  }

  /// Toggle between Vietnamese and English
  Future<void> toggleLanguage() async {
    final nextLang = isVietnamese ? AppTranslations.en : AppTranslations.vi;
    await setLanguage(nextLang);
  }
}
