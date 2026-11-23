import 'package:flutter_riverpod/flutter_riverpod.dart' show AsyncData;
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/app_route.dart';
import 'package:momeet/core/analytics/analytics_consent.dart';
import 'package:momeet/core/providers/browser_provider.dart';
import 'package:momeet/core/providers/my_profile_provider.dart';
import 'package:momeet/core/providers/timezone_provider.dart';
import 'package:momeet/core/theme/theme_provider.dart';
import 'package:momeet/features/mypage/presentation/widgets/settings_section.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import '../sample_provider_scope.dart';

const _themeModes = {
  '시스템 설정 따름': ThemeMode.system,
  '라이트': ThemeMode.light,
  '다크': ThemeMode.dark,
};

const _timezones = {
  '서울': 'Asia/Seoul',
  '뉴욕': 'America/New_York',
  '콜카타(30분 단위)': 'Asia/Kolkata',
  '긴 도시 이름': 'America/Port-au-Prince',
};

@widgetbook.UseCase(name: '설정 목록', type: SettingsSection, path: '[마이페이지]')
Widget settingsSection(BuildContext context) {
  final knobs = context.knobs;
  final themeMode = knobs.object.dropdown(
    label: '화면 모드',
    description:
        "처음에는 기기 설정을 따르고 '현재 시스템 설정을 따릅니다'를 적는다. 스위치를 누르면 라이트·다크 중 하나로 정해진다",
    options: _themeModes.keys.toList(),
  );
  final timezone = knobs.object.dropdown(
    label: '타임존',
    options: _timezones.keys.toList(),
  );
  final analytics = knobs.boolean(label: '사용성 분석 허용');
  final saveFails = knobs.boolean(
    label: '사용성 분석 저장 실패',
    description: '스위치를 누를 때 계정에 저장하지 못하면 아래에 알림을 띄우고 스위치는 그대로 둔다',
  );
  return SampleProviderScope(
    // 노브를 바꾸면 견본 상태를 처음부터 다시 만든다
    key: ValueKey((themeMode, timezone, analytics, saveFails)),
    overrides: [
      themeProvider.overrideWith(() => _SampleTheme(_themeModes[themeMode]!)),
      timezoneProvider.overrideWith(
        () => _SampleTimezone(_timezones[timezone]!),
      ),
      analyticsConsentProvider.overrideWith(
        () => _SampleConsent(AnalyticsConsent.of(analytics)),
      ),
      myProfileProvider.overrideWith(() => _SampleProfile(fails: saveFails)),
      // 약관 링크는 새 탭으로 여는데, 카탈로그에서는 아무것도 열지 않는다
      openLinkProvider.overrideWithValue((_) async {}),
    ],
    // 앱에서는 마이페이지 맨 아래, 좌우 20 여백 안에 놓인다
    child: Scaffold(
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        children: [
          SettingsSection(
            // 앱은 확인 다이얼로그를 거쳐 로그아웃하고 로그인 화면으로 보낸다
            onSignOut: () => context.goNamed(AppRoute.login.name),
          ),
        ],
      ),
    ),
  );
}

/// 기기에 저장하지 않고 고른 화면 모드만 바꾼다
class _SampleTheme extends ThemeNotifier {
  _SampleTheme(this._initial);

  final ThemeMode _initial;

  @override
  ThemeMode build() => _initial;

  @override
  Future<void> setThemeMode(ThemeMode mode) async => state = mode;
}

class _SampleTimezone extends TimezoneNotifier {
  _SampleTimezone(this._initial);

  final String _initial;

  @override
  Future<String> build() async => _initial;

  @override
  Future<void> updateTimezone(String newTimezone) async =>
      state = AsyncData(newTimezone);
}

class _SampleConsent extends AnalyticsConsentNotifier {
  _SampleConsent(this._initial);

  final AnalyticsConsent _initial;

  @override
  AnalyticsConsent? build() => _initial;

  @override
  void set(AnalyticsConsent value) => state = value;
}

/// 사용성 분석 동의를 계정에 저장하는 대신 바로 끝내거나([fails]면) 실패한다
class _SampleProfile extends MyProfileNotifier {
  _SampleProfile({required this.fails});

  final bool fails;

  @override
  Future<MyProfileRead?> build() async => null;

  @override
  Future<void> setAnalytics(bool value) async {
    if (fails) throw StateError('저장하지 못했습니다');
  }

  @override
  Future<void> requestDeletion() async {}
}
