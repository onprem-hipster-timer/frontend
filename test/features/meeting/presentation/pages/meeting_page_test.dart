import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/app_route.dart';
import 'package:momeet/core/providers/retry_policy.dart';
import 'package:momeet/features/meeting/presentation/pages/meeting_page.dart';
import 'package:momeet/shared/providers/api_providers.dart';
import 'package:timezone/data/latest.dart' as tz;

import '../../../../helpers/fake_rest_clients.dart';
import '../../meeting_fixtures.dart';
import '../../meeting_grid_finders.dart';

/// 서울 2027년 3월 [day]일 [hour]시의 UTC 시각
DateTime seoul(int day, int hour) => DateTime.utc(2027, 3, day, hour - 9);

void main() {
  late FakeMeetingsClient meetings;

  setUpAll(() async {
    tz.initializeTimeZones();
    await initializeDateFormatting('ko');
  });

  setUp(() => meetings = FakeMeetingsClient(meeting: makeMeeting()));

  Future<GoRouter> pumpMeeting(
    WidgetTester tester, {
    String initialLocation = '/meetings/meeting-1',
    Size? size,
  }) async {
    if (size != null) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
    }
    final router = GoRouter(
      initialLocation: initialLocation,
      routes: [
        GoRoute(
          path: AppRoute.calendar.path,
          name: AppRoute.calendar.name,
          builder: (context, state) => const Text('처음 화면'),
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
          ...meetingOverrides(meetings: meetings),
          schedulesApiProvider.overrideWithValue(FakeSchedulesClient()),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    return router;
  }

  testWidgets('주소의 모임을 불러와 제목, 하루 범위, 시간 기준과 격자를 보인다', (tester) async {
    await pumpMeeting(tester);

    expect(meetings.reads, ['meeting-1']);
    expect(meetings.availabilityReads, 1);
    expect(find.widgetWithText(AppBar, '팀 회의'), findsOneWidget);
    expect(find.text('내 시간 선택하기'), findsOneWidget);
    expect(find.text('6:00 ~ 18:00'), findsOneWidget);
    expect(find.text('한국 시간 기준'), findsOneWidget);
    expect(find.text('3.1'), findsOneWidget);
  });

  testWidgets('터치 기기는 길게 누른 채 끌기를 알린다', (tester) async {
    await pumpMeeting(tester);

    expect(find.text('길게 누른 채 끌면 여러 칸을 칠합니다'), findsOneWidget);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  testWidgets('마우스 기기는 누른 채 끌기를 알린다', (tester) async {
    await pumpMeeting(tester);

    expect(find.text('누른 채 끌면 여러 칸을 칠합니다'), findsOneWidget);
  }, variant: TargetPlatformVariant.only(TargetPlatform.windows));

  testWidgets('칸을 누르면 저장 중이다가 참여하고 저장한 뒤 저장됨과 내 이름 칩을 보인다', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpMeeting(tester);
    expect(find.text('편집'), findsNothing);

    await tester.tapAt(cellCenter(tester, '3월 1일 (월) 6:00 ~ 6:30'));
    await tester.pump();
    expect(find.text('저장 중'), findsOneWidget);
    expect(cellData('3월 1일 (월) 6:00 ~ 6:30').value, '내 시간');

    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(meetings.participations, ['지현']);
    expect(meetings.puts, hasLength(1));
    expect(find.text('저장됨'), findsOneWidget);
    expect(find.bySemanticsLabel('지현, 나'), findsOneWidget);
    expect(find.text('편집'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('저장하지 못하면 칠한 칸을 두고 알리며 다시 시도하면 저장한다', (tester) async {
    final semantics = tester.ensureSemantics();
    meetings.putError = Exception('끊김');
    await pumpMeeting(tester);

    await tester.tapAt(cellCenter(tester, '3월 1일 (월) 6:00 ~ 6:30'));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.text('저장하지 못했습니다'), findsOneWidget);
    expect(cellData('3월 1일 (월) 6:00 ~ 6:30').value, '내 시간');

    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();
    expect(meetings.puts, hasLength(2));
    expect(find.text('저장됨'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('카드의 내 달력에 일정 만들기는 모임 제목과 그 시간으로 새 일정을 연다', (tester) async {
    meetings.availability = [
      availabilityOf('a', name: '민수', slots: [(seoul(1, 9), seoul(1, 10))]),
      availabilityOf('b', name: '서연', slots: [(seoul(1, 9), seoul(1, 10))]),
    ];
    await pumpMeeting(tester);

    final button = find.byTooltip('내 달력에 일정 만들기');
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
    await tester.tap(button);
    await tester.pumpAndSettle();

    expect(find.text('새 일정'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, '팀 회의'), findsOneWidget);
    final start = seoul(1, 9).toLocal();
    final end = seoul(1, 10).toLocal();
    String hm(DateTime t) =>
        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    Finder inSheet(String text) => find.descendant(
      of: find.byType(BottomSheet),
      matching: find.textContaining(text),
    );
    expect(inSheet(hm(start)), findsOneWidget);
    expect(inSheet(hm(end)), findsOneWidget);
  });

  testWidgets('편집은 이 모임에서 보일 내 이름을 지금 이름으로 채워 연다', (tester) async {
    meetings.availability = [
      availabilityOf('participant-user-1', name: '지현', userId: 'user-1'),
    ];
    await pumpMeeting(tester);

    await tester.ensureVisible(find.text('편집'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('편집'));
    await tester.pumpAndSettle();

    expect(find.text('내 이름'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, '지현'), findsOneWidget);
  });

  testWidgets('링크 상자는 모임 링크를 보이고 복사한다', (tester) async {
    final copied = <String>[];
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
    await pumpMeeting(tester);

    const link = 'https://app.example.com/meetings/meeting-1';
    expect(find.text(link), findsOneWidget);
    await tester.ensureVisible(find.byTooltip('링크 복사'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('링크 복사'));
    await tester.pumpAndSettle();

    expect(copied, [link]);
    expect(find.text('링크를 복사했습니다'), findsOneWidget);
  });

  testWidgets('넓으면 격자 오른쪽에 링크·일정 참여자·선택된 일정을 둔다', (tester) async {
    await pumpMeeting(tester, size: const Size(1280, 800));

    final grid = tester.getTopLeft(find.text('내 시간 선택하기'));
    final link = tester.getTopLeft(find.text('링크'));
    final people = tester.getTopLeft(find.text('일정 참여자'));
    final slots = tester.getTopLeft(find.text('선택된 일정'));
    expect(link.dx, greaterThan(grid.dx + 400));
    expect(people.dx, link.dx);
    expect([
      link.dy,
      people.dy,
      slots.dy,
    ], orderedEquals([link.dy, people.dy, slots.dy]..sort()));
  });

  testWidgets('좁으면 격자, 선택된 일정, 일정 참여자, 링크 순서로 쌓는다', (tester) async {
    await pumpMeeting(tester, size: const Size(360, 800));

    final order = [
      for (final title in ['내 시간 선택하기', '선택된 일정', '일정 참여자', '링크'])
        tester.getTopLeft(find.text(title, skipOffstage: false)),
    ];
    for (var i = 1; i < order.length; i++) {
      expect(order[i].dy, greaterThan(order[i - 1].dy));
      expect(order[i].dx, lessThan(40));
    }
  });

  testWidgets('불러오지 못하면 알리고 다시 시도하면 다시 받는다', (tester) async {
    meetings.readError = StateError('없음');
    await pumpMeeting(tester);

    expect(find.text('모임을 불러오지 못했습니다'), findsOneWidget);

    meetings.readError = null;
    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, '팀 회의'), findsOneWidget);
    expect(meetings.reads, hasLength(2));
  });

  testWidgets('링크로 바로 열어 돌아갈 곳이 없으면 처음 화면으로 가는 버튼을 둔다', (tester) async {
    await pumpMeeting(tester);

    await tester.tap(find.byTooltip('처음 화면으로'));
    await tester.pumpAndSettle();

    expect(find.text('처음 화면'), findsOneWidget);
  });

  testWidgets('다른 화면에서 열었으면 뒤로 가기를 둔다', (tester) async {
    final router = await pumpMeeting(tester, initialLocation: '/');
    router.pushNamed(
      AppRoute.meeting.name,
      pathParameters: {'meetingId': 'meeting-1'},
    );
    await tester.pumpAndSettle();

    expect(find.byTooltip('처음 화면으로'), findsNothing);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(find.text('처음 화면'), findsOneWidget);
  });
}
