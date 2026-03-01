import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _themeKey = 'isDarkMode';

class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.system) {
    _loadTheme();
  }

  late SharedPreferences _prefs;

  Future<void> _loadTheme() async {
    _prefs = await SharedPreferences.getInstance();
    final isDarkMode = _prefs.getBool(_themeKey);

    if (isDarkMode != null) {
      state = isDarkMode ? ThemeMode.dark : ThemeMode.light;
    }
  }

  Future<void> toggleTheme() async {
    final newThemeMode = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    final isDarkMode = newThemeMode == ThemeMode.dark;

    await _prefs.setBool(_themeKey, isDarkMode);
    state = newThemeMode;
  }

  bool get isDarkMode => state == ThemeMode.dark;
}

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>(
  (ref) => ThemeNotifier(),
);

