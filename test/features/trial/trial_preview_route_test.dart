import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/core/analytics/analytics_consent.dart';
import 'package:momeet/core/providers/retry_policy.dart';
import 'package:momeet/features/timer/presentation/providers/timer_providers.dart';
import 'package:momeet/features/trial/presentation/pages/trial_page.dart';
import 'package:momeet/features/trial/presentation/pages/trial_preview_page.dart';
import 'package:momeet/features/trial/presentation/utils/trial_preview_kind.dart';
import 'package:momeet/router.dart';
import 'package:momeet/shared/api/kratos/kratos_client.dart';
import 'package:momeet/shared/providers/api_providers.dart';
import 'package:momeet/shared/widgets/scaffold_with_nav.dart';

import 'package:timezone/data/latest.dart' as tz;

import '../../helpers/fake_rest_clients.dart';
import '../../helpers/kratos_mocks.dart';

/// 실제 라우터(routerProvider)로 랜딩 미리보기 주소를 연다.
///
/// 미뤄 불러오는 화면은 한 파일에서 처음 불러온 테스트 안에서만 뜨므로, 주소마다 테스트를 나누지 않고 한 테스트에서
/// 차례로 연다.
void main() {
  setUpAll(() async {
    registerKratosFallbacks();
    tz.initializeTimeZones();
    await initializeDateFormatting('ko_KR');
  });

  /// 첫 화면은 불러오기가 계속 돌 수 있어 pumpAndSettle 대신 잠깐씩 넘긴다.
  Future<void> pumpAWhile(WidgetTester tester) async {
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  testWidgets(
    '로그인하지 않은 채 미리보기 주소를 열면 탭 셸 밖에서 그 종류의 미리보기가, 종류가 없거나 모르는 것이면 체험하기가 열린다',
    (tester) async {
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
      String location() =>
          router.routerDelegate.currentConfiguration.uri.toString();

      for (final kind in TrialPreviewKind.values) {
        final path = '/demo/preview?kind=${kind.name}';
        router.go(path);
        await pumpAWhile(tester);

        expect(location(), path);
        expect(
          tester.widget<TrialPreviewPage>(find.byType(TrialPreviewPage)).kind,
          kind,
        );
        expect(find.byType(ScaffoldWithNavBar), findsNothing, reason: path);
      }

      for (final path in ['/demo/preview?kind=unknown', '/demo/preview']) {
        router.go(path);
        await pumpAWhile(tester);

        expect(location(), AppRoute.trial.path, reason: path);
        expect(find.byType(TrialPage), findsOneWidget, reason: path);
        expect(find.byType(TrialPreviewPage), findsNothing, reason: path);
      }
    },
  );
}
