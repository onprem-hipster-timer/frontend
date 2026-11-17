import 'dart:async';

import 'package:dio/dio.dart'
    show DioException, DioExceptionType, RequestOptions;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/app_route.dart';
import 'package:momeet/core/providers/retry_policy.dart';
import 'package:momeet/features/mypage/mypage.dart';
import 'package:momeet/features/mypage/presentation/pages/my_meetings_page.dart';
import 'package:momeet/features/mypage/presentation/widgets/my_meetings_section.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/shared/providers/api_providers.dart';

import '../../../../helpers/fake_rest_clients.dart';
import '../../../../helpers/kratos_mocks.dart';
import '../../../meeting/meeting_fixtures.dart';

/// 2027년 1월 [day]일에 만든 [title] 모임
MeetingRead made(
  String title,
  int day, {
  MeetingMode mode = MeetingMode.hourly,
  VisibilityLevel? level = VisibilityLevel.public,
}) => makeMeeting(
  id: 'meeting-$day',
  title: title,
  mode: mode,
  createdAt: DateTime.utc(2027, 1, day),
  visibilityLevel: level,
);

void main() {
  late KratosTestHarness harness;
  late FakeMeetingsClient meetings;
  late GoRouter router;

  setUpAll(() async {
    registerKratosFallbacks();
    await initializeDateFormatting('ko');
  });

  setUp(() async {
    harness = await KratosTestHarness.create();
    meetings = FakeMeetingsClient();
  });

  Future<void> pumpMyPage(
    WidgetTester tester, {
    Size size = const Size(480, 1600),
    bool settle = true,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    router = GoRouter(
      initialLocation: AppRoute.mypage.path,
      routes: [
        GoRoute(
          path: AppRoute.mypage.path,
          name: AppRoute.mypage.name,
          builder: (context, state) => const MyPage(),
          routes: [
            GoRoute(
              path: 'meetings',
              name: AppRoute.myMeetings.name,
              builder: (context, state) => const MyMeetingsPage(),
            ),
          ],
        ),
        GoRoute(
          path: AppRoute.meetings.path,
          name: AppRoute.meetings.name,
          builder: (context, state) => const Text('모임 만들기 화면'),
        ),
        GoRoute(
          path: AppRoute.meeting.path,
          name: AppRoute.meeting.name,
          builder: (context, state) => Scaffold(
            appBar: AppBar(),
            body: Text('모임 화면 ${state.pathParameters['meetingId']}'),
          ),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        retry: appRetry,
        overrides: [
          ...harness.overrides,
          meetingsApiProvider.overrideWithValue(meetings),
          todosApiProvider.overrideWithValue(FakeTodosClient()),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    if (settle) await tester.pumpAndSettle();
  }

  /// 내 모임 칸의 제목들, 위에서부터
  List<String> shownTitles(WidgetTester tester, List<String> titles) {
    final found = [
      for (final title in titles)
        if (find.text(title).evaluate().isNotEmpty) title,
    ];
    return found..sort(
      (a, b) => tester
          .getTopLeft(find.text(a))
          .dy
          .compareTo(tester.getTopLeft(find.text(b)).dy),
    );
  }

  testWidgets('만든 모임을 새로 만든 순으로 제목, 기간과 방식, 공개 여부와 함께 보인다', (tester) async {
    meetings.mine = [
      made('주간 회의', 3, mode: MeetingMode.daily),
      made('킥오프', 9, level: VisibilityLevel.allowedEmails),
      made('회고', 5, mode: MeetingMode.weekly, level: VisibilityLevel.private),
    ];
    await pumpMyPage(tester);

    expect(find.text('내 모임'), findsOneWidget);
    expect(shownTitles(tester, ['주간 회의', '킥오프', '회고']), ['킥오프', '회고', '주간 회의']);
    expect(find.text('3.1(월)–3.5(금) · 시간별'), findsOneWidget);
    expect(find.text('3.1(월)–3.5(금) · 날짜별'), findsOneWidget);
    expect(find.text('3.1(월)–3.5(금) · 요일별'), findsOneWidget);
    expect(find.text('공개'), findsOneWidget);
    expect(find.text('비공개'), findsNWidgets(2));
    expect(find.text('모두 보기'), findsNothing);
  });

  testWidgets('여섯 개 이상이면 다섯 개만 보이고 모두 보기로 전체 목록을 연다', (tester) async {
    meetings.mine = [for (var day = 1; day <= 7; day++) made('모임 $day', day)];
    await pumpMyPage(tester);

    expect(
      shownTitles(tester, [for (var day = 1; day <= 7; day++) '모임 $day']),
      ['모임 7', '모임 6', '모임 5', '모임 4', '모임 3'],
    );
    final all = find.text('모두 보기 (7)');
    await tester.ensureVisible(all);
    await tester.pumpAndSettle();
    await tester.tap(all);
    await tester.pumpAndSettle();

    expect(find.byType(MyMeetingsPage), findsOneWidget);
    for (var day = 1; day <= 7; day++) {
      await tester.scrollUntilVisible(
        find.text('모임 $day'),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('모임 $day'), findsOneWidget);
    }
  });

  testWidgets('모임을 누르면 모임 화면을 위에 열고 뒤로 가면 마이페이지다', (tester) async {
    meetings.mine = [made('킥오프', 9)];
    await pumpMyPage(tester);

    await tester.tap(find.text('킥오프'));
    await tester.pumpAndSettle();
    expect(find.text('모임 화면 meeting-9'), findsOneWidget);

    router.pop();
    await tester.pumpAndSettle();
    expect(find.text('내 모임'), findsOneWidget);
  });

  testWidgets('불러오는 동안 자리를 보이고, 다 받으면 목록이다', (tester) async {
    final semantics = tester.ensureSemantics();
    meetings.listGate = Completer<void>();
    meetings.mine = [made('킥오프', 9)];
    await pumpMyPage(tester, settle: false);
    await tester.pump();

    expect(find.bySemanticsLabel('내 모임을 불러오는 중'), findsOneWidget);
    meetings.listGate!.complete();
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('내 모임을 불러오는 중'), findsNothing);
    expect(find.text('킥오프'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('만든 모임이 없으면 알리고 모임 만들기로 간다', (tester) async {
    await pumpMyPage(tester);

    expect(find.text('아직 만든 모임이 없어요'), findsOneWidget);
    await tester.tap(find.text('모임 만들기'));
    await tester.pumpAndSettle();
    expect(find.text('모임 만들기 화면'), findsOneWidget);
  });

  testWidgets('불러오지 못하면 알리고 다시 시도하면 다시 받는다', (tester) async {
    meetings.listError = DioException(
      requestOptions: RequestOptions(path: '/v1/meetings'),
      type: DioExceptionType.badResponse,
    );
    await pumpMyPage(tester);

    expect(find.text('내 모임을 불러오지 못했습니다'), findsOneWidget);
    final reads = meetings.listReads;
    meetings
      ..listError = null
      ..mine = [made('킥오프', 9)];
    await tester.tap(
      find.descendant(
        of: find.byType(MyMeetingsSection),
        matching: find.text('다시 시도'),
      ),
    );
    await tester.pumpAndSettle();

    expect(meetings.listReads, reads + 1);
    expect(find.text('킥오프'), findsOneWidget);
  });
}
