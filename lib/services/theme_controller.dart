import 'package:flutter/material.dart';
import 'preferences_service.dart';

class ThemeController extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.dark;

  ThemeMode get themeMode => _themeMode;

  ThemeController() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final mode = await PreferencesService.getThemeMode();
    _themeMode = _parseThemeMode(mode);
    notifyListeners();
  }

  Future<void> updateThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    await PreferencesService.setThemeMode(mode.toString().split('.').last);
  }

  ThemeMode _parseThemeMode(String mode) {
    switch (mode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.dark;
    }
  }
}
