import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:momeet/core/theme/theme_provider.dart';
import 'package:momeet/core/providers/shared_preferences_provider.dart';

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  ProviderContainer createContainer() {
    return ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
  }

  group('ThemeNotifier', () {
    test('초기값은 ThemeMode.system이다', () {
      final container = createContainer();
      addTearDown(container.dispose);

      expect(container.read(themeProvider), ThemeMode.system);
    });

    test('저장된 값이 dark이면 ThemeMode.dark를 반환한다', () async {
      await prefs.setString('themeMode', 'dark');

      final container = createContainer();
      addTearDown(container.dispose);

      expect(container.read(themeProvider), ThemeMode.dark);
    });

    test('저장된 값이 light이면 ThemeMode.light를 반환한다', () async {
      await prefs.setString('themeMode', 'light');

      final container = createContainer();
      addTearDown(container.dispose);

      expect(container.read(themeProvider), ThemeMode.light);
    });

    test('toggleTheme(true)는 dark 모드로 전환한다', () async {
      final container = createContainer();
      addTearDown(container.dispose);

      await container.read(themeProvider.notifier).toggleTheme(true);

      expect(container.read(themeProvider), ThemeMode.dark);
      expect(prefs.getString('themeMode'), 'dark');
    });

    test('toggleTheme(false)는 light 모드로 전환한다', () async {
      final container = createContainer();
      addTearDown(container.dispose);

      await container.read(themeProvider.notifier).toggleTheme(false);

      expect(container.read(themeProvider), ThemeMode.light);
      expect(prefs.getString('themeMode'), 'light');
    });

    test('setThemeMode는 상태와 SharedPreferences를 모두 업데이트한다', () async {
      final container = createContainer();
      addTearDown(container.dispose);

      await container.read(themeProvider.notifier).setThemeMode(ThemeMode.dark);
      expect(container.read(themeProvider), ThemeMode.dark);
      expect(prefs.getString('themeMode'), 'dark');

      await container
          .read(themeProvider.notifier)
          .setThemeMode(ThemeMode.system);
      expect(container.read(themeProvider), ThemeMode.system);
      expect(prefs.getString('themeMode'), 'system');
    });
  });
}
