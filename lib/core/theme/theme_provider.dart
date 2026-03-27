import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _themeModeKey = 'themeMode';

class ThemeNotifier extends AsyncNotifier<ThemeMode> {
  @override
  Future<ThemeMode> build() async {
    final prefs = await SharedPreferences.getInstance();
    final savedThemeMode = prefs.getString(_themeModeKey);

    switch (savedThemeMode) {
      case 'dark':
        return ThemeMode.dark;
      case 'light':
        return ThemeMode.light;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    final themeModeString = switch (mode) {
      ThemeMode.dark => 'dark',
      ThemeMode.light => 'light',
      ThemeMode.system => 'system',
    };

    await prefs.setString(_themeModeKey, themeModeString);
    state = AsyncData(mode);
  }

  Future<void> toggleTheme(bool isDarkMode) async {
    await setThemeMode(isDarkMode ? ThemeMode.dark : ThemeMode.light);
  }
}

final themeProvider = AsyncNotifierProvider<ThemeNotifier, ThemeMode>(
  () => ThemeNotifier(),
);
