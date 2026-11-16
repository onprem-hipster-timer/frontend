import 'package:dio/dio.dart'
    show DioException, DioExceptionType, RequestOptions;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/app_route.dart';
import 'package:momeet/core/auth/auth_user.dart';
import 'package:momeet/core/providers/retry_policy.dart';
import 'package:momeet/features/meeting/presentation/pages/meeting_page.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_login_panel.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:timezone/data/latest.dart' as tz;

import '../../meeting_fixtures.dart';
import '../../meeting_grid_finders.dart';

/// 서울 2027년 3월 [day]일 [hour]시 [minute]분의 UTC 시각
DateTime seoul(int day, int hour, [int minute = 0]) =>
    DateTime.utc(2027, 3, day, hour - 9, minute);

/// 3월 [day]일 [hour]시부터 30분 결과 칸
AvailabilityCell counted(int day, int hour, int count, {int minute = 0}) =>
    AvailabilityCell(
      startTime: seoul(day, hour, minute),
      endTime: seoul(day, hour, minute + 30),
      count: count,
    );

/// 로그인하지 않은 방문자가 모임 링크를 연다
void main() {
  late FakeMeetingsClient meetings;

  setUpAll(() async {
    tz.initializeTimeZones();
    await initializeDateFormatting('ko');
  });

  setUp(() {
    meetings = FakeMeetingsClient(meeting: makeMeeting())
      ..availability = [
        availabilityOf('a', name: '민수'),
        availabilityOf('b', name: '서연'),
        availabilityOf('g', name: '하준', guest: true),
      ]
      ..resultGrid = [counted(1, 9, 2), counted(1, 9, 3, minute: 30)];
  });

  Future<GoRouter> pumpMeeting(
    WidgetTester tester, {
    Size size = const Size(1280, 900),
    bool signedIn = false,
    ValueNotifier<AuthUser?>? session,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final router = GoRouter(
      initialLocation: '/meetings/meeting-1',
      routes: [
        GoRoute(
          path: AppRoute.calendar.path,
          name: AppRoute.calendar.name,
          builder: (context, state) => const Text('처음 화면'),
        ),
        GoRoute(
          path: AppRoute.login.path,
          name: AppRoute.login.name,
          builder: (context, state) => Text('로그인 화면 ${state.uri}'),
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
        overrides: meetingOverrides(
          meetings: meetings,
          signedIn: signedIn,
          session: session,
        ),
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    return router;
  }

  Finder loginButton() => find.descendant(
    of: find.byType(MeetingLoginPanel),
    matching: find.widgetWithText(FilledButton, '로그인'),
  );

  /// 로그인 상자(의 단추)가 제자리에서 옆으로 밀린 거리
  double loginOffset(WidgetTester tester, double rest) =>
      tester.getTopLeft(loginButton()).dx - rest;

  testWidgets('공개 모임은 제목과 사람 수 격자, 참여자 수, 로그인 상자를 보이고 이름은 보이지 않는다', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pumpMeeting(tester);

    expect(find.widgetWithText(AppBar, '팀 회의'), findsOneWidget);
    expect(find.text('6:00 ~ 18:00'), findsOneWidget);
    expect(find.text('3.1'), findsOneWidget);
    expect(find.text('로그인하면 내 시간을 칠할 수 있습니다'), findsOneWidget);
    expect(find.text('3명 참여 중'), findsOneWidget);
    expect(loginButton(), findsOneWidget);
    expect(cellData('3월 1일 (월) 9:00 ~ 9:30').hint, '참여자 2명');
    expect(cellData('3월 1일 (월) 9:30 ~ 10:00').hint, '참여자 3명');
    expect(find.text('참여자 1명'), findsOneWidget, reason: '색 설명');
    expect(find.text('내 시간'), findsNothing);

    for (final name in ['민수', '서연', '하준']) {
      expect(find.textContaining(name), findsNothing);
    }
    expect(find.text('선택된 일정'), findsNothing);
    expect(find.text('편집'), findsNothing);
    expect(find.byTooltip('내 달력에 일정 만들기'), findsNothing);
    expect(meetings.resultReads, 1);
    expect(meetings.reads, isEmpty);
    expect(meetings.availabilityReads, 0);
    semantics.dispose();
  });

  testWidgets('참여자가 없는 공개 모임은 아직 참여한 사람이 없다고 하고 색 설명이 없다', (tester) async {
    meetings
      ..availability = []
      ..resultGrid = [];
    await pumpMeeting(tester);

    expect(find.text('아직 참여한 사람이 없습니다'), findsOneWidget);
    expect(find.textContaining('참여 중'), findsNothing);
    expect(find.textContaining('참여자 1명'), findsNothing);
    expect(loginButton(), findsOneWidget);
  });

  testWidgets('넓으면 로그인 상자가 격자 오른쪽 맨 위, 좁으면 격자 위다', (tester) async {
    await pumpMeeting(tester);
    final grid = tester.getTopLeft(find.text('내 시간 선택하기'));
    final login = tester.getTopLeft(find.byType(MeetingLoginPanel));
    final people = tester.getTopLeft(find.text('일정 참여자'));
    expect(login.dx, greaterThan(grid.dx + 400));
    expect(login.dy, lessThan(people.dy));

    await pumpMeeting(tester, size: const Size(360, 800));
    final order = [
      find.byType(MeetingLoginPanel),
      find.text('내 시간 선택하기'),
      find.text('일정 참여자', skipOffstage: false),
      find.text('링크', skipOffstage: false),
    ].map((finder) => tester.getTopLeft(finder).dy).toList();
    expect(order, orderedEquals([...order]..sort()));
  });

  testWidgets('칠하려 하면 묻지 않고 로그인 상자를 떨며 요청을 보내지 않는다', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpMeeting(tester);
    final rest = tester.getTopLeft(loginButton()).dx;

    await tester.tapAt(cellCenter(tester, '3월 1일 (월) 9:00 ~ 9:30'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 40));
    expect(loginOffset(tester, rest), isNot(0));
    await tester.pumpAndSettle();

    expect(find.byType(Dialog), findsNothing);
    expect(loginOffset(tester, rest), 0);
    expect(cellData('3월 1일 (월) 9:00 ~ 9:30').value, isEmpty);
    expect(meetings.participations, isEmpty);
    expect(meetings.puts, isEmpty);
    semantics.dispose();
  });

  testWidgets('좁은 화면에서 격자를 내려 본 뒤 칠하려 하면 로그인 상자가 보이게 올린다', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpMeeting(tester, size: const Size(360, 800));
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -600));
    await tester.pumpAndSettle();
    expect(
      tester.getBottomLeft(find.byType(MeetingLoginPanel)).dy,
      lessThan(0),
    );

    await tester.tapAt(cellCenter(tester, '3월 2일 (화) 14:00 ~ 14:30'));
    await tester.pumpAndSettle();

    expect(
      tester.getTopLeft(find.byType(MeetingLoginPanel)).dy,
      greaterThanOrEqualTo(0),
    );
    semantics.dispose();
  });

  testWidgets('애니메이션을 줄였으면 떨지 않고 로그인 상자로 바로 올린다', (tester) async {
    final semantics = tester.ensureSemantics();
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await pumpMeeting(tester, size: const Size(360, 800));
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -600));
    await tester.pumpAndSettle();
    final rest = tester.getTopLeft(loginButton()).dx;

    await tester.tapAt(cellCenter(tester, '3월 2일 (화) 14:00 ~ 14:30'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 40));

    expect(loginOffset(tester, rest), 0);
    expect(
      tester.getTopLeft(find.byType(MeetingLoginPanel)).dy,
      greaterThanOrEqualTo(0),
    );
    semantics.dispose();
  });

  testWidgets('로그인은 로그인 화면으로 가며 이 모임을 돌아올 곳으로 붙인다', (tester) async {
    await pumpMeeting(tester);

    await tester.tap(loginButton());
    await tester.pumpAndSettle();

    expect(
      find.text(
        '로그인 화면 ${AppRoute.login.path}'
        '?redirect=${Uri.encodeComponent('/meetings/meeting-1')}',
      ),
      findsOneWidget,
    );
  });

  testWidgets('공개가 아니거나 없는 모임은 찾을 수 없다고 하고 로그인을 둔다', (tester) async {
    meetings.resultError = notFound();
    await pumpMeeting(tester);

    expect(find.widgetWithText(AppBar, '모임'), findsOneWidget);
    expect(find.text('모임을 찾을 수 없습니다'), findsOneWidget);
    expect(
      find.text('링크가 맞는지 확인해 주세요. 로그인하면 볼 수 있는 모임일 수도 있습니다.'),
      findsOneWidget,
    );
    expect(find.text('다시 시도'), findsNothing);
    expect(find.textContaining('404'), findsNothing);

    await tester.tap(find.widgetWithText(FilledButton, '로그인'));
    await tester.pumpAndSettle();
    expect(find.textContaining('로그인 화면'), findsOneWidget);
  });

  testWidgets('없는 모임과 볼 수 없는 모임은 화면이 같다', (tester) async {
    meetings.resultError = notFound();
    await pumpMeeting(tester);
    final missing = tester
        .widgetList<Text>(find.byType(Text))
        .map((text) => text.data)
        .toList();

    meetings = FakeMeetingsClient(meeting: null);
    await pumpMeeting(tester);
    final hidden = tester
        .widgetList<Text>(find.byType(Text))
        .map((text) => text.data)
        .toList();

    expect(hidden, missing);
  });

  testWidgets('그 밖에 불러오지 못하면 알리고 다시 시도하면 다시 받는다', (tester) async {
    meetings.resultError = DioException(
      requestOptions: RequestOptions(path: '/v1/meetings'),
      type: DioExceptionType.badCertificate,
    );
    await pumpMeeting(tester);

    expect(find.text('모임을 불러오지 못했습니다'), findsOneWidget);
    meetings.resultError = null;
    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();

    expect(find.text('3명 참여 중'), findsOneWidget);
  });

  testWidgets('보는 중에 로그인이 끝나면 이름을 감추고 방문자 화면으로 바뀐다', (tester) async {
    meetings.availability.add(
      availabilityOf('me', name: '지현', userId: 'user-1'),
    );
    final session = ValueNotifier<AuthUser?>(meetingUser());
    addTearDown(session.dispose);
    await pumpMeeting(tester, session: session);
    expect(find.bySemanticsLabel('민수'), findsOneWidget);
    expect(find.text('선택된 일정'), findsOneWidget);

    session.value = null;
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('민수'), findsNothing);
    expect(find.text('선택된 일정'), findsNothing);
    expect(find.text('4명 참여 중'), findsOneWidget);
    expect(loginButton(), findsOneWidget);
    expect(find.textContaining('로그인 화면'), findsNothing);
  });
}
