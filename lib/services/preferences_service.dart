import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const String _keySelectedSection = 'selected_section';
  static const String _keyShowProfessorNames = 'show_professor_names';
  static const String _keyLastRefreshDate = 'last_refresh_date';
  static const String _keyThemeMode = 'theme_mode';

  static Future<String?> getSelectedSection() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keySelectedSection);
  }

  static Future<void> setSelectedSection(String section) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySelectedSection, section);
  }

  static Future<bool> getShowProfessorNames() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyShowProfessorNames) ?? true;
  }

  static Future<void> setShowProfessorNames(bool show) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyShowProfessorNames, show);
  }

  static Future<String?> getLastRefreshDate() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyLastRefreshDate);
  }

  static Future<void> setLastRefreshDate(String date) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLastRefreshDate, date);
  }

  static Future<String> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyThemeMode) ?? 'system';
  }

  static Future<void> setThemeMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyThemeMode, mode);
  }
}
