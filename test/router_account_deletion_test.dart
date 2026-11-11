import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';
import 'package:momeet/core/analytics/analytics_consent.dart';
import 'package:momeet/core/providers/auth_provider.dart';
import 'package:momeet/core/providers/my_profile_provider.dart';
import 'package:momeet/core/providers/retry_policy.dart';
import 'package:momeet/features/auth/presentation/pages/account_deletion_pending_page.dart';
import 'package:momeet/features/auth/presentation/pages/consent_page.dart';
import 'package:momeet/features/mypage/presentation/widgets/account_deletion_dialog.dart';
import 'package:momeet/features/timer/presentation/providers/timer_providers.dart';
import 'package:momeet/router.dart';
import 'package:momeet/shared/api/kratos/kratos_client.dart';
import 'package:momeet/shared/api/kratos/kratos_models.dart';
import 'package:momeet/shared/providers/api_providers.dart';

import 'helpers/fake_rest_clients.dart';
import 'helpers/kratos_mocks.dart';

/// 실제 라우터(routerProvider)로 탈퇴 대기 화면을 거치는 흐름을 본다.
///
/// 목적지는 다른 기능의 데이터를 부르지 않는 `/timer/detail`을 쓴다.
void main() {
  late KratosTestHarness harness;
  late FakeUsersClient users;

  setUpAll(() async {
    registerKratosFallbacks();
    await initializeDateFormatting('ko_KR');
  });

  setUp(() async {
    harness = await KratosTestHarness.create();
    users = FakeUsersClient(consentRequired: false, deletionPending: true);
  });

  /// 캘린더처럼 불러오기 표시가 계속 도는 화면에서는 pumpAndSettle 대신 잠깐씩 넘긴다.
  Future<void> pumpAWhile(WidgetTester tester) async {
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  Future<(GoRouter, ProviderContainer)> pumpRouter(
    WidgetTester tester, {
    bool settle = true,
  }) async {
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
    settle ? await tester.pumpAndSettle() : await pumpAWhile(tester);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(Router<Object>)),
    );
    return (container.read(routerProvider), container);
  }

  String location(GoRouter router) =>
      router.routerDelegate.currentConfiguration.uri.toString();

  const destination = '/timer/detail';
  final grace = AppRoute.accountDeletion.path;
  final gated = '$grace?redirect=${Uri.encodeComponent(destination)}';

  Future<void> tapText(WidgetTester tester, String text) async {
    await tester.ensureVisible(find.text(text));
    await tester.tap(find.text(text));
    await tester.pumpAndSettle();
  }

  testWidgets('탈퇴 대기 중이면 연 경로 대신 탈퇴 대기 화면을 보이고, 취소하면 그 경로로 간다', (tester) async {
    final (router, _) = await pumpRouter(tester);
    expect(location(router), grace);

    router.go(destination);
    await tester.pumpAndSettle();
    expect(location(router), gated);
    expect(find.byType(AccountDeletionPendingPage), findsOneWidget);

    await tapText(tester, '탈퇴 취소하고 계속 이용');

    expect(location(router), destination);
    expect(users.deletionCancels, 1);
  });

  testWidgets('약관 동의가 필요해도 탈퇴 대기 화면이 먼저고, 취소하면 동의 화면을 거쳐 그 경로로 간다', (
    tester,
  ) async {
    users = FakeUsersClient(deletionPending: true);
    final (router, _) = await pumpRouter(tester);

    router.go(destination);
    await tester.pumpAndSettle();
    expect(location(router), gated);
    expect(find.byType(ConsentPage), findsNothing);

    await tapText(tester, '탈퇴 취소하고 계속 이용');
    expect(
      location(router),
      '${AppRoute.consent.path}?redirect=${Uri.encodeComponent(destination)}',
    );

    await tapText(tester, '전체 동의');
    await tapText(tester, '동의하고 시작하기');
    expect(location(router), destination);
    expect(users.agreed, hasLength(1));
  });

  testWidgets('로그아웃하면 탈퇴를 취소하지 않고 로그인 화면으로 간다', (tester) async {
    when(() => harness.kratos.logout(any())).thenAnswer((_) async {});
    final (router, _) = await pumpRouter(tester);

    await tapText(tester, '로그아웃');

    expect(router.routerDelegate.currentConfiguration.uri.path, '/login');
    expect(users.deletionCancels, 0);
  });

  testWidgets('다른 곳에서 탈퇴를 신청해 프로필이 바뀌면 탈퇴 대기 화면으로 간다', (tester) async {
    users = FakeUsersClient(consentRequired: false);
    final (router, container) = await pumpRouter(tester, settle: false);
    router.go(destination);
    await pumpAWhile(tester);
    expect(location(router), destination);

    users.profile = FakeUsersClient(
      consentRequired: false,
      deletionPending: true,
    ).profile;
    container.invalidate(myProfileProvider);
    await pumpAWhile(tester);

    expect(location(router), gated);
  });

  testWidgets('프로필을 불러오지 못하면 보호된 경로를 열지 않고, 다시 받으면 탈퇴 대기 화면으로 간다', (
    tester,
  ) async {
    users.readError = httpError('/v1/users/me', 500);
    final (router, container) = await pumpRouter(tester, settle: false);
    router.go(destination);
    await pumpAWhile(tester);
    // 모르는 동안에는 약관 동의 확인이 보호된 경로를 막는다
    expect(
      location(router),
      '${AppRoute.consent.path}?redirect=${Uri.encodeComponent(destination)}',
    );

    users.readError = null;
    container.invalidate(myProfileProvider);
    await pumpAWhile(tester);

    expect(location(router), gated);
  });

  testWidgets('탈퇴를 신청하면 로그인 화면으로 가서 신청했다고 알리고, 다시 로그인하면 탈퇴 대기 화면이다', (
    tester,
  ) async {
    when(() => harness.kratos.logout(any())).thenAnswer((_) async {});
    users = FakeUsersClient(consentRequired: false);
    final (router, container) = await pumpRouter(tester, settle: false);
    router.go(destination);
    await pumpAWhile(tester);

    showAccountDeletionDialog(tester.element(find.byType(Scaffold).last));
    await tester.pumpAndSettle();
    await tapText(tester, '위 내용을 확인했습니다');
    await tapText(tester, '탈퇴 신청');

    expect(router.routerDelegate.currentConfiguration.uri.path, '/login');
    expect(find.byType(AccountDeletionDialog), findsNothing);
    expect(find.textContaining('탈퇴를 신청했습니다'), findsOneWidget);

    harness.stubCreateFlow(KratosFlowType.login, 'f2');
    harness.stubSubmit(
      KratosFlowType.login,
      const KratosSubmitResult(sessionToken: 'ory_st_next'),
    );
    await container
        .read(authProvider.notifier)
        .signInWithEmail(email: testUser.email, password: 'pw');
    await tester.pumpAndSettle();

    expect(location(router), gated);
  });
}
