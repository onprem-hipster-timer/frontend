import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/core/analytics/analytics_consent.dart';
import 'package:momeet/core/providers/retry_policy.dart';
import 'package:momeet/features/mypage/mypage.dart';
import 'package:momeet/features/mypage/presentation/pages/my_meetings_page.dart';
import 'package:momeet/features/timer/presentation/providers/timer_providers.dart';
import 'package:momeet/router.dart';
import 'package:momeet/shared/providers/api_providers.dart';

import '../../helpers/fake_rest_clients.dart';
import '../../helpers/kratos_mocks.dart';
import '../meeting/meeting_fixtures.dart';

/// 실제 라우터(routerProvider)로 마이페이지에서 내 모임 전체 목록을 열고 닫을 때 브라우저에 알리는 주소를 본다.
void main() {
  late KratosTestHarness harness;
  late FakeMeetingsClient meetings;

  setUpAll(() async {
    registerKratosFallbacks();
    await initializeDateFormatting('ko');
  });

  setUp(() async {
    harness = await KratosTestHarness.create();
    meetings = FakeMeetingsClient()
      ..mine = [
        for (var day = 1; day <= 7; day++)
          makeMeeting(
            id: 'meeting-$day',
            title: '모임 $day',
            createdAt: DateTime.utc(2027, 1, day),
          ),
      ];
  });

  Future<GoRouter> pumpMyPage(WidgetTester tester) async {
    tester.view.physicalSize = const Size(480, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        retry: appRetry,
        overrides: [
          ...harness.overrides,
          usersApiProvider.overrideWithValue(
            FakeUsersClient(consentRequired: false),
          ),
          meetingsApiProvider.overrideWithValue(meetings),
          todosApiProvider.overrideWithValue(FakeTodosClient()),
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
    final router = ProviderScope.containerOf(
      tester.element(find.byType(Router<Object>)),
    ).read(routerProvider);
    router.goNamed(AppRoute.mypage.name);
    await tester.pumpAndSettle();
    expect(find.byType(MyPage), findsOneWidget);
    return router;
  }

  /// 브라우저 주소창에 알린 주소
  String address(GoRouter router) =>
      router.routeInformationProvider.value.uri.toString();

  testWidgets('모두 보기를 누르면 전체 목록을 열고 주소가 목록이며, 뒤로 가면 마이페이지 주소다', (tester) async {
    final router = await pumpMyPage(tester);
    expect(address(router), AppRoute.mypage.path);

    final all = find.text('모두 보기 (7)');
    await tester.ensureVisible(all);
    await tester.pumpAndSettle();
    await tester.tap(all);
    await tester.pumpAndSettle();

    expect(find.byType(MyMeetingsPage), findsOneWidget);
    expect(address(router), AppRoute.myMeetings.path);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(find.byType(MyMeetingsPage), findsNothing);
    expect(find.byType(MyPage), findsOneWidget);
    expect(address(router), AppRoute.mypage.path);
  });
}
