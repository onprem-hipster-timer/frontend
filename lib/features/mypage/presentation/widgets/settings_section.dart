import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:momeet/core/theme/theme_provider.dart';
import 'package:momeet/core/providers/timezone_provider.dart';
import 'package:momeet/features/settings/settings.dart';

/// 마이페이지 설정 섹션
class SettingsSection extends ConsumerWidget {
  final VoidCallback onSignOut;

  const SettingsSection({super.key, required this.onSignOut});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currentThemeMode = ref.watch(themeProvider);
    final isDarkMode = currentThemeMode == ThemeMode.system
        ? MediaQuery.platformBrightnessOf(context) == Brightness.dark
        : currentThemeMode == ThemeMode.dark;
    final currentTimezone =
        ref.watch(timezoneProvider).value ?? defaultTimezone;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '설정',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              SwitchListTile(
                secondary: Icon(
                  Icons.dark_mode,
                  color: theme.colorScheme.onSurface,
                ),
                title: const Text('다크 모드'),
                value: isDarkMode,
                onChanged: (value) {
                  ref.read(themeProvider.notifier).toggleTheme(value);
                },
                subtitle: currentThemeMode == ThemeMode.system
                    ? const Text('현재 시스템 설정을 따릅니다')
                    : null,
              ),
              const Divider(height: 1),
              ListTile(
                leading: Icon(
                  Icons.language,
                  color: theme.colorScheme.onSurface,
                ),
                title: const Text('타임존 설정'),
                subtitle: Text(
                  getTimezoneDisplayName(currentTimezone),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                trailing: Icon(
                  Icons.chevron_right,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                onTap: () {
                  showTimezoneSelectionSheet(context);
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: Icon(
                  Icons.lock_outline,
                  color: theme.colorScheme.onSurface,
                ),
                title: const Text('비밀번호 변경'),
                trailing: Icon(
                  Icons.chevron_right,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                onTap: () {
                  showPasswordChangeSheet(context);
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: Icon(Icons.logout, color: theme.colorScheme.error),
                title: Text(
                  '로그아웃',
                  style: TextStyle(color: theme.colorScheme.error),
                ),
                onTap: onSignOut,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
