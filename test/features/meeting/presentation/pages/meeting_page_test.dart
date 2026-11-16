import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:momeet/app_route.dart';
import 'package:momeet/core/providers/retry_policy.dart';
import 'package:momeet/features/meeting/presentation/pages/meeting_page.dart';
import 'package:momeet/shared/providers/api_providers.dart';

import '../../meeting_fixtures.dart';

/// 2027년 3월의 [day]일 (3월 1일은 월요일)
DateTime march(int day) => DateTime.utc(2027, 3, day);

void main() {
  late FakeMeetingsClient meetings;

  Future<GoRouter> pumpMeeting(
    WidgetTester tester, {
    String initialLocation = '/meetings/meeting-1',
  }) async {
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
        overrides: [meetingsApiProvider.overrideWithValue(meetings)],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    return router;
  }

  setUp(() => meetings = FakeMeetingsClient(meeting: makeMeeting()));

  testWidgets('주소의 모임 번호로 모임을 불러와 제목·기간·시간·시간 기준을 보인다', (tester) async {
    await pumpMeeting(tester);

    expect(meetings.reads, ['meeting-1']);
    expect(find.text('팀 회의'), findsOneWidget);
    expect(find.text('3월 1일 (월) ~ 3월 5일 (금)'), findsOneWidget);
    expect(find.text('시간별 · 6:00 ~ 18:00'), findsOneWidget);
    expect(find.text('한국 시간 기준'), findsOneWidget);
  });

  testWidgets('시간을 묻지 않은 모임은 시간 범위 없이 방식만 보인다', (tester) async {
    meetings.meeting = makeMeeting(
      startDate: march(1),
      endDate: march(7),
      availableDays: [0, 1, 2, 3, 4, 5, 6],
      startTime: '00:00:00',
      endTime: '00:00:00',
    );
    await pumpMeeting(tester);

    expect(find.text('요일별'), findsOneWidget);
    expect(find.textContaining(':00'), findsNothing);
  });

  testWidgets('불러오지 못하면 알리고 다시 시도하면 다시 받는다', (tester) async {
    meetings.readError = StateError('없음');
    await pumpMeeting(tester);

    expect(find.text('모임을 불러오지 못했습니다'), findsOneWidget);

    meetings.readError = null;
    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();

    expect(find.text('팀 회의'), findsOneWidget);
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
