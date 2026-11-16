import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:momeet/app_route.dart';
import 'package:momeet/core/providers/auth_provider.dart';
import 'package:momeet/core/providers/browser_provider.dart';
import 'package:momeet/core/providers/retry_policy.dart';
import 'package:momeet/core/providers/timezone_provider.dart';
import 'package:momeet/features/meeting/presentation/pages/meeting_page.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_login_panel.dart';
import 'package:momeet/shared/api/kratos/kratos_models.dart';
import 'package:momeet/shared/providers/api_providers.dart';
import 'package:timezone/data/latest.dart' as tz;

import '../../../../helpers/fake_rest_clients.dart';
import '../../../../helpers/fake_turnstile.dart';
import '../../../../helpers/kratos_mocks.dart';
import '../../guest_fixtures.dart';
import '../../meeting_fixtures.dart';
import '../../meeting_grid_finders.dart';

/// 서울 2027년 3월 [day]일 [hour]시의 UTC 시각
DateTime seoul(int day, int hour) => DateTime.utc(2027, 3, day, hour - 9);

/// 모임 meeting-1의 게스트(민수)가 자기 모임 화면을 연다
void main() {
  late KratosTestHarness harness;
  late FakeMeetingsClient meetings;
  late FakeGuestsClient guests;
  late FakeUsersClient users;
  late FakeTurnstiles turnstiles;

  setUpAll(() async {
    registerKratosFallbacks();
    tz.initializeTimeZones();
    await initializeDateFormatting('ko');
  });

  setUp(() async {
    harness = await KratosTestHarness.create();
    harness.stubGuestSession();
    await harness.prefs.setString(guestMeetingKey, 'guest-uid meeting-1');
    meetings =
        FakeMeetingsClient(meeting: makeMeeting().copyWith(allowGuests: true))
          ..guestName = '민수'
          ..availability = [
            availabilityOf(
              'owner',
              name: '지현',
              owner: true,
              slots: [(seoul(1, 9), seoul(1, 12))],
            ),
            availabilityOf(
              'b',
              name: '서연',
              slots: [(seoul(1, 9), seoul(1, 11))],
            ),
          ];
    guests = FakeGuestsClient()..guests['민수'] = testGuest.handle;
    users = FakeUsersClient(consentRequired: false);
    turnstiles = FakeTurnstiles();
  });

  Future<void> pumpGuest(
    WidgetTester tester, {
    Size size = const Size(1280, 900),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final router = GoRouter(
      initialLocation: '/meetings/meeting-1',
      routes: [
        GoRoute(
          path: AppRoute.login.path,
          name: AppRoute.login.name,
          builder: (context, state) => const Text('로그인 화면'),
        ),
        GoRoute(
          path: AppRoute.meeting.path,
          name: AppRoute.meeting.name,
          builder: (context, state) =>
              MeetingPage(meetingId: state.pathParameters['meetingId']!),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        retry: appRetry,
        overrides: [
          ...harness.overrides,
          meetingsApiProvider.overrideWithValue(meetings),
          visibilityApiProvider.overrideWithValue(FakeVisibilityClient()),
          guestsApiProvider.overrideWithValue(guests),
          usersApiProvider.overrideWithValue(users),
          timezoneProvider.overrideWith(() => FixedTimezone('Asia/Seoul')),
          appOriginProvider.overrideWithValue('https://app.example.com'),
          turnstiles.override,
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  ProviderContainer container(WidgetTester tester) =>
      ProviderScope.containerOf(tester.element(find.byType(MeetingPage)));

  testWidgets('처음 그릴 때 게스트 이름으로 한 번 참여하고 회원처럼 격자·참여자·선택된 일정을 보인다', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pumpGuest(tester);

    expect(meetings.participations, ['민수']);
    expect(meetings.reads, ['meeting-1']);
    expect(find.widgetWithText(AppBar, '팀 회의'), findsOneWidget);
    expect(find.bySemanticsLabel('민수, 게스트, 나'), findsOneWidget);
    expect(find.bySemanticsLabel('지현, 주인'), findsOneWidget);
    expect(find.text('선택된 일정'), findsOneWidget);
    expect(find.text('게스트 민수로 진행 중입니다'), findsOneWidget);
    expect(find.byType(MeetingLoginPanel), findsNothing);
    expect(users.reads, 0, reason: '회원 경로는 부르지 않는다');
    semantics.dispose();
  });

  testWidgets('선택된 일정 카드에 내 달력에 일정 만들기가 없다', (tester) async {
    await pumpGuest(tester);

    expect(find.text('3월 1일 (월)'), findsWidgets);
    expect(find.byTooltip('내 달력에 일정 만들기'), findsNothing);
  });

  testWidgets('칠하면 참여해 받은 내 참여자로 저장한다', (tester) async {
    await pumpGuest(tester);

    await tester.tapAt(cellCenter(tester, '3월 2일 (화) 9:00 ~ 9:30'));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(meetings.participations, ['민수'], reason: '다시 참여하지 않는다');
    final (participantId, slots) = meetings.puts.single;
    expect(participantId, 'participant-guest');
    expect(slots.single.startTime, seoul(2, 9));
    expect(find.text('저장됨'), findsOneWidget);
  });

  testWidgets('이미 참여한 게스트가 다시 열면 그 참여자를 그대로 쓴다', (tester) async {
    meetings.availability.add(
      availabilityOf(
        'participant-guest',
        name: '민수',
        guest: true,
        slots: [(seoul(1, 9), seoul(1, 10))],
      ),
    );
    await pumpGuest(tester);

    expect(
      meetings.availability.where((e) => e.participant.isGuest),
      hasLength(1),
    );
    expect(cellData('3월 1일 (월) 9:00 ~ 9:30').value, contains('내 시간'));
  });

  testWidgets('로그아웃하면 세션을 끝내고 방문자 화면으로 바뀐다', (tester) async {
    when(() => harness.kratos.logout(any())).thenAnswer((_) async {});
    await pumpGuest(tester);

    await tester.tap(find.text('로그아웃'));
    await tester.pumpAndSettle();

    verify(
      () => harness.kratos.logout(KratosTestHarness.sessionToken),
    ).called(1);
    expect(find.byType(MeetingLoginPanel), findsOneWidget);
    expect(find.textContaining('민수'), findsNothing);
  });

  testWidgets('보는 중에 게스트 세션이 끝나면 그 자리에서 방문자 화면으로 바뀐다', (tester) async {
    await pumpGuest(tester);
    when(() => harness.kratos.whoami(any())).thenAnswer((_) async => null);

    await tester.runAsync(
      () => container(tester).read(authProvider.notifier).refreshAccessToken(),
    );
    await tester.pumpAndSettle();

    expect(find.byType(MeetingLoginPanel), findsOneWidget);
    expect(find.text('3명 참여 중'), findsOneWidget);
  });

  group('거절', () {
    testWidgets('약관이 바뀌었으면(428) 다시 동의를 받고 이어서 불러온다', (tester) async {
      meetings.participateError = guestError(428, 'ConsentRequiredError');
      guests.consentVersion = '2026-12-01';
      await pumpGuest(tester);

      expect(find.text('약관이 바뀌었습니다. 계속하려면 다시 동의해 주세요.'), findsOneWidget);
      final agree = find.widgetWithText(FilledButton, '동의하고 계속하기');
      expect(tester.widget<FilledButton>(agree).onPressed, isNull);

      await tester.tap(find.text('전체 동의'));
      await tester.pumpAndSettle();
      await tester.tap(agree);
      await tester.pumpAndSettle();

      expect(guests.lookups, [('민수', 'token-1')]);
      final (consent, token) = guests.consents.single;
      expect(token, isNull, reason: '동의 기록에는 토큰을 담지 않는다');
      expect(consent.version, '2026-12-01');
      expect(meetings.participations, ['민수', '민수']);
      expect(find.text('게스트 민수로 진행 중입니다'), findsOneWidget);
    });

    testWidgets('동의하는 사이 약관이 또 바뀌면 알리고 체크를 지운다', (tester) async {
      meetings.participateError = guestError(428, 'ConsentRequiredError');
      guests.consentError = guestError(409, 'ConsentVersionMismatchError');
      await pumpGuest(tester);
      await tester.tap(find.text('전체 동의'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, '동의하고 계속하기'));
      await tester.pumpAndSettle();

      expect(find.text('약관이 바뀌었습니다. 바뀐 내용을 확인하고 다시 동의해 주세요'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, '동의하고 계속하기'),
            )
            .onPressed,
        isNull,
      );
    });

    testWidgets('동의하지 않으면 로그아웃해 방문자 화면이 된다', (tester) async {
      when(() => harness.kratos.logout(any())).thenAnswer((_) async {});
      meetings.participateError = guestError(428, 'ConsentRequiredError');
      await pumpGuest(tester);

      await tester.tap(find.text('동의하지 않고 로그아웃'));
      await tester.pumpAndSettle();

      expect(find.byType(MeetingLoginPanel), findsOneWidget);
      expect(guests.consents, isEmpty);
    });

    testWidgets('거절됐는데(403) 세션이 남았으면 지금은 게스트로 볼 수 없다고 하고 다시 시도한다', (
      tester,
    ) async {
      meetings.readError = guestError(403, 'GuestAccessDeniedError');
      await pumpGuest(tester);

      expect(find.text('지금은 게스트로 이 모임을 볼 수 없습니다'), findsOneWidget);
      expect(find.textContaining('다시 열리면 남긴 시간 그대로'), findsOneWidget);
      expect(container(tester).read(currentGuestProvider), isNotNull);

      meetings.readError = null;
      await tester.tap(find.text('다시 시도'));
      await tester.pumpAndSettle();
      expect(find.text('게스트 민수로 진행 중입니다'), findsOneWidget);
    });

    testWidgets('거절됐는데(403) 세션도 끝났으면 게스트가 지워졌다고 알리고 방문자 화면이 된다', (
      tester,
    ) async {
      meetings.readError = guestError(403, 'GuestAccessDeniedError');
      // 처음 세션을 되살릴 때만 게스트이고, 다시 확인하면 끝났다
      var first = true;
      when(() => harness.kratos.whoami(any())).thenAnswer((_) async {
        if (!first) return null;
        first = false;
        return KratosSession.guest(
          guest: testGuest,
          accessToken: harness.accessToken,
        );
      });
      await pumpGuest(tester);

      expect(find.text('이 모임의 게스트 정보가 지워졌습니다'), findsOneWidget);
      expect(find.byType(MeetingLoginPanel), findsOneWidget);
      expect(await harness.storedSessionToken(), isNull);
      expect(harness.prefs.getString(guestMeetingKey), isNull);
    });
  });
}
