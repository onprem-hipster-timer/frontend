import 'package:dio/dio.dart' show RequestOptions;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:momeet/core/analytics/analytics_consent.dart';
import 'package:momeet/core/providers/account_scope.dart';
import 'package:momeet/core/providers/auth_provider.dart';
import 'package:momeet/core/providers/browser_provider.dart';
import 'package:momeet/core/providers/kept_guest_session_store.dart';
import 'package:momeet/core/providers/retry_policy.dart';
import 'package:momeet/core/providers/timezone_provider.dart';
import 'package:momeet/features/auth/presentation/pages/login_page.dart';
import 'package:momeet/features/timer/presentation/providers/timer_providers.dart';
import 'package:momeet/router.dart';
import 'package:momeet/shared/api/kratos/kratos_client.dart';
import 'package:momeet/shared/api/kratos/kratos_models.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/shared/providers/api_providers.dart';
import 'package:timezone/data/latest.dart' as tz;

import '../../helpers/fake_rest_clients.dart';
import '../../helpers/fake_turnstile.dart';
import '../../helpers/kratos_mocks.dart';
import 'guest_fixtures.dart';
import 'meeting_fixtures.dart';

/// 서울 2027년 3월 [day]일 [hour]시의 UTC 시각
DateTime seoul(int day, int hour) => DateTime.utc(2027, 3, day, hour - 9);

/// backend처럼 옮긴다: 게스트 참여자를 지우고 그 시간을 회원의 참여자(없으면 새로 만든다)에 합친다
class _ServerMeetings extends FakeMeetingsClient {
  _ServerMeetings({super.meeting});

  /// 받은 옮기기 요청의 게스트 JWT
  final tokens = <String>[];

  @override
  Future<AvailabilityRead> importGuestV1MeetingsMeetingIdGuestImportPost({
    required String meetingId,
    required GuestImport body,
    String? timezone,
    RequestOptions? options,
  }) async {
    tokens.add(body.guestToken);
    final guest = availability.firstWhere((e) => e.participant.isGuest);
    availability.remove(guest);
    final at = availability.indexWhere((e) => e.participant.userId == userId);
    final merged = AvailabilityRead(
      participant: at >= 0
          ? availability[at].participant
          : ParticipantRead(
              id: 'participant-$userId',
              meetingId: meetingId,
              displayName: '지현',
              createdAt: DateTime.utc(2027),
              isOwner: false,
              userId: userId,
            ),
      timeSlots: [
        if (at >= 0) ...availability[at].timeSlots,
        ...guest.timeSlots,
      ],
    );
    if (at >= 0) {
      availability[at] = merged;
    } else {
      availability.add(merged);
    }
    return merged;
  }
}

void main() {
  late KratosTestHarness harness;
  late _ServerMeetings meetings;
  const memberToken = 'ory_st_member';
  const keptKey = '${keptGuestSessionKeyPrefix}meeting-1';

  setUpAll(() async {
    registerKratosFallbacks();
    tz.initializeTimeZones();
    await initializeDateFormatting('ko');
  });

  setUp(() async {
    harness = await KratosTestHarness.create();
    harness
      ..stubGuestSession()
      ..stubCreateFlow(KratosFlowType.login, 'flow-login');
    when(() => harness.kratos.logout(any())).thenAnswer((_) async {});
    await harness.prefs.setString(guestMeetingKey, 'guest-uid meeting-1');
    meetings =
        _ServerMeetings(meeting: makeMeeting().copyWith(allowGuests: true))
          ..guestName = '민수'
          ..availability = [
            availabilityOf(
              'b',
              name: '서연',
              slots: [(seoul(1, 9), seoul(1, 11))],
            ),
            availabilityOf(
              'participant-guest',
              name: '민수',
              guest: true,
              slots: [(seoul(1, 10), seoul(1, 12))],
            ),
          ];
  });

  Future<void> pumpAWhile(WidgetTester tester) async {
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  GoRouter routerOf(WidgetTester tester) => ProviderScope.containerOf(
    tester.element(find.byType(Router<Object>)),
  ).read(routerProvider);

  String location(WidgetTester tester) =>
      routerOf(tester).routerDelegate.currentConfiguration.uri.toString();

  /// 실제 앱처럼 계정이 바뀌면 컨테이너와 라우터를 새로 만들고([AccountScope]), 새 라우터는 브라우저 주소에서
  /// 시작한다. 브라우저 주소는 웹 엔진처럼 라우터가 알린 경로를 따른다
  Future<void> pumpApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    var address = '/meetings/meeting-1';
    final messenger = tester.binding.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(SystemChannels.navigation, (call) async {
      if (call.method == 'routeInformationUpdated') {
        final args = call.arguments as Map<Object?, Object?>;
        address = (args['uri'] ?? args['location'])! as String;
      }
      return null;
    });
    addTearDown(
      () => messenger.setMockMethodCallHandler(SystemChannels.navigation, null),
    );
    await tester.pumpWidget(
      AccountScope(
        createContainer: () => ProviderContainer(
          retry: appRetry,
          overrides: [
            ...harness.overrides,
            browserRouteProvider.overrideWith((ref) => address),
            meetingsApiProvider.overrideWithValue(meetings),
            visibilityApiProvider.overrideWithValue(FakeVisibilityClient()),
            guestsApiProvider.overrideWithValue(FakeGuestsClient()),
            usersApiProvider.overrideWithValue(
              FakeUsersClient(consentRequired: false),
            ),
            timezoneProvider.overrideWith(() => FixedTimezone('Asia/Seoul')),
            appOriginProvider.overrideWithValue('https://app.example.com'),
            timerWsClientProvider.overrideWithValue(null),
            analyticsConsentBridgeProvider.overrideWithValue(
              InMemoryAnalyticsConsentBridge(),
            ),
            FakeTurnstiles().override,
          ],
        ),
        child: Consumer(
          builder: (context, ref, _) =>
              MaterialApp.router(routerConfig: ref.watch(routerProvider)),
        ),
      ),
    );
    await pumpAWhile(tester);
  }

  testWidgets(
    '게스트가 로그인하고 옮기기를 고르면 로그인 화면이 열리고, 회원으로 로그인해 모임으로 돌아오면 게스트 시간을 한 번 옮겨 '
    '참여자는 회원 하나다',
    (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpApp(tester);
      expect(find.text('게스트 민수로 진행 중입니다'), findsOneWidget);

      await tester.tap(find.text('안전한 정규 유저로 바꾸기'));
      await pumpAWhile(tester);
      await tester.tap(find.text('로그인하고 옮기기'));
      await pumpAWhile(tester);

      expect(find.byType(LoginPage), findsOneWidget);
      expect(
        location(tester),
        '${AppRoute.login.path}?redirect=${Uri.encodeComponent('/meetings/meeting-1')}',
      );
      expect(
        await const FlutterSecureStorage().read(key: keptKey),
        KratosTestHarness.sessionToken,
      );

      // 회원으로 로그인한다. 따로 둔 게스트 세션은 그대로 게스트 세션이다
      when(() => harness.kratos.whoami(memberToken)).thenAnswer(
        (_) async => KratosSession(user: testUser, accessToken: testJwt()),
      );
      harness.stubSubmit(
        KratosFlowType.login,
        const KratosSubmitResult(sessionToken: memberToken),
      );
      meetings
        ..guestName = null
        ..userId = testUser.id;
      final container = ProviderScope.containerOf(
        tester.element(find.byType(Router<Object>)),
      );
      await tester.runAsync(
        () => container
            .read(authProvider.notifier)
            .signInWithEmail(email: 'user@example.com', password: 'pw'),
      );
      await pumpAWhile(tester);
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await pumpAWhile(tester);

      expect(location(tester), '/meetings/meeting-1');
      expect(meetings.tokens, [
        harness.accessToken,
      ], reason: '따로 둔 게스트 세션의 JWT로 한 번');
      expect(find.text('게스트로 넣은 시간을 계정으로 옮겼어요'), findsOneWidget);
      expect(find.bySemanticsLabel('지현, 나'), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('^민수')), findsNothing);
      expect(await const FlutterSecureStorage().read(key: keptKey), isNull);
      verify(
        () => harness.kratos.logout(KratosTestHarness.sessionToken),
      ).called(1);
      semantics.dispose();
    },
  );
}
