import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:momeet/app_route.dart';
import 'package:momeet/core/providers/retry_policy.dart';
import 'package:momeet/core/providers/timezone_provider.dart';
import 'package:momeet/core/share/system_share.dart';
import 'package:momeet/features/meeting/presentation/pages/meeting_page.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_login_panel.dart';
import 'package:momeet/core/providers/browser_provider.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/shared/providers/api_providers.dart';
import 'package:timezone/data/latest.dart' as tz;

import '../../../../helpers/fake_rest_clients.dart';
import '../../../../helpers/kratos_mocks.dart';
import '../../meeting_fixtures.dart';
import '../../meeting_grid_finders.dart';

const editHint = '모임을 만든 사람만 수정할 수 있어요';
const link = 'https://app.example.com/meetings/meeting-1';

/// 로그인한 회원(test-uid)이 모임 화면의 계정 줄과 링크 칸을 쓴다
void main() {
  late KratosTestHarness harness;
  late FakeMeetingsClient meetings;
  late List<(String, String)> shares;
  late SystemShareResult shareResult;
  late List<String> copied;

  setUpAll(() async {
    registerKratosFallbacks();
    tz.initializeTimeZones();
    await initializeDateFormatting('ko');
  });

  setUp(() async {
    harness = await KratosTestHarness.create();
    when(() => harness.kratos.logout(any())).thenAnswer((_) async {});
    meetings = FakeMeetingsClient(meeting: makeMeeting())..userId = testUser.id;
    shares = [];
    shareResult = SystemShareResult.unavailable;
    copied = [];
  });

  Future<void> pumpMeeting(
    WidgetTester tester, {
    Size size = const Size(1280, 900),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied.add((call.arguments as Map)['text'] as String);
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    final router = GoRouter(
      initialLocation: '/meetings/meeting-1',
      routes: [
        GoRoute(
          path: AppRoute.login.path,
          name: AppRoute.login.name,
          builder: (context, state) => const Text('로그인 화면'),
        ),
        GoRoute(
          path: AppRoute.meetingEdit.path,
          name: AppRoute.meetingEdit.name,
          builder: (context, state) => const Text('모임 설정 화면'),
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
          usersApiProvider.overrideWithValue(
            FakeUsersClient(consentRequired: false),
          ),
          schedulesApiProvider.overrideWithValue(FakeSchedulesClient()),
          timezoneProvider.overrideWith(() => FixedTimezone('Asia/Seoul')),
          appOriginProvider.overrideWithValue('https://app.example.com'),
          systemShareProvider.overrideWithValue(({
            required title,
            required url,
          }) async {
            shares.add((title, url));
            return shareResult;
          }),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// [text]를 머리띠에 가리지 않게 화면 가운데로 굴린 뒤 누른다
  Future<void> tapText(WidgetTester tester, String text) async {
    final target = find.text(text);
    unawaited(Scrollable.ensureVisible(tester.element(target), alignment: 0.5));
    await tester.pumpAndSettle();
    await tester.tap(target);
    await tester.pumpAndSettle();
  }

  group('회원 로그아웃', () {
    for (final (name, size) in [
      ('넓으면', const Size(1280, 900)),
      ('좁으면', const Size(400, 900)),
    ]) {
      testWidgets('$name 계정 줄에 로그아웃이 있고, 누르면 세션을 끝내 공개 모임의 방문자 화면이 된다', (
        tester,
      ) async {
        await pumpMeeting(tester, size: size);
        expect(find.text('user@example.com 계정으로 진행 중입니다'), findsOneWidget);

        await tapText(tester, '로그아웃');

        verify(
          () => harness.kratos.logout(KratosTestHarness.sessionToken),
        ).called(1);
        expect(find.textContaining('계정으로 진행 중입니다'), findsNothing);
        expect(find.text('로그인하면 내 시간을 칠할 수 있어요'), findsWidgets);
        if (size.width > 800) {
          expect(find.byType(MeetingLoginPanel), findsOneWidget);
        }
      });
    }

    testWidgets('공개가 아닌 모임이면 로그아웃한 뒤 찾을 수 없는 모임과 로그인이다', (tester) async {
      await pumpMeeting(tester);
      meetings.resultError = notFound();

      await tapText(tester, '로그아웃');

      expect(find.text('모임을 찾을 수 없습니다'), findsOneWidget);
      expect(find.text('로그인'), findsOneWidget);
    });

    testWidgets('보내는 중인 저장을 기다린 뒤 로그아웃한다', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpMeeting(tester);
      meetings.putGate = Completer<void>();
      await tester.tapAt(cellCenter(tester, '3월 1일 (월) 6:00 ~ 6:30'));
      await tester.pump(const Duration(seconds: 1));
      expect(meetings.puts, hasLength(1), reason: '저장을 보내는 중이다');

      await tester.tap(find.text('로그아웃'));
      await tester.pump();
      verifyNever(() => harness.kratos.logout(any()));

      meetings.putGate!.complete();
      await tester.pumpAndSettle();
      verify(
        () => harness.kratos.logout(KratosTestHarness.sessionToken),
      ).called(1);
      semantics.dispose();
    });

    testWidgets('저장하지 못해도 묻지 않고 로그아웃한다', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpMeeting(tester);
      meetings.putError = Exception('끊김');
      await tester.tapAt(cellCenter(tester, '3월 1일 (월) 6:00 ~ 6:30'));
      await tester.pump();

      await tester.tap(find.text('로그아웃'));
      await tester.pumpAndSettle();

      verify(
        () => harness.kratos.logout(KratosTestHarness.sessionToken),
      ).called(1);
      expect(find.byType(AlertDialog), findsNothing);
      semantics.dispose();
    });
  });

  group('링크 칸', () {
    testWidgets('공유 창이 있으면 모임 제목과 링크로 연다', (tester) async {
      shareResult = SystemShareResult.shared;
      await pumpMeeting(tester);

      await tapText(tester, '공유하기');

      expect(shares, [('팀 회의', link)]);
      expect(copied, isEmpty);
      expect(find.text('링크를 복사했습니다'), findsNothing);
    });

    testWidgets('공유 창이 없으면 링크를 복사하고 알린다', (tester) async {
      await pumpMeeting(tester);

      await tapText(tester, '공유하기');

      expect(copied, [link]);
      expect(find.text('링크를 복사했습니다'), findsOneWidget);
    });

    testWidgets('공유 창을 닫으면 아무것도 하지 않고, 공유하다 실패하면 복사한다', (tester) async {
      shareResult = SystemShareResult.dismissed;
      await pumpMeeting(tester);
      await tapText(tester, '공유하기');
      expect(shares, hasLength(1));
      expect(copied, isEmpty);
      expect(find.byType(SnackBar), findsNothing);

      shareResult = SystemShareResult.failed;
      await tapText(tester, '공유하기');
      expect(copied, [link]);
      expect(find.text('링크를 복사했습니다'), findsOneWidget);
    });

    testWidgets('주소 글과 복사 단추 대신 공유하기와 수정하기를 나란히 둔다', (tester) async {
      await pumpMeeting(tester, size: const Size(400, 900));

      expect(find.text(link), findsNothing);
      expect(find.byTooltip('링크 복사'), findsNothing);
      final share = tester.getRect(find.text('공유하기'));
      final edit = tester.getRect(find.text('수정하기'));
      expect((share.center.dy - edit.center.dy).abs(), lessThan(1));
      final shareButton = tester.getSize(
        find.ancestor(
          of: find.text('공유하기'),
          matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
        ),
      );
      final editButton = tester.getSize(
        find.ancestor(
          of: find.text('수정하기'),
          matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
        ),
      );
      expect(shareButton.width, closeTo(editButton.width, 1));
      expect(shareButton.height, greaterThanOrEqualTo(48));
    });

    testWidgets('주인이 아니면 수정하기는 막혀 있고 만든 사람만 고칠 수 있다고 알린다', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpMeeting(tester);
      final edit = find.ancestor(
        of: find.text('수정하기'),
        matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
      );

      expect(tester.widget<ButtonStyleButton>(edit).enabled, isFalse);
      expect(find.byTooltip(editHint), findsOneWidget);
      await tester.tap(find.text('수정하기'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.text('모임 설정 화면'), findsNothing);
      semantics.dispose();
    });

    testWidgets('주인이면 수정하기로 모임 설정을 연다', (tester) async {
      meetings.meeting = makeMeeting(ownerId: testUser.id);
      await pumpMeeting(tester);

      expect(find.byTooltip(editHint), findsNothing);
      await tapText(tester, '수정하기');

      expect(find.text('모임 설정 화면'), findsOneWidget);
    });

    testWidgets('비공개 모임이면 단추 아래에 누가 열 수 있는지 알린다', (tester) async {
      meetings.meeting = makeMeeting().copyWith(
        visibilityLevel: VisibilityLevel.allowedEmails,
      );
      await pumpMeeting(tester);

      final note = tester.getRect(find.text('정한 이메일로 로그인한 사람만 열 수 있어요'));
      expect(note.top, greaterThan(tester.getRect(find.text('공유하기')).bottom));
    });
  });
}
