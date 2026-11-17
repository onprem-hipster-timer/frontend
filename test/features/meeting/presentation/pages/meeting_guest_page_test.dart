import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:momeet/app_route.dart';
import 'package:momeet/core/auth/guest_user.dart';
import 'package:momeet/core/providers/auth_provider.dart';
import 'package:momeet/core/providers/browser_provider.dart';
import 'package:momeet/core/providers/retry_policy.dart';
import 'package:momeet/core/providers/timezone_provider.dart';
import 'package:momeet/core/turnstile/turnstile.dart';
import 'package:momeet/features/meeting/presentation/pages/meeting_page.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_login_panel.dart';
import 'package:momeet/shared/api/kratos/kratos_client.dart';
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
    bool turnstile = true,
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
          if (turnstile)
            turnstiles.override
          else
            turnstileFactoryProvider.overrideWithValue(null),
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

  testWidgets('좁으면 게스트 줄은 격자 앞의 상자 없는 한 줄이고 로그아웃이 그 줄 끝에 있다', (tester) async {
    when(() => harness.kratos.logout(any())).thenAnswer((_) async {});
    await pumpGuest(tester, size: const Size(360, 800));

    final line = find.text('게스트 민수로 진행 중입니다');
    expect(find.ancestor(of: line, matching: find.byType(Card)), findsNothing);
    expect(
      tester.getTopLeft(line).dy,
      lessThan(tester.getTopLeft(find.text('내 시간 선택하기')).dy),
    );
    final signOut = find.text('로그아웃');
    expect(
      (tester.getCenter(signOut).dy - tester.getCenter(line).dy).abs(),
      lessThan(8),
    );

    await tester.tap(signOut);
    await tester.pumpAndSettle();
    expect(find.textContaining('민수'), findsNothing);
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

  testWidgets('확인 위젯이 없는 환경이면 편집과 약관 동의 대신 로그아웃 길만 둔다', (tester) async {
    meetings.participateError = guestError(428, 'ConsentRequiredError');
    await pumpGuest(tester, turnstile: false);

    expect(find.text('동의하고 계속하기'), findsNothing);
    expect(find.text('로그아웃'), findsOneWidget);

    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();
    expect(find.text('게스트 민수로 진행 중입니다'), findsOneWidget);
    expect(find.widgetWithText(TextButton, '편집'), findsNothing);
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

    testWidgets('칠한 것을 저장하다 거절되면(403) 다시 불러와 게스트를 받지 않는다고 보인다', (tester) async {
      await pumpGuest(tester);
      meetings
        ..putError = guestError(403, 'GuestAccessDeniedError')
        ..readError = guestError(403, 'GuestAccessDeniedError');

      await tester.tapAt(cellCenter(tester, '3월 2일 (화) 9:00 ~ 9:30'));
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      expect(find.text('저장하지 못했습니다'), findsNothing);
      expect(find.text('지금은 게스트로 이 모임을 볼 수 없습니다'), findsOneWidget);
    });

    testWidgets('칠한 것을 저장하다 거절됐는데(403) 세션도 끝났으면 게스트가 지워졌다고 알리고 방문자 화면이 된다', (
      tester,
    ) async {
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
      meetings
        ..putError = guestError(403, 'GuestAccessDeniedError')
        ..readError = guestError(403, 'GuestAccessDeniedError');

      await tester.tapAt(cellCenter(tester, '3월 2일 (화) 9:00 ~ 9:30'));
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      expect(find.text('이 모임의 게스트 정보가 지워졌습니다'), findsOneWidget);
      expect(find.byType(MeetingLoginPanel), findsOneWidget);
    });
  });

  group('편집', () {
    Future<void> openEdit(WidgetTester tester) async {
      await tester.tap(find.widgetWithText(TextButton, '편집'));
      await tester.pumpAndSettle();
    }

    Finder nameField() => find.byType(TextFormField);

    /// 게스트 이름 바꾸기가 [name]으로 성공하게 한다. backend처럼 참여자 이름도 바뀐다
    void stubRename(String name) {
      harness.stubCreateFlow(KratosFlowType.settings, 's1');
      when(
        () => harness.kratos.submit(
          KratosFlowType.settings,
          any(),
          any(),
          sessionToken: any(named: 'sessionToken'),
          turnstileToken: any(named: 'turnstileToken'),
        ),
      ).thenAnswer((_) async {
        final at = meetings.availability.indexWhere(
          (e) => e.participant.isGuest,
        );
        meetings.availability[at] = meetings.availability[at].copyWith(
          participant: meetings.availability[at].participant.copyWith(
            displayName: name,
          ),
        );
        harness.stubGuestSession(
          GuestUser(id: testGuest.id, handle: testGuest.handle, name: name),
        );
        return const KratosSubmitResult();
      });
    }

    Future<void> letUndoPass(WidgetTester tester) async {
      await tester.pump(const Duration(seconds: 6));
      await tester.pumpAndSettle();
    }

    testWidgets('이름을 바꾸면 설정 플로우에 새 토큰으로 내고 참여자 이름도 바뀐다', (tester) async {
      final semantics = tester.ensureSemantics();
      stubRename('철수');
      await pumpGuest(tester);
      await openEdit(tester);
      expect(find.widgetWithText(TextFormField, '민수'), findsOneWidget);

      await tester.enterText(nameField(), ' 철수 ');
      await tester.tap(find.text('저장'));
      await tester.pumpAndSettle();

      verify(
        () => harness.kratos.submit(
          KratosFlowType.settings,
          's1',
          {
            'method': 'profile',
            'traits': {'handle': testGuest.handle, 'name': '철수'},
          },
          sessionToken: KratosTestHarness.sessionToken,
          turnstileToken: 'token-1',
        ),
      ).called(1);
      expect(find.text('이름을 바꿨습니다'), findsOneWidget);
      expect(find.bySemanticsLabel('철수, 게스트, 나'), findsOneWidget);
      expect(find.text('게스트 철수로 진행 중입니다'), findsOneWidget);
      expect(turnstiles.last.resets, 1);
      semantics.dispose();
    });

    testWidgets('같은 이름이 있으면 이름 칸에 알리고 다시 보낼 때는 새 토큰이다', (tester) async {
      harness.stubCreateFlow(KratosFlowType.settings, 's1');
      harness.stubSubmitError(
        KratosFlowType.settings,
        const KratosException(statusCode: 409, errorId: 'guest_name_taken'),
      );
      await pumpGuest(tester);
      await openEdit(tester);

      await tester.enterText(nameField(), '서연');
      await tester.tap(find.text('저장'));
      await tester.pumpAndSettle();
      expect(find.text('이 모임에 같은 이름이 있습니다. 다른 이름을 입력해 주세요'), findsOneWidget);

      stubRename('서연2');
      await tester.enterText(nameField(), '서연2');
      await tester.tap(find.text('저장'));
      await tester.pumpAndSettle();
      expect(turnstiles.last.issued, ['token-1', 'token-2']);
      expect(find.text('이름을 바꿨습니다'), findsOneWidget);
    });

    group('들어온 지 오래되어 이름 바꾸기가 거절되면(403 session_refresh_required)', () {
      const refreshed = 'ory_st_refreshed';
      const reason = '들어온 지 오래되어 비밀번호를 한 번 더 확인합니다';

      Finder passwordField() => find.widgetWithText(TextFormField, '비밀번호');

      /// 지금 세션으로는 거절되고, 다시 로그인한 세션으로는 [name]으로 바뀐다.
      /// 로그인은 [passwords] 차례로 답한다: 맞으면 새 세션, 틀리면 비밀번호 오류
      void stubRefresh(String name, {List<bool> passwords = const [true]}) {
        when(() => harness.kratos.logout(any())).thenAnswer((_) async {});
        harness.stubCreateFlow(KratosFlowType.settings, 's1');
        harness.stubCreateFlow(KratosFlowType.login, 'l1');
        var logins = 0;
        when(
          () => harness.kratos.submit(
            KratosFlowType.login,
            any(),
            any(),
            sessionToken: any(named: 'sessionToken'),
            turnstileToken: any(named: 'turnstileToken'),
          ),
        ).thenAnswer((_) async {
          if (!passwords[logins++]) throw kratosError(4000006);
          return const KratosSubmitResult(sessionToken: refreshed);
        });
        when(
          () => harness.kratos.submit(
            KratosFlowType.settings,
            any(),
            any(),
            sessionToken: any(named: 'sessionToken'),
            turnstileToken: any(named: 'turnstileToken'),
          ),
        ).thenAnswer((invocation) async {
          if (invocation.namedArguments[#sessionToken] != refreshed) {
            throw const KratosException(
              statusCode: 403,
              errorId: 'session_refresh_required',
            );
          }
          harness.stubGuestSession(
            GuestUser(id: testGuest.id, handle: testGuest.handle, name: name),
          );
          return const KratosSubmitResult();
        });
      }

      Future<void> renameTo(WidgetTester tester, String name) async {
        await openEdit(tester);
        await tester.enterText(find.byType(TextFormField).first, name);
        await tester.tap(find.text('저장'));
        await tester.pumpAndSettle();
      }

      testWidgets('그 자리에서 비밀번호를 받아 다시 로그인하고 새 세션과 새 토큰으로 이름을 바꾼다', (
        tester,
      ) async {
        stubRefresh('철수');
        await pumpGuest(tester);
        await renameTo(tester, '철수');

        expect(find.text(reason), findsOneWidget);
        expect(passwordField(), findsOneWidget);
        expect(find.widgetWithText(TextFormField, '철수'), findsOneWidget);
        expect(find.text('이름을 바꿨습니다'), findsNothing);

        await tester.enterText(passwordField(), '1234');
        await tester.tap(find.text('저장'));
        await tester.pumpAndSettle();

        verify(
          () => harness.kratos.submit(KratosFlowType.login, 'l1', {
            'method': 'password',
            'identifier': testGuest.handle,
            'password': '1234',
          }, turnstileToken: 'token-2'),
        ).called(1);
        verify(
          () => harness.kratos.submit(
            KratosFlowType.settings,
            's1',
            {
              'method': 'profile',
              'traits': {'handle': testGuest.handle, 'name': '철수'},
            },
            sessionToken: refreshed,
            turnstileToken: 'token-3',
          ),
        ).called(1);
        expect(turnstiles.last.issued, ['token-1', 'token-2', 'token-3']);
        verify(
          () => harness.kratos.logout(KratosTestHarness.sessionToken),
        ).called(1);
        expect(await harness.storedSessionToken(), refreshed);
        expect(find.text('이름을 바꿨습니다'), findsOneWidget);
        expect(find.text('게스트 철수로 진행 중입니다'), findsOneWidget);
        expect(
          container(tester).read(currentGuestProvider)?.meetingId,
          'meeting-1',
        );
      });

      testWidgets('비밀번호가 틀리면 비밀번호 칸에 알리고 바꾸지 않으며, 맞게 다시 내면 바꾼다', (
        tester,
      ) async {
        stubRefresh('철수', passwords: [false, true]);
        await pumpGuest(tester);
        await renameTo(tester, '철수');

        await tester.enterText(passwordField(), 'wrong');
        await tester.tap(find.text('저장'));
        await tester.pumpAndSettle();

        expect(find.text('비밀번호가 맞지 않습니다'), findsOneWidget);
        expect(find.widgetWithText(TextFormField, '철수'), findsOneWidget);
        verifyNever(
          () => harness.kratos.submit(
            KratosFlowType.settings,
            any(),
            any(),
            sessionToken: refreshed,
            turnstileToken: any(named: 'turnstileToken'),
          ),
        );
        verifyNever(() => harness.kratos.logout(any()));
        expect(
          await harness.storedSessionToken(),
          KratosTestHarness.sessionToken,
        );

        await tester.enterText(passwordField(), '1234');
        await tester.tap(find.text('저장'));
        await tester.pumpAndSettle();

        expect(turnstiles.last.issued, [
          'token-1',
          'token-2',
          'token-3',
          'token-4',
        ]);
        expect(find.text('이름을 바꿨습니다'), findsOneWidget);
        expect(await harness.storedSessionToken(), refreshed);
      });

      testWidgets('비워 두고 저장하면 보내지 않고 비밀번호를 입력하라고 한다', (tester) async {
        stubRefresh('철수');
        await pumpGuest(tester);
        await renameTo(tester, '철수');

        await tester.tap(find.text('저장'));
        await tester.pumpAndSettle();

        expect(find.text('비밀번호를 입력해 주세요'), findsOneWidget);
        expect(turnstiles.last.issued, ['token-1']);
      });

      testWidgets('다시 로그인한 뒤 같은 이름이 있으면 이름 칸에 알리고 비밀번호는 다시 묻지 않는다', (
        tester,
      ) async {
        stubRefresh('철수');
        await pumpGuest(tester);
        await renameTo(tester, '서연');
        when(
          () => harness.kratos.submit(
            KratosFlowType.settings,
            any(),
            any(),
            sessionToken: refreshed,
            turnstileToken: any(named: 'turnstileToken'),
          ),
        ).thenThrow(
          const KratosException(statusCode: 409, errorId: 'guest_name_taken'),
        );

        await tester.enterText(passwordField(), '1234');
        await tester.tap(find.text('저장'));
        await tester.pumpAndSettle();

        expect(find.text('이 모임에 같은 이름이 있습니다. 다른 이름을 입력해 주세요'), findsOneWidget);
        expect(passwordField(), findsNothing);
        expect(find.text(reason), findsNothing);
        expect(await harness.storedSessionToken(), refreshed);
      });
    });

    testWidgets('이름을 그대로 두고 저장하면 보내지 않고 닫는다', (tester) async {
      await pumpGuest(tester);
      await openEdit(tester);

      await tester.tap(find.text('저장'));
      await tester.pumpAndSettle();

      expect(nameField(), findsNothing);
      expect(turnstiles.last.issued, isEmpty);
    });

    testWidgets('지우면 바로 방문자 화면이 되고 되돌리면 게스트 화면으로 돌아와 보내지 않는다', (tester) async {
      await pumpGuest(tester);
      await openEdit(tester);

      await tester.tap(find.text('게스트 계정 지우기'));
      await tester.pumpAndSettle();
      expect(find.text('게스트 계정을 지웠습니다'), findsOneWidget);
      expect(find.byType(MeetingLoginPanel), findsOneWidget);

      await tester.tap(find.text('되돌리기'));
      await tester.pumpAndSettle();
      await letUndoPass(tester);

      expect(guests.deletes, isEmpty);
      expect(find.text('게스트 민수로 진행 중입니다'), findsOneWidget);
      expect(container(tester).read(currentGuestProvider), isNotNull);
    });

    testWidgets('알림이 되돌리기 없이 닫히면 시트에서 받은 토큰으로 지우고 세션을 끝낸다', (tester) async {
      when(() => harness.kratos.logout(any())).thenAnswer((_) async {});
      await pumpGuest(tester);
      await openEdit(tester);

      await tester.tap(find.text('게스트 계정 지우기'));
      await tester.pumpAndSettle();
      expect(guests.deletes, isEmpty);
      await letUndoPass(tester);

      expect(guests.deletes, ['token-1']);
      verify(
        () => harness.kratos.logout(KratosTestHarness.sessionToken),
      ).called(1);
      expect(await harness.storedSessionToken(), isNull);
      expect(find.byType(MeetingLoginPanel), findsOneWidget);
    });

    testWidgets('지우지 못하면 게스트 화면으로 돌아오고 알린다', (tester) async {
      guests.deleteError = guestError(403, 'GuestVerificationFailedError');
      await pumpGuest(tester);
      await openEdit(tester);

      await tester.tap(find.text('게스트 계정 지우기'));
      await tester.pumpAndSettle();
      await letUndoPass(tester);

      expect(guests.deletes, ['token-1']);
      expect(
        find.text('게스트 계정을 지우지 못했습니다: 사람인지 확인하지 못했습니다. 다시 시도해 주세요'),
        findsOneWidget,
      );
      expect(find.text('게스트 민수로 진행 중입니다'), findsOneWidget);
      expect(container(tester).read(currentGuestProvider), isNotNull);
    });
  });
}
