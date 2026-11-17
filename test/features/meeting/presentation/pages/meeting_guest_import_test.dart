import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:momeet/app_route.dart';
import 'package:momeet/core/providers/auth_provider.dart';
import 'package:momeet/core/providers/browser_provider.dart';
import 'package:momeet/core/providers/kept_guest_session_store.dart';
import 'package:momeet/core/providers/retry_policy.dart';
import 'package:momeet/core/providers/timezone_provider.dart';
import 'package:momeet/features/meeting/presentation/pages/meeting_page.dart';
import 'package:momeet/shared/api/kratos/kratos_models.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/shared/providers/api_providers.dart';
import 'package:timezone/data/latest.dart' as tz;

import '../../../../helpers/fake_rest_clients.dart';
import '../../../../helpers/fake_turnstile.dart';
import '../../../../helpers/fake_usage_analytics.dart';
import '../../../../helpers/kratos_mocks.dart';
import '../../guest_fixtures.dart';
import '../../meeting_fixtures.dart';

/// 서울 2027년 3월 [day]일 [hour]시의 UTC 시각
DateTime seoul(int day, int hour) => DateTime.utc(2027, 3, day, hour - 9);

/// 받은 옮기기 요청(`POST /guest-import`)을 기록하고 [responses]를 차례로 돌려준다(예외면 던진다). 옮기기에
/// 성공하면 모임의 가능 시간에도 넣는다(다시 읽을 때 보인다)
class ImportingMeetingsClient extends FakeMeetingsClient {
  ImportingMeetingsClient({super.meeting});

  final responses = <Object>[];
  final tokens = <String>[];

  @override
  Future<AvailabilityRead> importGuestV1MeetingsMeetingIdGuestImportPost({
    required String meetingId,
    required GuestImport body,
    String? timezone,
    RequestOptions? options,
  }) async {
    tokens.add(body.guestToken);
    final next = responses.removeAt(0);
    if (next is! AvailabilityRead) throw next;
    availability = [
      for (final entry in availability)
        if (entry.participant.id != next.participant.id) entry,
      next,
    ];
    return next;
  }
}

DioException refused(int status, [String? errorType]) => DioException(
  requestOptions: RequestOptions(path: '/v1/meetings/meeting-1/guest-import'),
  response: Response(
    requestOptions: RequestOptions(path: '/v1/meetings/meeting-1/guest-import'),
    statusCode: status,
    data: errorType == null ? null : {'error_type': errorType},
  ),
);

DioException guestNotFound() => refused(404, 'GuestNotFoundError');

DioException lost() => DioException(
  requestOptions: RequestOptions(path: '/v1/meetings/meeting-1/guest-import'),
  type: DioExceptionType.receiveTimeout,
);

/// 낱말 잇기 문자(U+2060)를 빼고 [part]가 든 글자
Finder plainContaining(String part) => find.byWidgetPredicate(
  (widget) =>
      widget is Text &&
      (widget.data?.replaceAll('\u2060', '').contains(part) ?? false),
);

const keptToken = 'ory_st_kept';
const keptKey = '${keptGuestSessionKeyPrefix}meeting-1';
const moved = '게스트로 넣은 시간을 계정으로 옮겼어요';
const notFound = '게스트로 넣은 시간을 찾지 못했어요. 이제 회원으로 참여해요';

/// 회원(지현)의 참여자에 게스트 시간을 합친 응답
AvailabilityRead mergedMember() => availabilityOf(
  'member-p',
  name: '지현',
  userId: testUser.id,
  slots: [(seoul(1, 9), seoul(1, 11))],
);

void main() {
  late KratosTestHarness harness;
  late ImportingMeetingsClient meetings;
  late FakeUsageAnalytics analytics;
  late GoRouter router;
  final guestJwt = testJwt();

  setUpAll(() async {
    registerKratosFallbacks();
    tz.initializeTimeZones();
    await initializeDateFormatting('ko');
  });

  setUp(() async {
    harness = await KratosTestHarness.create();
    await const FlutterSecureStorage().write(key: keptKey, value: keptToken);
    when(() => harness.kratos.whoami(keptToken)).thenAnswer(
      (_) async => KratosSession.guest(guest: testGuest, accessToken: guestJwt),
    );
    when(() => harness.kratos.logout(any())).thenAnswer((_) async {});
    meetings = ImportingMeetingsClient(meeting: makeMeeting())
      ..availability = [
        availabilityOf('b', name: '서연', slots: [(seoul(1, 9), seoul(1, 11))]),
      ];
    analytics = FakeUsageAnalytics();
  });

  Future<void> pumpPage(
    WidgetTester tester, {
    Size size = const Size(1280, 900),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    router = GoRouter(
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
          guestsApiProvider.overrideWithValue(FakeGuestsClient()),
          usersApiProvider.overrideWithValue(
            FakeUsersClient(consentRequired: false),
          ),
          timezoneProvider.overrideWith(() => FixedTimezone('Asia/Seoul')),
          appOriginProvider.overrideWithValue('https://app.example.com'),
          FakeTurnstiles().override,
          analytics.asOverride,
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<String?> kept() => const FlutterSecureStorage().read(key: keptKey);

  group('회원이 따로 둔 게스트 세션이 있는 모임을 열면', () {
    testWidgets('한 번 저절로 옮기고 응답으로 화면을 바꾸며 알린 뒤 따로 둔 세션을 끝내고 지운다', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      meetings.responses.add(mergedMember());

      await pumpPage(tester);
      await tester.pumpAndSettle();

      expect(meetings.tokens, [guestJwt], reason: '따로 둔 세션으로 새로 받은 게스트 JWT');
      expect(find.text(moved), findsOneWidget);
      expect(
        find.bySemanticsLabel('지현, 나'),
        findsOneWidget,
        reason: '옮긴 내 참여자',
      );
      expect(await kept(), isNull);
      verify(() => harness.kratos.logout(keptToken)).called(1);
      expect(analytics.events, contains('meeting_guest_converted'));
      expect(
        allowedUsageNames.containsAll(
          analytics.sent.map((e) => e.split(':').last),
        ),
        isTrue,
      );
      expect(
        harness.prefs.getKeys().where((k) => k.contains('guest')),
        isEmpty,
      );
      semantics.dispose();
    });

    testWidgets('따로 둔 세션이 없으면 아무것도 하지 않는다', (tester) async {
      await const FlutterSecureStorage().delete(key: keptKey);

      await pumpPage(tester);
      await tester.pump(const Duration(seconds: 5));

      expect(meetings.tokens, isEmpty);
      expect(find.text(moved), findsNothing);
    });

    testWidgets('처음 시도가 404이고 내 시간이 없으면 찾지 못했다고 알리고 따로 둔 것을 지운다', (
      tester,
    ) async {
      meetings.responses.add(guestNotFound());

      await pumpPage(tester);
      await tester.pumpAndSettle();

      expect(find.text(notFound), findsOneWidget);
      expect(await kept(), isNull);
      expect(analytics.events, isNot(contains('meeting_guest_converted')));
    });

    testWidgets('처음 시도에서 게스트 세션이 끝나 있으면 찾지 못했다고 알린다', (tester) async {
      when(
        () => harness.kratos.whoami(keptToken),
      ).thenAnswer((_) async => null);

      await pumpPage(tester);
      await tester.pumpAndSettle();

      expect(meetings.tokens, isEmpty);
      expect(find.text(notFound), findsOneWidget);
      expect(await kept(), isNull);
    });

    testWidgets('응답을 못 받은 뒤 다시 하기가 404이고 내 시간이 있으면 옮긴 것으로 본다', (tester) async {
      meetings.responses
        ..add(lost())
        ..add(guestNotFound());
      // 서버는 처음 요청에서 이미 옮겼다
      meetings.availability = [...meetings.availability, mergedMember()];

      await pumpPage(tester);
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      expect(meetings.tokens, hasLength(2));
      expect(find.text(moved), findsOneWidget);
      expect(find.text(notFound), findsNothing);
      expect(await kept(), isNull);
    });

    testWidgets('계속 연결이 끊기면 정한 횟수만 다시 하고 조용한 알림에 다시 시도를 두며 따로 둔 것은 둔다', (
      tester,
    ) async {
      meetings.responses.addAll([lost(), refused(503), lost()]);

      await pumpPage(tester);
      await tester.pump(const Duration(seconds: 30));
      await tester.pumpAndSettle();

      expect(meetings.tokens, hasLength(3), reason: '저절로는 세 번까지');
      expect(find.text('게스트로 넣은 시간을 아직 옮기지 못했어요'), findsOneWidget);
      expect(await kept(), keptToken);

      meetings.responses.add(lost());
      await tester.tap(find.widgetWithText(TextButton, '다시 시도'));
      await tester.pump(const Duration(seconds: 30));
      await tester.pumpAndSettle();
      expect(meetings.tokens, hasLength(4), reason: '누를 때마다 한 번');
      expect(find.text('게스트로 넣은 시간을 아직 옮기지 못했어요'), findsOneWidget);

      meetings.responses.add(mergedMember());
      await tester.tap(find.widgetWithText(TextButton, '다시 시도'));
      await tester.pumpAndSettle();
      expect(find.text(moved), findsOneWidget);
      expect(find.text('게스트로 넣은 시간을 아직 옮기지 못했어요'), findsNothing);
      expect(await kept(), isNull);
    });

    testWidgets('같은 때 다른 요청과 겹치면(409) 잠시 뒤 다시 해 옮긴다', (tester) async {
      meetings.responses.addAll([
        refused(409, 'GuestImportConflictError'),
        mergedMember(),
      ]);

      await pumpPage(tester);
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      expect(meetings.tokens, hasLength(2));
      expect(find.text(moved), findsOneWidget);
    });

    testWidgets('게스트 JWT가 거절되면(422) 따로 둔 세션으로 한 번 새로 받아 다시 보낸다', (
      tester,
    ) async {
      final fresh = testJwt();
      var minted = 0;
      when(() => harness.kratos.whoami(keptToken)).thenAnswer(
        (_) async => KratosSession.guest(
          guest: testGuest,
          accessToken: minted++ == 0 ? guestJwt : fresh,
        ),
      );
      meetings.responses.addAll([
        refused(422, 'GuestTokenInvalidError'),
        mergedMember(),
      ]);

      await pumpPage(tester);
      await tester.pumpAndSettle();

      expect(meetings.tokens, [guestJwt, fresh]);
      expect(find.text(moved), findsOneWidget);
    });

    testWidgets('게스트 JWT가 거절된 뒤 새로 받지 못하면(세션이 끝남) 찾지 못했다고 알린다', (tester) async {
      var minted = 0;
      when(() => harness.kratos.whoami(keptToken)).thenAnswer(
        (_) async => minted++ == 0
            ? KratosSession.guest(guest: testGuest, accessToken: guestJwt)
            : null,
      );
      meetings.responses.add(refused(422, 'GuestTokenInvalidError'));

      await pumpPage(tester);
      await tester.pumpAndSettle();

      expect(find.text(notFound), findsOneWidget);
      expect(await kept(), isNull);
    });

    testWidgets('모임을 볼 수 없다는 404는 게스트를 찾지 못한 것으로 보지 않고 따로 둔 것을 둔다', (
      tester,
    ) async {
      meetings.responses.addAll([
        for (var i = 0; i < 3; i++) refused(404, 'MeetingNotFoundError'),
      ]);

      await pumpPage(tester);
      await tester.pump(const Duration(seconds: 30));
      await tester.pumpAndSettle();

      expect(find.text(notFound), findsNothing);
      expect(find.text('게스트로 넣은 시간을 아직 옮기지 못했어요'), findsOneWidget);
      expect(await kept(), keptToken);
    });
  });

  group('게스트의 안전한 정규 유저로 바꾸기', () {
    setUp(() async {
      await const FlutterSecureStorage().delete(key: keptKey);
      harness.stubGuestSession();
      await harness.prefs.setString(guestMeetingKey, 'guest-uid meeting-1');
      meetings
        ..meeting = makeMeeting().copyWith(allowGuests: true)
        ..guestName = '민수';
    });

    testWidgets(
      '계정 줄에서 무엇이 바뀌는지 알리고, 로그인하고 옮기기는 게스트 세션을 끝내지 않고 따로 둔 뒤 로그인으로 간다',
      (tester) async {
        await pumpPage(tester);

        await tester.tap(find.text('안전한 정규 유저로 바꾸기'));
        await tester.pumpAndSettle();
        expect(
          plainContaining('회원으로 로그인하면 게스트로 넣은 시간이 계정으로 옮겨지고, 게스트 닉네임은 사라져요'),
          findsOneWidget,
        );
        expect(plainContaining('비밀번호를 잊어도'), findsOneWidget);

        await tester.tap(find.text('로그인하고 옮기기'));
        await tester.pumpAndSettle();

        expect(
          router.routerDelegate.currentConfiguration.uri.toString(),
          '${AppRoute.login.path}?redirect=${Uri.encodeComponent('/meetings/meeting-1')}',
        );
        expect(await kept(), KratosTestHarness.sessionToken);
        expect(await harness.storedSessionToken(), isNull);
        verifyNever(() => harness.kratos.logout(any()));
      },
    );

    testWidgets('취소하면 아무것도 바꾸지 않는다', (tester) async {
      await pumpPage(tester);

      await tester.tap(find.text('안전한 정규 유저로 바꾸기'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('취소'));
      await tester.pumpAndSettle();

      expect(find.text('게스트 민수로 진행 중입니다'), findsOneWidget);
      expect(await kept(), isNull);
      expect(
        await harness.storedSessionToken(),
        KratosTestHarness.sessionToken,
      );
    });
  });

  group('로그인을 그만두고 방문자로 돌아오면', () {
    setUp(() async {
      harness = await KratosTestHarness.create(authenticated: false);
      await const FlutterSecureStorage().write(key: keptKey, value: keptToken);
      when(() => harness.kratos.whoami(keptToken)).thenAnswer(
        (_) async =>
            KratosSession.guest(guest: testGuest, accessToken: guestJwt),
      );
      meetings
        ..meeting = makeMeeting().copyWith(allowGuests: true)
        ..guestName = '민수';
    });

    testWidgets('게스트로 계속하기로 따로 둔 게스트 세션을 되돌려 게스트로 이어 간다', (tester) async {
      await pumpPage(tester);

      await tester.tap(find.widgetWithText(TextButton, '게스트로 계속하기'));
      await tester.pumpAndSettle();

      expect(find.text('게스트 민수로 진행 중입니다'), findsOneWidget);
      expect(await kept(), isNull);
      expect(await harness.storedSessionToken(), keptToken);
    });

    testWidgets('따로 둔 세션이 끝났으면 알리고 지운다', (tester) async {
      when(
        () => harness.kratos.whoami(keptToken),
      ).thenAnswer((_) async => null);
      await pumpPage(tester);

      await tester.tap(find.widgetWithText(TextButton, '게스트로 계속하기'));
      await tester.pumpAndSettle();

      expect(find.text('게스트 세션이 끝나 이어서 쓸 수 없어요'), findsOneWidget);
      expect(find.widgetWithText(TextButton, '게스트로 계속하기'), findsNothing);
      expect(await kept(), isNull);
    });
  });
}
