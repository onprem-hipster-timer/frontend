import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:momeet/core/analytics/analytics_consent.dart';
import 'package:momeet/core/providers/auth_provider.dart';
import 'package:momeet/core/providers/browser_provider.dart';
import 'package:momeet/core/providers/retry_policy.dart';
import 'package:momeet/core/providers/timezone_provider.dart';
import 'package:momeet/features/meeting/presentation/pages/meeting_create_page.dart';
import 'package:momeet/features/meeting/presentation/pages/meeting_created_page.dart';
import 'package:momeet/features/meeting/presentation/pages/meeting_edit_page.dart';
import 'package:momeet/features/meeting/presentation/pages/meeting_page.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_visitor_body.dart';
import 'package:momeet/features/timer/presentation/providers/timer_providers.dart';
import 'package:momeet/router.dart';
import 'package:momeet/shared/api/kratos/kratos_client.dart';
import 'package:momeet/shared/api/kratos/kratos_models.dart';
import 'package:momeet/shared/providers/api_providers.dart';
import 'package:momeet/shared/widgets/scaffold_with_nav.dart';
import 'package:timezone/data/latest.dart' as tz;

import '../../helpers/fake_rest_clients.dart';
import '../../helpers/kratos_mocks.dart';
import 'meeting_fixtures.dart';

/// 실제 라우터(routerProvider)로 모임 만들기·만든 뒤·모임 화면의 주소를 연다.
void main() {
  late KratosTestHarness harness;
  late FakeMeetingsClient meetings;

  setUpAll(() async {
    registerKratosFallbacks();
    tz.initializeTimeZones();
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

  Future<GoRouter> pumpRouter(
    WidgetTester tester, {
    String? browserRoute,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        retry: appRetry,
        overrides: [
          ...harness.overrides,
          if (browserRoute != null)
            browserRouteProvider.overrideWithValue(browserRoute),
          usersApiProvider.overrideWithValue(
            FakeUsersClient(consentRequired: false),
          ),
          meetingsApiProvider.overrideWithValue(meetings),
          visibilityApiProvider.overrideWithValue(FakeVisibilityClient()),
          timezoneProvider.overrideWith(() => FixedTimezone('Asia/Seoul')),
          appOriginProvider.overrideWithValue('https://app.example.com'),
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

  testWidgets('로그인한 회원이 새 탭에서 모임 링크를 열면 세션을 확인한 뒤에도 그 모임에 머문다', (tester) async {
    tester.binding.platformDispatcher.defaultRouteNameTestValue =
        '/meetings/meeting-1';
    addTearDown(
      tester.binding.platformDispatcher.clearDefaultRouteNameTestValue,
    );
    final whoami = Completer<void>();
    when(() => harness.kratos.whoami(any())).thenAnswer((_) async {
      await whoami.future;
      return KratosSession(user: testUser, accessToken: harness.accessToken);
    });
    final router = await pumpRouter(tester);
    expect(location(router), startsWith(AppRoute.loading.path));

    whoami.complete();
    await pumpAWhile(tester);

    expect(location(router), '/meetings/meeting-1');
    expect(find.byType(MeetingPage), findsOneWidget);
    expect(meetings.reads, ['meeting-1']);
  });

  testWidgets('세션 확인이 바로 끝나도 로딩 화면에 남지 않고 연 주소로 간다', (tester) async {
    tester.binding.platformDispatcher.defaultRouteNameTestValue =
        '/meetings/meeting-1';
    addTearDown(
      tester.binding.platformDispatcher.clearDefaultRouteNameTestValue,
    );
    final router = await pumpRouter(tester);

    expect(location(router), '/meetings/meeting-1');
  });

  testWidgets('로그인하지 않았으면 로그인으로 보내지 않고 공개 모임의 방문자 화면을 연다', (tester) async {
    harness = await KratosTestHarness.create(authenticated: false);
    harness.stubCreateFlow(KratosFlowType.login, 'flow-login');
    final router = await pumpRouter(tester);

    router.go('/meetings/meeting-1');
    await pumpAWhile(tester);

    expect(location(router), '/meetings/meeting-1');
    expect(find.byType(MeetingPage), findsOneWidget);
    expect(find.text('팀 회의'), findsOneWidget);
    expect(find.byType(MeetingVisitorBody), findsOneWidget);
    expect(meetings.resultReads, 1);
    expect(meetings.reads, isEmpty);

    await tester.tap(find.widgetWithText(FilledButton, '내 시간 입력하기'));
    await pumpAWhile(tester);
    await tester.tap(find.widgetWithText(FilledButton, '로그인'));
    await pumpAWhile(tester);
    expect(
      location(router),
      '${AppRoute.login.path}?redirect=${Uri.encodeComponent('/meetings/meeting-1')}',
    );
  });

  testWidgets('모임 설정 주소는 탭 셸 밖에서 주인의 설정 화면을 연다', (tester) async {
    meetings.meeting = makeMeeting(ownerId: testUser.id);
    final router = await pumpRouter(tester);

    router.go('/meetings/meeting-1/edit');
    await pumpAWhile(tester);

    expect(location(router), '/meetings/meeting-1/edit');
    expect(find.byType(MeetingEditPage), findsOneWidget);
    expect(find.text('저장하기'), findsOneWidget);
    expect(find.byType(ScaffoldWithNavBar), findsNothing);
  });

  testWidgets('로그인하지 않았으면 모임 설정 화면은 로그인으로 보낸다', (tester) async {
    harness = await KratosTestHarness.create(authenticated: false);
    harness.stubCreateFlow(KratosFlowType.login, 'flow-login');
    final router = await pumpRouter(tester);

    router.go('/meetings/meeting-1/edit');
    await pumpAWhile(tester);

    expect(
      location(router),
      '${AppRoute.login.path}?redirect=${Uri.encodeComponent('/meetings/meeting-1/edit')}',
    );
  });

  testWidgets('로그인하지 않았으면 모임을 만든 뒤 화면은 로그인으로 보낸다', (tester) async {
    harness = await KratosTestHarness.create(authenticated: false);
    harness.stubCreateFlow(KratosFlowType.login, 'flow-login');
    final router = await pumpRouter(tester);

    router.go('/meetings/meeting-1/created');
    await pumpAWhile(tester);

    expect(
      location(router),
      '${AppRoute.login.path}?redirect=${Uri.encodeComponent('/meetings/meeting-1/created')}',
    );
  });

  testWidgets('모임 화면에서 세션이 끝나면 그 자리에서 방문자 화면으로 바뀐다', (tester) async {
    final router = await pumpRouter(tester);
    router.go('/meetings/meeting-1');
    await pumpAWhile(tester);
    expect(find.text('내 시간 선택하기'), findsOneWidget);
    expect(find.byType(MeetingVisitorBody), findsNothing);

    when(() => harness.kratos.whoami(any())).thenAnswer((_) async => null);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(MeetingPage)),
    );
    await tester.runAsync(
      () => container.read(authProvider.notifier).refreshAccessToken(),
    );
    await pumpAWhile(tester);

    expect(location(router), '/meetings/meeting-1');
    expect(find.byType(MeetingVisitorBody), findsOneWidget);
    expect(meetings.resultReads, 1);
  });

  group('계정이 바뀌어 라우터를 새로 만들 때(로그아웃, 게스트 삭제)', () {
    setUp(() async {
      harness = await KratosTestHarness.create(authenticated: false);
      harness.stubCreateFlow(KratosFlowType.login, 'flow-login');
    });

    testWidgets('브라우저가 모임 화면에 있었으면 그 모임의 방문자 화면에서 이어 간다', (tester) async {
      final router = await pumpRouter(
        tester,
        browserRoute: '/meetings/meeting-1',
      );

      expect(location(router), '/meetings/meeting-1');
      expect(find.byType(MeetingVisitorBody), findsOneWidget);
    });

    testWidgets('로그인 화면에 있었으면 돌아갈 곳을 담은 그 로그인 화면에서 이어 간다', (tester) async {
      final login =
          '${AppRoute.login.path}?redirect=${Uri.encodeComponent('/meetings/meeting-1')}';
      final router = await pumpRouter(tester, browserRoute: login);

      expect(location(router), login);
    });

    testWidgets('로그인해야 보는 화면에 있었으면 처음 화면으로 간다', (tester) async {
      final router = await pumpRouter(tester, browserRoute: AppRoute.todo.path);

      expect(location(router), AppRoute.landing.path);
    });
  });

  group('게스트 세션', () {
    setUp(() async {
      harness.stubGuestSession();
      await harness.prefs.setString(guestMeetingKey, 'guest-uid meeting-1');
    });

    testWidgets('게스트 세션을 되살리면 처음 화면 대신 자기 모임으로 간다', (tester) async {
      final router = await pumpRouter(tester);

      expect(location(router), '/meetings/meeting-1');
      expect(find.byType(MeetingPage), findsOneWidget);
    });

    testWidgets('게스트가 회원 화면으로 가면 로그인이 필요하다고 하고 모임으로 돌아간다', (tester) async {
      final router = await pumpRouter(tester);

      router.go(AppRoute.todo.path);
      await pumpAWhile(tester);

      expect(
        location(router),
        '${AppRoute.guestSession.path}?redirect=${Uri.encodeComponent(AppRoute.todo.path)}',
      );
      expect(find.text('로그인이 필요합니다'), findsOneWidget);
      expect(find.text('(게스트 세션에서는 해당 기능을 이용할 수 없습니다.)'), findsOneWidget);
      expect(find.byType(ScaffoldWithNavBar), findsNothing);

      await tester.tap(find.text('모임으로 돌아가기'));
      await pumpAWhile(tester);
      expect(location(router), '/meetings/meeting-1');
    });

    testWidgets('게스트가 다른 모임의 링크를 열면 그 모임을 부르지 않고 안내를 보인다', (tester) async {
      final router = await pumpRouter(tester);
      meetings.reads.clear();
      final results = meetings.resultReads;

      router.go('/meetings/meeting-2');
      await pumpAWhile(tester);

      expect(location(router), startsWith(AppRoute.guestSession.path));
      expect(find.text('로그인이 필요합니다'), findsOneWidget);
      expect(meetings.reads, isEmpty);
      expect(meetings.resultReads, results);
    });

    testWidgets('안내의 회원으로 로그인은 가려던 곳을 붙여 로그인 화면으로 간다', (tester) async {
      harness.stubCreateFlow(KratosFlowType.login, 'flow-login');
      final router = await pumpRouter(tester);
      router.go(AppRoute.mypage.path);
      await pumpAWhile(tester);

      await tester.tap(find.text('회원으로 로그인'));
      await pumpAWhile(tester);

      expect(
        location(router),
        '${AppRoute.login.path}?redirect=${Uri.encodeComponent(AppRoute.mypage.path)}',
      );
    });

    testWidgets('들어온 모임을 모르면 안내에서 게스트 세션을 끝낸다', (tester) async {
      await harness.prefs.remove(guestMeetingKey);
      when(() => harness.kratos.logout(any())).thenAnswer((_) async {});
      final router = await pumpRouter(tester);
      expect(location(router), AppRoute.guestSession.path);
      expect(find.text('모임으로 돌아가기'), findsNothing);

      await tester.tap(find.text('게스트 세션 끝내기'));
      await pumpAWhile(tester);

      verify(
        () => harness.kratos.logout(KratosTestHarness.sessionToken),
      ).called(1);
      expect(location(router), AppRoute.landing.path);
    });
  });

  testWidgets('하단 바에 모임 탭이 없고, 만들기 화면은 탭 셸 밖에서 홈으로 가는 서비스 배지와 함께 열린다', (
    tester,
  ) async {
    final router = await pumpRouter(tester);
    expect(find.byType(ScaffoldWithNavBar), findsOneWidget);
    // 달력 앱바의 '모임 만들기'는 탭이 아니다
    expect(find.bySemanticsLabel(RegExp('^모임(?! 만들기)')), findsNothing);

    router.go(AppRoute.meetings.path);
    await pumpAWhile(tester);

    expect(location(router), AppRoute.meetings.path);
    expect(find.byType(MeetingCreatePage), findsOneWidget);
    expect(find.byType(ScaffoldWithNavBar), findsNothing);

    await tester.tap(find.byTooltip('홈으로'));
    await pumpAWhile(tester);
    expect(location(router), AppRoute.calendar.path);
  });

  testWidgets('만든 뒤 화면은 모임 번호를 담은 주소로 탭 셸 밖에 열린다', (tester) async {
    final router = await pumpRouter(tester);

    router.go('/meetings/meeting-1/created');
    await pumpAWhile(tester);

    expect(find.byType(MeetingCreatedPage), findsOneWidget);
    expect(find.byType(MeetingPage), findsNothing);
    expect(find.byType(ScaffoldWithNavBar), findsNothing);
    expect(find.byTooltip('홈으로'), findsOneWidget);

    await tester.tap(find.text('나의 일정 입력'));
    await pumpAWhile(tester);
    expect(location(router), '/meetings/meeting-1');
    expect(find.byType(MeetingPage), findsOneWidget);
  });

  group('로그인하지 않은 사람의 모임 만들기', () {
    setUp(() async {
      harness = await KratosTestHarness.create(authenticated: false);
      harness.stubCreateFlow(KratosFlowType.login, 'flow-login');
    });

    testWidgets('/meetings는 로그인으로 보내지 않고 만들기 화면을 연다', (tester) async {
      final router = await pumpRouter(tester);

      router.go(AppRoute.meetings.path);
      await pumpAWhile(tester);

      expect(location(router), AppRoute.meetings.path);
      expect(find.byType(MeetingCreatePage), findsOneWidget);
    });

    testWidgets('로그인하고 계속하기로 로그인하면 만들기 화면으로 돌아와 답한 그대로이고 화살표 한 번으로 만든다', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(480, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final router = await pumpRouter(tester);
      router.go(AppRoute.meetings.path);
      await pumpAWhile(tester);
      await tester.tap(find.byTooltip('다음 달'));
      await pumpAWhile(tester);
      final now = DateTime.now();
      final day = DateTime.utc(now.year, now.month + 1, 3);
      // 하루를 고르고(같은 날 두 번) 날짜별·비공개(나만 보기)로 답해 제목까지 간다
      for (var i = 0; i < 2; i++) {
        await tester.tap(
          find.bySemanticsLabel(RegExp('^${day.month}월 ${day.day}일')),
        );
        await pumpAWhile(tester);
      }
      for (final answer in ['날짜별', '비공개', '지금은 나만 볼게요']) {
        await tester.tap(find.text(answer).last);
        await pumpAWhile(tester);
      }
      await tester.enterText(find.byType(TextField), '스터디');
      await tester.tap(find.byTooltip('모임 만들기'));
      await pumpAWhile(tester);
      expect(meetings.created, isEmpty);

      await tester.tap(find.widgetWithText(FilledButton, '로그인하고 계속하기'));
      await pumpAWhile(tester);
      expect(
        location(router),
        '${AppRoute.login.path}?redirect=${Uri.encodeComponent(AppRoute.meetings.path)}',
      );

      harness.stubSubmit(
        KratosFlowType.login,
        const KratosSubmitResult(sessionToken: KratosTestHarness.sessionToken),
      );
      final container = ProviderScope.containerOf(
        tester.element(find.byType(Router<Object>)),
      );
      await tester.runAsync(
        () => container
            .read(authProvider.notifier)
            .signInWithEmail(email: 'user@example.com', password: 'pw'),
      );
      await pumpAWhile(tester);

      expect(location(router), AppRoute.meetings.path);
      expect(find.text('스터디'), findsOneWidget);

      await tester.tap(find.byTooltip('모임 만들기'));
      await pumpAWhile(tester);

      expect(meetings.created.single.title, '스터디');
      expect(meetings.created.single.startDate, day);
      expect(location(router), '/meetings/meeting-new-1/created');
    });

    testWidgets('게스트는 모임 만들기 화면에 머문다', (tester) async {
      harness = await KratosTestHarness.create();
      harness.stubGuestSession();
      await harness.prefs.setString(guestMeetingKey, 'guest-uid meeting-1');
      final router = await pumpRouter(tester);

      router.go(AppRoute.meetings.path);
      await pumpAWhile(tester);

      expect(location(router), AppRoute.meetings.path);
      expect(find.byType(MeetingCreatePage), findsOneWidget);
      expect(find.text('로그인이 필요합니다'), findsNothing);
    });
  });
}
