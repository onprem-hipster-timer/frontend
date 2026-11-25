import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/core/analytics/analytics_consent.dart';
import 'package:momeet/core/providers/retry_policy.dart';
import 'package:momeet/features/meeting/presentation/utils/meeting_brush_texts.dart';
import 'package:momeet/features/timer/presentation/providers/timer_providers.dart';
import 'package:momeet/features/trial/presentation/pages/trial_page.dart';
import 'package:momeet/features/trial/presentation/utils/trial_texts.dart';
import 'package:momeet/router.dart';
import 'package:momeet/shared/api/kratos/kratos_client.dart';
import 'package:momeet/shared/providers/api_providers.dart';
import 'package:momeet/shared/widgets/scaffold_with_nav.dart';

import '../../helpers/fake_rest_clients.dart';
import '../../helpers/kratos_mocks.dart';

/// 실제 라우터(routerProvider)로 체험하기 주소를 연다.
void main() {
  setUpAll(() async {
    registerKratosFallbacks();
    await initializeDateFormatting('ko_KR');
  });

  /// 첫 화면은 불러오기가 계속 돌 수 있어 pumpAndSettle 대신 잠깐씩 넘긴다.
  Future<void> pumpAWhile(WidgetTester tester) async {
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  testWidgets('로그인하지 않은 채 /demo를 열면 탭 셸 밖에서 체험하기의 달력 단계가 열린다', (tester) async {
    final harness = await KratosTestHarness.create(authenticated: false);
    harness.stubCreateFlow(KratosFlowType.login, 'flow-login');
    await tester.pumpWidget(
      ProviderScope(
        retry: appRetry,
        overrides: [
          ...harness.overrides,
          usersApiProvider.overrideWithValue(FakeUsersClient()),
          timerWsClientProvider.overrideWithValue(null),
          analyticsConsentBridgeProvider.overrideWithValue(
            InMemoryAnalyticsConsentBridge(),
          ),
        ],
        child: Consumer(
          builder: (context, ref, _) =>
              MaterialApp.router(routerConfig: ref.watch(routerProvider)),
        ),
      ),
    );
    await pumpAWhile(tester);
    final router = ProviderScope.containerOf(
      tester.element(find.byType(Router<Object>)),
    ).read(routerProvider);

    router.go('/demo');
    await pumpAWhile(tester);

    expect(
      router.routerDelegate.currentConfiguration.uri.toString(),
      AppRoute.trial.path,
    );
    expect(find.byType(TrialPage), findsOneWidget);
    expect(find.byType(ScaffoldWithNavBar), findsNothing);
    expect(find.text(keepWords(trialCalendarHeadline)), findsOneWidget);
  });
}
