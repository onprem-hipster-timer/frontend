import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/app_route.dart';
import 'package:momeet/core/providers/retry_policy.dart';
import 'package:momeet/features/meeting/presentation/pages/meeting_created_page.dart';

import '../../meeting_fixtures.dart';

void main() {
  late FakeMeetingsClient meetings;
  late GoRouter router;
  late List<String> copied;

  setUp(() {
    meetings = FakeMeetingsClient(meeting: makeMeeting());
    copied = [];
  });

  Future<void> pumpPage(WidgetTester tester) async {
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
    router = GoRouter(
      initialLocation: '/meetings/meeting-1/created',
      routes: [
        GoRoute(
          path: AppRoute.meetingCreated.path,
          name: AppRoute.meetingCreated.name,
          builder: (context, state) =>
              MeetingCreatedPage(meetingId: state.pathParameters['meetingId']!),
        ),
        GoRoute(
          path: AppRoute.meeting.path,
          name: AppRoute.meeting.name,
          builder: (context, state) =>
              Text('모임 화면 ${state.pathParameters['meetingId']}'),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        retry: appRetry,
        overrides: meetingOverrides(meetings: meetings),
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('완료를 알리고 모임 첫날을 달력 그림으로 보인다', (tester) async {
    await pumpPage(tester);

    expect(find.text('모임 생성이 완료되었어요 :)'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('March'), findsOneWidget);
    expect(find.bySemanticsLabel('첫날 3월 1일 (월)'), findsOneWidget);
  });

  testWidgets('링크 공유를 누르면 모임 화면 주소를 복사하고 알린다', (tester) async {
    await pumpPage(tester);

    await tester.tap(find.text('링크 공유'));
    await tester.pumpAndSettle();

    expect(copied, ['https://app.example.com/meetings/meeting-1']);
    expect(find.text('링크를 복사했습니다'), findsOneWidget);
  });

  testWidgets('나의 일정 입력을 누르면 주소가 그 모임의 공유 링크인 모임 화면으로 간다', (tester) async {
    await pumpPage(tester);

    await tester.tap(find.text('나의 일정 입력'));
    await tester.pumpAndSettle();

    expect(find.text('모임 화면 meeting-1'), findsOneWidget);
    expect(
      router.routerDelegate.currentConfiguration.uri.path,
      '/meetings/meeting-1',
    );
  });

  testWidgets('모임을 불러오지 못해도 달력 그림만 비우고 두 버튼은 쓸 수 있다', (tester) async {
    meetings.readError = StateError('없음');
    await pumpPage(tester);

    expect(find.text('March'), findsNothing);
    await tester.tap(find.text('링크 공유'));
    await tester.pumpAndSettle();
    expect(copied, ['https://app.example.com/meetings/meeting-1']);

    await tester.tap(find.text('나의 일정 입력'));
    await tester.pumpAndSettle();
    expect(find.text('모임 화면 meeting-1'), findsOneWidget);
  });
}
