import 'dart:async';

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

/// 로그인하지 않은 방문자가 모임 화면의 로그인 상자에서 게스트로 들어간다
void main() {
  late KratosTestHarness harness;
  late FakeMeetingsClient meetings;
  late FakeGuestsClient guests;
  late FakeTurnstiles turnstiles;

  setUpAll(() async {
    registerKratosFallbacks();
    tz.initializeTimeZones();
    await initializeDateFormatting('ko');
  });

  setUp(() async {
    harness = await KratosTestHarness.create(authenticated: false);
    harness.stubCreateFlow(KratosFlowType.login, 'flow-guest');
    harness.stubSubmit(
      KratosFlowType.login,
      const KratosSubmitResult(sessionToken: 'ory_st_guest'),
    );
    harness.stubGuestSession();
    meetings = FakeMeetingsClient(
      meeting: makeMeeting().copyWith(allowGuests: true),
    );
    guests = FakeGuestsClient();
    turnstiles = FakeTurnstiles();
  });

  Future<void> pumpVisitor(
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

  Finder guestButton() => find.descendant(
    of: find.byType(MeetingLoginPanel),
    matching: find.widgetWithText(FilledButton, 'Guest'),
  );
  Finder nameField() => find.widgetWithText(TextFormField, '이름');
  Finder passwordField() => find.widgetWithText(TextFormField, '비밀번호');
  Finder submit(String label) => find.widgetWithText(FilledButton, label);

  Future<void> openGuest(WidgetTester tester) async {
    await tester.tap(guestButton());
    await tester.pumpAndSettle();
  }

  /// 이름을 넣고 비밀번호 칸으로 옮겨 이름 칸을 벗어난다
  Future<void> enterName(WidgetTester tester, String name) async {
    await tester.enterText(nameField(), name);
    await tester.pump();
    await tester.tap(passwordField());
    await tester.pumpAndSettle();
  }

  Future<void> agreeAll(WidgetTester tester) async {
    await tester.ensureVisible(find.text('전체 동의'));
    await tester.tap(find.text('전체 동의'));
    await tester.pumpAndSettle();
  }

  Future<void> press(WidgetTester tester, String label) async {
    await tester.ensureVisible(submit(label));
    await tester.tap(submit(label));
    await tester.pumpAndSettle();
  }

  void verifyGuestLogin({required String handle, required String token}) {
    verify(
      () => harness.kratos.submit(KratosFlowType.login, 'flow-guest', {
        'method': 'password',
        'identifier': handle,
        'password': '1234',
      }, turnstileToken: token),
    ).called(1);
  }

  group('로그인 상자', () {
    testWidgets('게스트를 받는 모임이면 로그인 옆에 Guest가 있다', (tester) async {
      await pumpVisitor(tester);

      expect(
        find.descendant(
          of: find.byType(MeetingLoginPanel),
          matching: find.widgetWithText(FilledButton, '로그인'),
        ),
        findsOneWidget,
      );
      expect(guestButton(), findsOneWidget);
      expect(nameField(), findsNothing);
    });

    testWidgets('게스트를 받지 않는 모임이면 Guest가 없다', (tester) async {
      meetings.meeting = makeMeeting();
      await pumpVisitor(tester);

      expect(guestButton(), findsNothing);
    });

    testWidgets('확인 위젯이 없는 환경(웹이 아님)이면 Guest가 없다', (tester) async {
      await pumpVisitor(tester, turnstile: false);

      expect(guestButton(), findsNothing);
    });

    testWidgets('Guest는 그 자리에서 게스트 폼을 열고 닫기로 단추로 돌아간다', (tester) async {
      await pumpVisitor(tester);

      await openGuest(tester);
      expect(find.text('게스트로 참여'), findsOneWidget);
      expect(nameField(), findsOneWidget);
      expect(passwordField(), findsOneWidget);
      expect(find.bySemanticsLabel('사람인지 확인하는 상자'), findsOneWidget);
      expect(find.text('전체 동의'), findsNothing, reason: '이름을 찾기 전');

      await tester.tap(find.byTooltip('닫기'));
      await tester.pumpAndSettle();
      expect(nameField(), findsNothing);
      expect(guestButton(), findsOneWidget);
      expect(turnstiles.last.disposed, isTrue);
    });
  });

  group('처음 쓰는 이름', () {
    testWidgets('이름을 찾고 동의를 받아 만든 뒤 로그인한다. 단계마다 새 토큰을 쓴다', (tester) async {
      await pumpVisitor(tester);
      await openGuest(tester);

      await enterName(tester, '  민수  ');
      expect(guests.lookups, [('민수', 'token-1')]);
      expect(
        find.text('비밀번호는 바꾸거나 찾을 수 없습니다. 잊으면 이 이름으로 다시 들어올 수 없습니다.'),
        findsOneWidget,
      );
      expect(tester.widget<FilledButton>(submit('참여하기')).onPressed, isNull);

      await agreeAll(tester);
      await tester.enterText(passwordField(), '1234');
      await press(tester, '참여하기');

      final (created, createToken) = guests.creates.single;
      expect(createToken, 'token-2');
      expect(created.name, '민수');
      expect(created.password, '1234');
      expect(created.resourceId, 'meeting-1');
      expect(created.consent.version, '2026-11-13');
      expect(
        [
          created.consent.ageOver14,
          created.consent.terms,
          created.consent.privacy,
        ],
        [true, true, true],
      );
      verifyGuestLogin(handle: 'g1@guest.invalid', token: 'token-3');
      expect(turnstiles.issued, ['token-1', 'token-2', 'token-3']);
      expect(turnstiles.last.resets, 3, reason: '응답마다 다시 확인');
      final guest = container(tester).read(currentGuestProvider)!;
      expect(guest.meetingId, 'meeting-1');
      expect(await harness.storedSessionToken(), 'ory_st_guest');
    });

    testWidgets('약관 세 항목을 하나씩 모두 체크해야 참여할 수 있다', (tester) async {
      await pumpVisitor(tester);
      await openGuest(tester);
      await enterName(tester, '민수');

      for (final label in ['[필수] 만 14세 이상입니다', '[필수] 이용약관 동의']) {
        await tester.ensureVisible(find.text(label));
        await tester.tap(find.text(label));
        await tester.pumpAndSettle();
      }
      expect(tester.widget<FilledButton>(submit('참여하기')).onPressed, isNull);

      await tester.ensureVisible(find.text('[필수] 개인정보 수집·이용 동의'));
      await tester.tap(find.text('[필수] 개인정보 수집·이용 동의'));
      await tester.pumpAndSettle();
      expect(tester.widget<FilledButton>(submit('참여하기')).onPressed, isNotNull);
      expect(find.text('보기'), findsNWidgets(2));
    });

    testWidgets('만든 뒤 로그인이 거절되면 다시 눌러도 다시 만들지 않고 로그인만 한다', (tester) async {
      await pumpVisitor(tester);
      await openGuest(tester);
      await enterName(tester, '민수');
      await agreeAll(tester);
      await tester.enterText(passwordField(), '1234');
      harness.stubSubmitError(
        KratosFlowType.login,
        const KratosException(
          statusCode: 403,
          errorId: 'guest_verification_failed',
        ),
      );

      await press(tester, '참여하기');
      expect(find.text('사람인지 확인하지 못했습니다. 다시 시도해 주세요'), findsOneWidget);
      expect(container(tester).read(currentGuestProvider), isNull);

      harness.stubSubmit(
        KratosFlowType.login,
        const KratosSubmitResult(sessionToken: 'ory_st_guest'),
      );
      await press(tester, '들어가기');

      expect(guests.creates, hasLength(1));
      verifyGuestLogin(handle: 'g1@guest.invalid', token: 'token-4');
      expect(turnstiles.issued, ['token-1', 'token-2', 'token-3', 'token-4']);
      expect(container(tester).read(currentGuestProvider), isNotNull);
    });

    testWidgets('두 번 눌러도 한 번만 만들고 로그인한다', (tester) async {
      await pumpVisitor(tester);
      await openGuest(tester);
      await enterName(tester, '민수');
      await agreeAll(tester);
      await tester.enterText(passwordField(), '1234');
      await tester.ensureVisible(submit('참여하기'));

      await tester.tap(submit('참여하기'));
      await tester.tap(submit('참여하기'), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(guests.creates, hasLength(1));
      verify(
        () => harness.kratos.submit(
          KratosFlowType.login,
          any(),
          any(),
          turnstileToken: any(named: 'turnstileToken'),
        ),
      ).called(1);
    });

    testWidgets('그 사이 같은 이름이 생기면 다시 찾아 로그인 폼이 된다', (tester) async {
      await pumpVisitor(tester);
      await openGuest(tester);
      await enterName(tester, '민수');
      await agreeAll(tester);
      await tester.enterText(passwordField(), '1234');
      guests.guests['민수'] = 'other@guest.invalid';

      await press(tester, '참여하기');

      expect(guests.lookups.map((l) => l.$2), ['token-1', 'token-3']);
      expect(find.text('이미 참여한 이름입니다. 본인이면 비밀번호를 입력하세요'), findsOneWidget);
      expect(find.text('전체 동의'), findsNothing);
      expect(submit('들어가기'), findsOneWidget);
      expect(container(tester).read(currentGuestProvider), isNull);
    });

    testWidgets('약관이 그 사이 바뀌면 알리고 체크를 지워 새 버전으로 다시 받는다', (tester) async {
      await pumpVisitor(tester);
      await openGuest(tester);
      await enterName(tester, '민수');
      await agreeAll(tester);
      await tester.enterText(passwordField(), '1234');
      guests.consentVersion = '2026-12-01';

      await press(tester, '참여하기');

      expect(find.text('약관이 바뀌었습니다. 바뀐 내용을 확인하고 다시 동의해 주세요'), findsOneWidget);
      expect(tester.widget<FilledButton>(submit('참여하기')).onPressed, isNull);
      await agreeAll(tester);
      await press(tester, '참여하기');

      expect(guests.creates.last.$1.consent.version, '2026-12-01');
      expect(container(tester).read(currentGuestProvider), isNotNull);
    });

    testWidgets('게스트가 100명이면 더 들어올 수 없다고 한다', (tester) async {
      guests.createError = guestError(409, 'GuestLimitReachedError');
      await pumpVisitor(tester);
      await openGuest(tester);
      await enterName(tester, '민수');
      await agreeAll(tester);
      await tester.enterText(passwordField(), '1234');

      await press(tester, '참여하기');

      expect(find.text('이 모임은 게스트가 100명이라 더 들어올 수 없습니다'), findsOneWidget);
      verifyNever(
        () => harness.kratos.submit(
          KratosFlowType.login,
          any(),
          any(),
          turnstileToken: any(named: 'turnstileToken'),
        ),
      );
    });
  });

  group('처음 쓰는 이름의 비밀번호 길이', () {
    const tooShort = '비밀번호는 4글자 이상이어야 해요';

    Future<void> tryCreate(WidgetTester tester, String password) async {
      await pumpVisitor(tester);
      await openGuest(tester);
      await enterName(tester, '민수');
      await agreeAll(tester);
      await tester.enterText(passwordField(), password);
      await press(tester, '참여하기');
    }

    for (final (label, password) in [
      ('세 글자', '123'),
      ('한글 세 글자', '가나다'),
      ('이모지 세 글자(코드 단위로는 여럿)', '👨‍👩‍👧👍🏽🇰🇷'),
      ('조합형 세 글자(NFC로 줄이면 셋)', 'e\u0301e\u0301e\u0301'),
    ]) {
      testWidgets('4글자보다 짧으면($label) 비밀번호 칸에 알리고 아무것도 보내지 않는다', (tester) async {
        await tryCreate(tester, password);

        expect(find.text(tooShort), findsOneWidget);
        expect(guests.creates, isEmpty);
        expect(turnstiles.issued, ['token-1'], reason: '이름 찾기에 쓴 토큰뿐이다');
        verifyNever(
          () => harness.kratos.submit(
            KratosFlowType.login,
            any(),
            any(),
            turnstileToken: any(named: 'turnstileToken'),
          ),
        );
      });
    }

    testWidgets('눈에 보이는 글자로 네 글자면 이모지라도 만든다', (tester) async {
      await tryCreate(tester, '👨‍👩‍👧👍🏽🇰🇷🙂');

      expect(find.text(tooShort), findsNothing);
      expect(guests.creates, hasLength(1));
    });

    testWidgets('고치면 알림이 사라지고 네 글자로 다시 내면 만든다', (tester) async {
      await tryCreate(tester, '123');

      await tester.enterText(passwordField(), '1234');
      await tester.pumpAndSettle();
      expect(find.text(tooShort), findsNothing);
      await press(tester, '참여하기');

      expect(guests.creates.single.$1.password, '1234');
      expect(guests.creates.single.$2, 'token-2');
    });

    testWidgets('서버가 짧은 비밀번호로 거절하면(422) 같은 알림을 비밀번호 칸에 보이고 로그인하지 않는다', (
      tester,
    ) async {
      guests.createError = httpError(
        '/v1/guests',
        422,
        data: {
          'detail': [
            {
              'type': 'value_error',
              'loc': ['body', 'password'],
              'msg': 'Value error, too short',
            },
          ],
        },
      );
      await tryCreate(tester, '1234');

      expect(find.text(tooShort), findsOneWidget);
      verifyNever(
        () => harness.kratos.submit(
          KratosFlowType.login,
          any(),
          any(),
          turnstileToken: any(named: 'turnstileToken'),
        ),
      );
    });

    testWidgets('이름이 거절되면(422) 이름 알림이다', (tester) async {
      guests.createError = httpError(
        '/v1/guests',
        422,
        data: {
          'detail': [
            {
              'type': 'value_error',
              'loc': ['body', 'name'],
              'msg': 'Value error',
            },
          ],
        },
      );
      await tryCreate(tester, '1234');

      expect(find.text('이름에 쓸 수 없는 글자가 있습니다'), findsOneWidget);
      expect(find.text(tooShort), findsNothing);
    });
  });

  group('이미 참여한 이름', () {
    setUp(() => guests.guests['민수'] = 'g7@guest.invalid');

    testWidgets('로그인이 되고 약관을 묻지 않으며 비밀번호로 들어간다', (tester) async {
      await pumpVisitor(tester);
      await openGuest(tester);

      await enterName(tester, '민수');
      expect(find.text('이미 참여한 이름입니다. 본인이면 비밀번호를 입력하세요'), findsOneWidget);
      expect(find.text('전체 동의'), findsNothing);
      expect(find.textContaining('바꾸거나 찾을 수 없습니다'), findsNothing);

      await tester.enterText(passwordField(), '1234');
      await press(tester, '들어가기');

      expect(guests.creates, isEmpty);
      verifyGuestLogin(handle: 'g7@guest.invalid', token: 'token-2');
      expect(
        container(tester).read(currentGuestProvider)?.meetingId,
        'meeting-1',
      );
    });

    testWidgets('예전에 만든 짧은 비밀번호로도 들어간다', (tester) async {
      await pumpVisitor(tester);
      await openGuest(tester);
      await enterName(tester, '민수');

      await tester.enterText(passwordField(), '12');
      await press(tester, '들어가기');

      expect(find.text('비밀번호는 4글자 이상이어야 해요'), findsNothing);
      verify(
        () => harness.kratos.submit(KratosFlowType.login, 'flow-guest', {
          'method': 'password',
          'identifier': 'g7@guest.invalid',
          'password': '12',
        }, turnstileToken: 'token-2'),
      ).called(1);
    });

    testWidgets('비밀번호가 틀리면 비밀번호 칸에 알리고 다시 보낼 때는 새 토큰이다', (tester) async {
      harness.stubSubmitError(KratosFlowType.login, kratosError(4000006));
      await pumpVisitor(tester);
      await openGuest(tester);
      await enterName(tester, '민수');
      await tester.enterText(passwordField(), '1234');

      await press(tester, '들어가기');
      expect(find.text('비밀번호가 맞지 않습니다'), findsOneWidget);
      expect(container(tester).read(currentGuestProvider), isNull);

      await tester.enterText(passwordField(), '12345');
      await tester.pump();
      expect(find.text('비밀번호가 맞지 않습니다'), findsNothing);
      harness.stubSubmit(
        KratosFlowType.login,
        const KratosSubmitResult(sessionToken: 'ory_st_guest'),
      );
      await press(tester, '들어가기');

      expect(turnstiles.issued, ['token-1', 'token-2', 'token-3']);
      expect(guests.lookups, hasLength(1));
    });

    testWidgets('이름을 다 쓰기 전에는 찾지 않고 칸을 벗어날 때 한 번 찾는다', (tester) async {
      await pumpVisitor(tester);
      await openGuest(tester);

      for (final typed in ['민', '민수']) {
        await tester.enterText(nameField(), typed);
        await tester.pump();
      }
      expect(guests.lookups, isEmpty);

      await tester.tap(passwordField());
      await tester.pumpAndSettle();
      await tester.tap(nameField());
      await tester.pumpAndSettle();
      await tester.tap(passwordField());
      await tester.pumpAndSettle();
      expect(guests.lookups, [('민수', 'token-1')]);
    });

    testWidgets('찾는 사이 이름을 고치면 앞 결과를 버리고 고친 이름을 새 토큰으로 찾는다', (tester) async {
      final gate = guests.lookupGate = Completer<void>();
      await pumpVisitor(tester);
      await openGuest(tester);
      await tester.enterText(nameField(), '민수');
      await tester.pump();
      await tester.tap(passwordField());
      await tester.pump();
      expect(find.bySemanticsLabel('이름을 찾는 중'), findsOneWidget);

      await tester.enterText(nameField(), '서연');
      await tester.pump();
      guests.lookupGate = null;
      gate.complete();
      await tester.pumpAndSettle();
      expect(find.text('이미 참여한 이름입니다. 본인이면 비밀번호를 입력하세요'), findsNothing);

      await tester.tap(passwordField());
      await tester.pumpAndSettle();
      expect(guests.lookups, [('민수', 'token-1'), ('서연', 'token-2')]);
      expect(find.text('전체 동의'), findsOneWidget, reason: '서연은 처음 쓰는 이름');
    });
  });

  group('거절', () {
    Future<void> lookUp(WidgetTester tester) async {
      await pumpVisitor(tester);
      await openGuest(tester);
      await enterName(tester, '민수');
    }

    final cases = <String, (Object, String)>{
      '게스트를 받지 않거나 기간이 끝난 모임': (
        guestError(403, 'GuestEntryRefusedError'),
        '지금은 이 모임에 게스트로 들어갈 수 없습니다',
      ),
      '토큰을 받지 않음': (
        guestError(403, 'GuestVerificationFailedError'),
        '사람인지 확인하지 못했습니다. 다시 시도해 주세요',
      ),
      '확인할 수 없음': (
        guestError(503, 'GuestServiceUnavailableError'),
        '지금은 확인할 수 없습니다. 잠시 뒤 다시 시도해 주세요',
      ),
      '요청 한도': (
        guestError(429, 'RateLimitExceeded', retryAfter: 35),
        '요청이 너무 많습니다. 35초 뒤 다시 시도해 주세요',
      ),
      '이름 규칙': (
        guestError(422, 'RequestValidationError'),
        '이름에 쓸 수 없는 글자가 있습니다',
      ),
    };
    for (final MapEntry(key: name, value: (error, text)) in cases.entries) {
      testWidgets('이름 찾기 거절: $name', (tester) async {
        guests.lookupError = error;
        await lookUp(tester);

        expect(find.text(text), findsOneWidget);
        expect(find.text('전체 동의'), findsNothing);
        expect(turnstiles.last.resets, 1);
      });
    }

    testWidgets('이름 찾기가 거절된 뒤 들어가기는 새 토큰으로 다시 찾는다', (tester) async {
      guests.lookupError = guestError(403, 'GuestVerificationFailedError');
      guests.guests['민수'] = 'g7@guest.invalid';
      await lookUp(tester);
      await tester.enterText(passwordField(), '1234');

      await press(tester, '들어가기');

      expect(guests.lookups.map((l) => l.$2), ['token-1', 'token-2']);
      verifyGuestLogin(handle: 'g7@guest.invalid', token: 'token-3');
    });

    final loginCases = <String, (KratosException, String)>{
      '게스트를 받지 않는 모임(로그인 훅)': (
        kratosError(4000001),
        '지금은 이 모임에 게스트로 들어갈 수 없습니다',
      ),
      '확인할 수 없음': (
        const KratosException(
          statusCode: 503,
          errorId: 'guest_verification_unavailable',
        ),
        '지금은 확인할 수 없습니다. 잠시 뒤 다시 시도해 주세요',
      ),
      '요청 한도': (
        const KratosException(
          statusCode: 429,
          retryAfter: Duration(seconds: 12),
        ),
        '요청이 너무 많습니다. 12초 뒤 다시 시도해 주세요',
      ),
    };
    for (final MapEntry(key: name, value: (error, text))
        in loginCases.entries) {
      testWidgets('로그인 거절: $name', (tester) async {
        guests.guests['민수'] = 'g7@guest.invalid';
        harness.stubSubmitError(KratosFlowType.login, error);
        await lookUp(tester);
        await tester.enterText(passwordField(), '1234');

        await press(tester, '들어가기');

        expect(find.text(text), findsOneWidget);
        expect(container(tester).read(currentGuestProvider), isNull);
        expect(turnstiles.last.resets, 2);
      });
    }

    testWidgets('확인 상자를 불러오지 못하면 알리고 요청을 보내지 않는다', (tester) async {
      turnstiles.initial = TurnstileStatus.unavailable;
      await pumpVisitor(tester);
      await openGuest(tester);

      expect(find.textContaining('확인 상자를 불러오지 못했습니다'), findsOneWidget);
      await enterName(tester, '민수');
      expect(guests.lookups, isEmpty);
      expect(find.text('지금은 확인할 수 없습니다. 잠시 뒤 다시 시도해 주세요'), findsOneWidget);

      await tester.tap(find.text('다시 불러오기'));
      await tester.pumpAndSettle();
      await tester.enterText(passwordField(), '1234');
      await press(tester, '들어가기');
      expect(guests.lookups, [('민수', 'token-1')]);
    });
  });

  testWidgets('넓은 화면에서 애니메이션을 줄였으면 게스트 폼을 연 채 칠하려 해도 떨지 않고 폼을 보이게 올린다', (
    tester,
  ) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await pumpVisitor(tester, size: const Size(1280, 500));
    await openGuest(tester);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -900));
    await tester.pumpAndSettle();
    expect(tester.getBottomLeft(nameField()).dy, lessThan(0));
    final rest = tester.getTopLeft(find.byType(MeetingLoginPanel)).dx;

    await tester.tapAt(cellCenter(tester, '3월 2일 (화) 14:00 ~ 14:30'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 40));

    expect(tester.getTopLeft(find.byType(MeetingLoginPanel)).dx, rest);
    expect(tester.getTopLeft(nameField()).dy, greaterThanOrEqualTo(0));
    expect(guests.lookups, isEmpty);
  });

  group('좁은 화면의 요청 시트', () {
    Finder inSheet(Finder finder) =>
        find.descendant(of: find.byType(BottomSheet), matching: finder);

    Future<void> openRequest(WidgetTester tester) async {
      await tester.tap(find.widgetWithText(FilledButton, '내 시간 입력하기'));
      await tester.pumpAndSettle();
    }

    testWidgets('게스트를 받는 모임이면 로그인 옆에 Guest와 이름·비밀번호만 있으면 된다는 말을 둔다', (
      tester,
    ) async {
      await pumpVisitor(tester, size: const Size(360, 800));
      expect(find.byType(MeetingLoginPanel), findsNothing);

      await openRequest(tester);

      expect(inSheet(find.text('로그인하면 내 시간을 칠할 수 있어요')), findsOneWidget);
      expect(
        inSheet(find.widgetWithText(FilledButton, 'Guest')),
        findsOneWidget,
      );
      expect(
        inSheet(
          find.text('게스트는 가입 없이 이름과 비밀번호만 있으면 돼요, 하지만 로그인만큼 강력한 보안을 보장하지 못해요!'),
        ),
        findsOneWidget,
      );
    });

    testWidgets(
      'Guest는 시트 안에서 이름 → 비밀번호 → 약관 → 확인 상자 → 참여하기 순서의 폼을 열고, 들어가면 시트를 닫고 게스트 화면이 된다',
      (tester) async {
        await pumpVisitor(tester, size: const Size(360, 800));
        await openRequest(tester);

        await tester.tap(inSheet(find.widgetWithText(FilledButton, 'Guest')));
        await tester.pumpAndSettle();
        expect(inSheet(find.text('게스트로 참여')), findsOneWidget);
        expect(inSheet(nameField()), findsOneWidget);

        await enterName(tester, '민수');
        await agreeAll(tester);
        await tester.enterText(passwordField(), '1234');
        final order = [
          nameField(),
          passwordField(),
          find.text('전체 동의'),
          find.bySemanticsLabel('사람인지 확인하는 상자'),
          submit('참여하기'),
        ].map((finder) => tester.getTopLeft(finder).dy).toList();
        expect(order, orderedEquals([...order]..sort()));

        await press(tester, '참여하기');

        verifyGuestLogin(handle: 'g1@guest.invalid', token: 'token-3');
        expect(find.byType(BottomSheet), findsNothing);
        expect(find.text('게스트 민수로 진행 중입니다'), findsOneWidget);
        expect(find.widgetWithText(FilledButton, '내 시간 입력하기'), findsNothing);
      },
    );

    testWidgets('게스트 폼에서 뒤로 가면 로그인·Guest 고르기로 돌아간다', (tester) async {
      await pumpVisitor(tester, size: const Size(360, 800));
      await openRequest(tester);
      await tester.tap(inSheet(find.widgetWithText(FilledButton, 'Guest')));
      await tester.pumpAndSettle();

      await tester.tap(inSheet(find.byTooltip('뒤로')));
      await tester.pumpAndSettle();

      expect(nameField(), findsNothing);
      expect(
        inSheet(find.widgetWithText(FilledButton, 'Guest')),
        findsOneWidget,
      );
      expect(turnstiles.last.disposed, isTrue);
    });
  });
}
