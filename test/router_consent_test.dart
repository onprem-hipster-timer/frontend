import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:momeet/core/analytics/analytics_consent.dart';
import 'package:momeet/core/providers/my_profile_provider.dart';
import 'package:momeet/core/providers/retry_policy.dart';
import 'package:momeet/features/auth/presentation/pages/consent_page.dart';
import 'package:momeet/features/timer/presentation/providers/timer_providers.dart';
import 'package:momeet/router.dart';
import 'package:momeet/shared/providers/api_providers.dart';

import 'helpers/fake_rest_clients.dart';
import 'helpers/kratos_mocks.dart';

/// 실제 라우터(routerProvider)로 약관 동의 화면을 거치는 흐름을 본다.
///
/// 목적지는 다른 기능의 데이터를 부르지 않는 `/timer/detail`을 쓴다.
void main() {
  late KratosTestHarness harness;
  late FakeUsersClient users;

  setUpAll(registerKratosFallbacks);

  setUp(() async {
    harness = await KratosTestHarness.create();
    users = FakeUsersClient();
  });

  Future<(GoRouter, ProviderContainer)> pumpRouter(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        retry: appRetry,
        overrides: [
          ...harness.overrides,
          usersApiProvider.overrideWithValue(users),
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
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(Router<Object>)),
    );
    return (container.read(routerProvider), container);
  }

  String location(GoRouter router) =>
      router.routerDelegate.currentConfiguration.uri.toString();

  const destination = '/timer/detail';
  final gated =
      '${AppRoute.consent.path}?redirect=${Uri.encodeComponent(destination)}';

  testWidgets('동의 전이면 연 경로 대신 동의 화면을 보이고, 동의하면 그 경로로 간다', (tester) async {
    final (router, _) = await pumpRouter(tester);
    expect(location(router), AppRoute.consent.path);

    router.go(destination);
    await tester.pumpAndSettle();
    expect(location(router), gated);
    expect(find.byType(ConsentPage), findsOneWidget);

    await tester.tap(find.text('전체 동의'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('동의하고 시작하기'));
    await tester.tap(find.text('동의하고 시작하기'));
    await tester.pumpAndSettle();

    expect(location(router), destination);
    expect(find.byType(ConsentPage), findsNothing);
  });

  testWidgets('다른 곳에서 동의를 마쳐 프로필이 바뀌어도 원래 경로로 간다', (tester) async {
    final (router, container) = await pumpRouter(tester);
    router.go(destination);
    await tester.pumpAndSettle();
    expect(location(router), gated);

    users.profile = users.profile.copyWith(consentRequired: false);
    container.invalidate(myProfileProvider);
    await tester.pumpAndSettle();

    expect(location(router), destination);
  });

  testWidgets('동의하지 않고 로그아웃하면 로그인 화면으로 간다', (tester) async {
    when(() => harness.kratos.logout(any())).thenAnswer((_) async {});
    final (router, _) = await pumpRouter(tester);

    await tester.ensureVisible(find.text('동의하지 않고 로그아웃'));
    await tester.tap(find.text('동의하지 않고 로그아웃'));
    await tester.pumpAndSettle();

    expect(router.routerDelegate.currentConfiguration.uri.path, '/login');
    expect(users.agreed, isEmpty);
  });
}
