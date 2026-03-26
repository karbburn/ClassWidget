import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

class PreferencesService {
  static const String _keySelectedSection = 'selected_section';
  static const String _keyLastRefreshDate = 'last_refresh_date';

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
    return prefs.getBool(AppConstants.prefShowProfessor) ?? true;
  }

  static Future<void> setShowProfessorNames(bool show) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.prefShowProfessor, show);
  }

  static Future<int> getMorningCutoff() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(AppConstants.prefMorningCutoff) ?? AppConstants.defaultMorningCutoff;
  }

  static Future<void> setMorningCutoff(int hour) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(AppConstants.prefMorningCutoff, hour);
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
    return prefs.getString(AppConstants.prefThemeMode) ?? 'system';
  }

  static Future<void> setThemeMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.prefThemeMode, mode);
  }
}
