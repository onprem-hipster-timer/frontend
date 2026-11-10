import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:momeet/core/theme/theme_provider.dart';
import 'package:momeet/core/providers/timezone_provider.dart';
import 'package:momeet/features/settings/settings.dart';
import 'package:momeet/router.dart';

/// 마이페이지 설정 섹션
class SettingsSection extends StatelessWidget {
  final VoidCallback onSignOut;

  const SettingsSection({super.key, required this.onSignOut});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
          child: Column(
            children: [
              const _DarkModeTile(),
              const Divider(height: 1),
              const _TimezoneTile(),
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
                // 메일로 받은 코드로만 바꾼다 (비밀번호 재설정 화면을 그대로 쓴다)
                onTap: () => context.pushNamed(AppRoute.forgotPassword.name),
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

/// 다크 모드 켜기. 시스템 설정을 따르는 중이면 그 사실을 알린다
class _DarkModeTile extends ConsumerWidget {
  const _DarkModeTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currentThemeMode = ref.watch(themeProvider);
    final isDarkMode = currentThemeMode == ThemeMode.system
        ? MediaQuery.platformBrightnessOf(context) == Brightness.dark
        : currentThemeMode == ThemeMode.dark;
    return SwitchListTile(
      secondary: Icon(Icons.dark_mode, color: theme.colorScheme.onSurface),
      title: const Text('다크 모드'),
      value: isDarkMode,
      onChanged: (value) {
        ref.read(themeProvider.notifier).toggleTheme(value);
      },
      subtitle: currentThemeMode == ThemeMode.system
          ? const Text('현재 시스템 설정을 따릅니다')
          : null,
    );
  }
}

/// 지금 타임존을 보이고, 누르면 타임존 고르기를 연다
class _TimezoneTile extends ConsumerWidget {
  const _TimezoneTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currentTimezone =
        ref.watch(timezoneProvider).value ?? defaultTimezone;
    return ListTile(
      leading: Icon(Icons.language, color: theme.colorScheme.onSurface),
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
    );
  }
}
