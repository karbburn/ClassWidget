import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

final sharedPreferencesProvider =
    FutureProvider<SharedPreferences>((ref) async {
  return await SharedPreferences.getInstance();
});

final showProfessorNamesProvider = FutureProvider<bool>((ref) async {
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  return prefs.getBool(AppConstants.prefShowProfessor) ?? true;
});

final themeModeProvider = FutureProvider<String>((ref) async {
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  return prefs.getString(AppConstants.prefThemeMode) ?? 'system';
});

final preferencesNotifierProvider =
    StateNotifierProvider<PreferencesNotifier, AsyncValue<void>>((ref) {
  return PreferencesNotifier(ref);
});

class PreferencesNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  PreferencesNotifier(this._ref) : super(const AsyncValue.data(null));

  Future<void> setShowProfessorNames(bool value) async {
    state = const AsyncValue.loading();
    try {
      final prefs = await _ref.read(sharedPreferencesProvider.future);
      await prefs.setBool(AppConstants.prefShowProfessor, value);
      _ref.invalidate(showProfessorNamesProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> setThemeMode(String mode) async {
    state = const AsyncValue.loading();
    try {
      final prefs = await _ref.read(sharedPreferencesProvider.future);
      await prefs.setString(AppConstants.prefThemeMode, mode);
      _ref.invalidate(themeModeProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> setMorningCutoff(int hour) async {
    state = const AsyncValue.loading();
    try {
      final prefs = await _ref.read(sharedPreferencesProvider.future);
      await prefs.setInt(AppConstants.prefMorningCutoff, hour);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
