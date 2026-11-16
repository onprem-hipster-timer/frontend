import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/core/analytics/analytics_consent.dart';
import 'package:momeet/core/providers/retry_policy.dart';
import 'package:momeet/features/meeting/presentation/pages/meeting_page.dart';
import 'package:momeet/features/timer/presentation/providers/timer_providers.dart';
import 'package:momeet/router.dart';
import 'package:momeet/shared/api/kratos/kratos_client.dart';
import 'package:momeet/shared/providers/api_providers.dart';
import 'package:momeet/shared/widgets/scaffold_with_nav.dart';

import '../../helpers/fake_rest_clients.dart';
import '../../helpers/kratos_mocks.dart';
import 'meeting_fixtures.dart';

/// 실제 라우터(routerProvider)로 모임 화면의 주소를 연다.
void main() {
  late KratosTestHarness harness;
  late FakeMeetingsClient meetings;

  setUpAll(() async {
    registerKratosFallbacks();
    await initializeDateFormatting('ko_KR');
  });

  setUp(() async {
    harness = await KratosTestHarness.create();
    meetings = FakeMeetingsClient(meeting: makeMeeting());
  });

  /// 첫 화면(달력)은 불러오기가 계속 돌 수 있어 pumpAndSettle 대신 잠깐씩 넘긴다.
  Future<void> pumpAWhile(WidgetTester tester) async {
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  Future<GoRouter> pumpRouter(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        retry: appRetry,
        overrides: [
          ...harness.overrides,
          usersApiProvider.overrideWithValue(
            FakeUsersClient(consentRequired: false),
          ),
          meetingsApiProvider.overrideWithValue(meetings),
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
    return ProviderScope.containerOf(
      tester.element(find.byType(Router<Object>)),
    ).read(routerProvider);
  }

  String location(GoRouter router) =>
      router.routerDelegate.currentConfiguration.uri.toString();

  testWidgets('공유 링크 주소의 모임 번호로 모임 화면을 탭 셸 밖에서 연다', (tester) async {
    final router = await pumpRouter(tester);

    router.go('/meetings/meeting-1');
    await pumpAWhile(tester);

    expect(location(router), '/meetings/meeting-1');
    expect(find.byType(MeetingPage), findsOneWidget);
    expect(find.text('팀 회의'), findsOneWidget);
    expect(meetings.reads, ['meeting-1']);
    expect(find.byType(ScaffoldWithNavBar), findsNothing);
  });

  testWidgets('로그인하지 않았으면 로그인 화면으로 보내며 그 모임 주소를 돌아갈 곳으로 붙인다', (tester) async {
    harness = await KratosTestHarness.create(authenticated: false);
    harness.stubCreateFlow(KratosFlowType.login, 'flow-login');
    final router = await pumpRouter(tester);

    router.go('/meetings/meeting-1');
    await pumpAWhile(tester);

    expect(
      location(router),
      '${AppRoute.login.path}?redirect=${Uri.encodeComponent('/meetings/meeting-1')}',
    );
    expect(meetings.reads, isEmpty);
  });
}
