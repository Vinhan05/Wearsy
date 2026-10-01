import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_theme.dart';
import 'app_theme_palette.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _prefThemeKey = 'selected_app_theme_id';
  AppThemePalette _currentPalette = AppThemePalette.theme1;

  ThemeProvider() {
    _loadThemeFromPrefs();
  }

  AppThemePalette get currentPalette => _currentPalette;
  String get currentThemeId => _currentPalette.id;
  ThemeData get currentThemeData => AppTheme.buildTheme(_currentPalette);

  Future<void> _loadThemeFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedId = prefs.getString(_prefThemeKey);
      if (savedId != null) {
        _currentPalette = AppThemePalette.getById(savedId);
        AppTheme.setPalette(_currentPalette);
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> switchTheme(String themeId) async {
    if (_currentPalette.id == themeId) return;
    _currentPalette = AppThemePalette.getById(themeId);
    AppTheme.setPalette(_currentPalette);
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefThemeKey, themeId);
    } catch (_) {}
  }
}
