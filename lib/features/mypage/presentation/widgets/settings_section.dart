import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:momeet/core/analytics/analytics_consent.dart';
import 'package:momeet/core/config/legal_links.dart';
import 'package:momeet/core/providers/browser_provider.dart';
import 'package:momeet/core/theme/theme_provider.dart';
import 'package:momeet/core/providers/timezone_provider.dart';
import 'package:momeet/features/mypage/presentation/widgets/account_deletion_dialog.dart';
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
              const _AnalyticsTile(),
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
              _LegalLinkTile(
                icon: Icons.description_outlined,
                title: '이용약관',
                url: LegalLinks.terms,
              ),
              const Divider(height: 1),
              _LegalLinkTile(
                icon: Icons.privacy_tip_outlined,
                title: '개인정보처리방침',
                url: LegalLinks.privacy,
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
        const SizedBox(height: 8),
        // 실수로 누르지 않도록 설정 목록 밖 맨 아래에 작게 둔다
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => showAccountDeletionDialog(context),
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.onSurfaceVariant,
            ),
            child: const Text('회원 탈퇴'),
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

/// 사용성 분석(Microsoft Clarity) 허용. 언제든 켜고 끌 수 있다
class _AnalyticsTile extends ConsumerWidget {
  const _AnalyticsTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final consent = ref.watch(analyticsConsentProvider);
    return SwitchListTile(
      secondary: Icon(
        Icons.analytics_outlined,
        color: theme.colorScheme.onSurface,
      ),
      title: const Text('사용성 분석 허용'),
      subtitle: const Text('방문·클릭·스크롤·화면 재현 정보를 Microsoft Clarity(미국)로 보냅니다'),
      value: consent == AnalyticsConsent.granted,
      onChanged: (value) {
        ref
            .read(analyticsConsentProvider.notifier)
            .set(value ? AnalyticsConsent.granted : AnalyticsConsent.denied);
      },
    );
  }
}

/// 누르면 [url]의 약관 문서를 새 탭으로 연다
class _LegalLinkTile extends ConsumerWidget {
  const _LegalLinkTile({
    required this.icon,
    required this.title,
    required this.url,
  });

  final IconData icon;
  final String title;
  final Uri url;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon, color: theme.colorScheme.onSurface),
      title: Text(title),
      trailing: Icon(
        Icons.open_in_new,
        color: theme.colorScheme.onSurfaceVariant,
      ),
      onTap: () => ref.read(openLinkProvider)(url),
    );
  }
}
