import 'package:flutter_test/flutter_test.dart' show setUpAll;
import 'package:intl/date_symbol_data_local.dart';
import 'package:layout_audit/layout_audit.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/auth/presentation/pages/account_deletion_pending_page.dart';
import 'package:momeet/features/auth/presentation/pages/auth_error_page.dart';
import 'package:momeet/features/auth/presentation/pages/consent_page.dart';
import 'package:momeet/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:momeet/features/auth/presentation/pages/login_page.dart';
import 'package:momeet/features/auth/presentation/pages/signup_page.dart';
import 'package:momeet/features/auth/presentation/pages/verification_page.dart';
import 'package:momeet/features/calendar/presentation/widgets/calendar_settings_drawer.dart';
import 'package:momeet/features/mypage/presentation/pages/mypage_page.dart';
import 'package:momeet/features/mypage/presentation/providers/my_page_providers.dart';
import 'package:momeet/features/mypage/presentation/widgets/account_deletion_dialog.dart';
import 'package:momeet/features/settings/presentation/widgets/timezone_selection_sheet.dart';
import 'package:momeet/shared/api/kratos/kratos_client.dart';
import 'package:momeet/shared/pages/security_warning_page.dart';
import 'package:momeet/shared/providers/api_providers.dart';

import '../helpers/fake_rest_clients.dart';
import '../helpers/kratos_mocks.dart';
import '../helpers/layout_audit_app.dart';

/// 인증·마이페이지·설정·보안 경고 화면을 화면 크기 × 글자 배율 × 긴 문구로 점검한다.
///
/// 사용자가 넣는 글자(이메일, 태그 이름)와 주소창 경로에 [StressText]를 넣는다.
void main() {
  late KratosTestHarness signedOut;
  late KratosTestHarness signedIn;

  setUpAll(() async {
    registerKratosFallbacks();
    signedOut = await KratosTestHarness.create(authenticated: false);
    signedOut.stubCreateFlow(KratosFlowType.login, 'flow-login');
    signedIn = await KratosTestHarness.create();
    await initializeDateFormatting('ko');
  });

  Widget signedOutApp(Widget child) =>
      wrapWithApp(overrides: signedOut.overrides)(child);

  testLayoutAudit(
    'login_page',
    subject: '입력한 이메일',
    build: (text) => signedOutApp(LoginPage(initialEmail: text.value)),
  );

  testLayoutAudit(
    'signup_page',
    subject: '입력한 이메일',
    build: (text) => signedOutApp(SignupPage(initialEmail: text.value)),
  );

  testLayoutAudit(
    'forgot_password_page',
    subject: '안내',
    texts: const [StressTexts.koreanLong],
    build: (text) => signedOutApp(const ForgotPasswordPage()),
  );

  testLayoutAudit(
    'verification_page',
    subject: '코드를 보낸 이메일',
    build: (text) => signedOutApp(
      VerificationPage(flowId: 'flow-verify', email: text.value),
    ),
  );

  testLayoutAudit(
    'auth_error_page',
    subject: '안내',
    texts: const [StressTexts.koreanLong],
    build: (text) => signedOutApp(const AuthErrorPage()),
  );

  testLayoutAudit(
    'consent_page',
    subject: '안내',
    texts: const [StressTexts.koreanLong],
    build: (text) => wrapWithApp(
      overrides: [
        ...signedIn.overrides,
        usersApiProvider.overrideWithValue(FakeUsersClient()),
      ],
    )(const ConsentPage()),
  );

  testLayoutAudit(
    'account_deletion_pending_page',
    subject: '안내',
    texts: const [StressTexts.koreanLong],
    build: (text) => wrapWithApp(
      overrides: [
        ...signedIn.overrides,
        usersApiProvider.overrideWithValue(
          FakeUsersClient(deletionPending: true),
        ),
      ],
    )(const AccountDeletionPendingPage()),
  );

  testLayoutAudit(
    'security_warning_page',
    subject: '막은 경로',
    build: (text) =>
        wrapWithApp()(SecurityWarningPage(attemptedUrl: '/${text.value}')),
  );

  testLayoutAudit(
    'mypage_page',
    subject: '태그 이름',
    build: (text) => wrapWithApp(
      overrides: [
        ...signedIn.overrides,
        todoStatisticsProvider.overrideWith(
          (ref) async => const TodoStatistics(
            totalCount: 1234,
            unscheduledCount: 120,
            scheduledCount: 340,
            doneCount: 700,
            cancelledCount: 74,
          ),
        ),
        tagUsageStatisticsProvider.overrideWith(
          (ref) async => TagUsageStatistics(
            tagUsageMap: {
              for (var i = 0; i < 6; i++)
                'tag-$i': TagUsageItem(
                  tagId: 'tag-$i',
                  tagName: i.isEven ? text.value : '태그$i',
                  count: 120 - i,
                ),
            },
          ),
        ),
      ],
    )(const MyPage()),
  );

  testLayoutAudit(
    'account_deletion_dialog',
    subject: '안내',
    texts: const [StressTexts.koreanLong],
    build: (text) => wrapWithApp(
      overrides: [
        ...signedIn.overrides,
        usersApiProvider.overrideWithValue(FakeUsersClient()),
      ],
    )(const AccountDeletionDialog()),
  );

  testLayoutAudit(
    'timezone_selection_sheet',
    subject: '검색어',
    texts: const [StressTexts.koreanLong],
    build: (text) => wrapWithApp(overrides: signedIn.overrides)(
      const TimezoneSelectionSheet(),
    ),
  );

  testLayoutAudit(
    'calendar_settings_drawer',
    subject: '설정 항목',
    texts: const [StressTexts.koreanLong],
    build: (text) => wrapWithApp(overrides: signedIn.overrides)(
      const CalendarSettingsDrawer(),
    ),
  );
}
