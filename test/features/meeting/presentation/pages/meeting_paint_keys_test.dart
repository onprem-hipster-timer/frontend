import 'package:flutter/gestures.dart';
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

/// 서울 2027년 3월 [day]일 [hour]시 [minute]분의 UTC 시각
DateTime seoul(int day, int hour, [int minute = 0]) =>
    DateTime.utc(2027, 3, day, hour - 9, minute);

const first = '3월 1일 (월) 6:00 ~ 6:30';
const second = '3월 1일 (월) 6:30 ~ 7:00';
const third = '3월 1일 (월) 7:00 ~ 7:30';
const fourth = '3월 1일 (월) 7:30 ~ 8:00';

const ctrl = LogicalKeyboardKey.controlLeft;
const cmd = LogicalKeyboardKey.metaLeft;
const shift = LogicalKeyboardKey.shiftLeft;
const z = LogicalKeyboardKey.keyZ;
const y = LogicalKeyboardKey.keyY;

/// [keys]를 차례로 누른 뒤 거꾸로 뗀다(마지막 키가 단축키의 글자)
Future<void> press(WidgetTester tester, List<LogicalKeyboardKey> keys) async {
  for (final key in keys) {
    await tester.sendKeyDownEvent(key);
  }
  for (final key in keys.reversed) {
    await tester.sendKeyUpEvent(key);
  }
  await tester.pump();
}

/// [label] 칸의 내 답('가능', 답하지 않았으면 빈 글)
String valueOf(String label) => cellData(label).value;

void main() {
  late FakeMeetingsClient meetings;

  setUpAll(() async {
    tz.initializeTimeZones();
    await initializeDateFormatting('ko');
  });

  setUp(() => meetings = FakeMeetingsClient(meeting: makeMeeting()));

  /// 회원으로 모임 화면을 연다(좁은 화면이라 격자가 맨 앞이다)
  Future<void> pumpMeeting(WidgetTester tester) async {
    tester.view.physicalSize = const Size(400, 800);
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
  }

  /// 저장을 기다렸다가 끝낸다
  Future<void> settleSave(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
  }

  Finder finish() => find.widgetWithText(FilledButton, '저장하기');

  testWidgets('칠한 뒤 Ctrl+Z는 칠하기 전으로 되돌리고 칠한 것처럼 저장한다', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpMeeting(tester);
    await tester.tapAt(cellCenter(tester, first));
    await settleSave(tester);
    expect(meetings.puts, hasLength(1));
    expect(find.text('자동 저장됐어요'), findsOneWidget);

    await press(tester, [ctrl, z]);
    expect(valueOf(first), isEmpty);
    expect(find.text('자동 저장 중'), findsOneWidget);

    await settleSave(tester);
    expect(meetings.puts, hasLength(2));
    expect(meetings.puts.last.$2, isEmpty);
    expect(find.text('자동 저장됐어요'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('입력을 마친 뒤 Ctrl+Z로 되돌리면 저장하기가 다시 나타난다', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpMeeting(tester);
    await tester.tapAt(cellCenter(tester, first));
    await tester.pump();
    await tester.tap(finish());
    await tester.pumpAndSettle();
    expect(find.text('입력을 마쳤어요'), findsOneWidget);
    expect(finish(), findsNothing);

    await press(tester, [ctrl, z]);

    expect(finish(), findsOneWidget);
    expect(find.text('입력을 마쳤어요'), findsNothing);
    semantics.dispose();
  });

  testWidgets('Ctrl+Y와 Ctrl+Shift+Z는 되돌린 것을 다시 칠하고 저장한다', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpMeeting(tester);
    await tester.tapAt(cellCenter(tester, first));
    await tester.pump();

    await press(tester, [ctrl, z]);
    expect(valueOf(first), isEmpty);
    await press(tester, [ctrl, y]);
    expect(valueOf(first), '가능');
    await press(tester, [ctrl, z]);
    expect(valueOf(first), isEmpty);
    await press(tester, [ctrl, shift, z]);
    expect(valueOf(first), '가능');

    await settleSave(tester);
    expect(
      [
        for (final slot in meetings.puts.last.$2)
          (slot.startTime.toUtc(), slot.endTime.toUtc()),
      ],
      [(seoul(1, 6), seoul(1, 6, 30))],
    );
    semantics.dispose();
  });

  testWidgets('macOS는 Cmd+Z로 되돌리고 Cmd+Shift+Z로 다시 칠하며 Ctrl+Z로는 되돌리지 않는다', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pumpMeeting(tester);
    await tester.tapAt(cellCenter(tester, first));
    await tester.pump();

    await press(tester, [ctrl, z]);
    expect(valueOf(first), '가능');
    await press(tester, [cmd, z]);
    expect(valueOf(first), isEmpty);
    await press(tester, [cmd, shift, z]);
    expect(valueOf(first), '가능');
    semantics.dispose();
  }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));

  testWidgets('두 번 칠하면 나중 것부터 하나씩 되돌리고, 되돌릴 것이 없으면 저장하지 않는다', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpMeeting(tester);
    await tester.tapAt(cellCenter(tester, first));
    await tester.tapAt(cellCenter(tester, second));
    await tester.pump();

    await press(tester, [ctrl, z]);
    expect(valueOf(second), isEmpty);
    expect(valueOf(first), '가능');
    await press(tester, [ctrl, z]);
    expect(valueOf(first), isEmpty);
    await settleSave(tester);
    expect(meetings.puts.single.$2, isEmpty);

    await press(tester, [ctrl, z]);
    await settleSave(tester);
    expect(meetings.puts, hasLength(1));
    expect(find.text('자동 저장됐어요'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('끌어 칠하는 동안은 되돌리지 않고, 손을 떼면 그 붓질을 하나로 되돌린다', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpMeeting(tester);
    await tester.tapAt(cellCenter(tester, first));
    await tester.pump();

    final gesture = await tester.startGesture(
      cellCenter(tester, third),
      kind: PointerDeviceKind.mouse,
      buttons: kPrimaryMouseButton,
    );
    await tester.pump();
    await gesture.moveTo(cellCenter(tester, fourth));
    await tester.pump();
    await press(tester, [ctrl, z]);
    expect(valueOf(first), '가능', reason: '끄는 동안에는 앞의 칠하기를 되돌리지 않는다');

    await gesture.up();
    await tester.pump();
    expect(valueOf(third), '가능');
    expect(valueOf(fourth), '가능');

    await press(tester, [ctrl, z]);
    expect(valueOf(third), isEmpty);
    expect(valueOf(fourth), isEmpty);
    expect(valueOf(first), '가능');
    semantics.dispose();
  });

  testWidgets('화면을 열면 격자를 누르지 않아도(스크린 리더로 칠해도) 키를 받는다', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpMeeting(tester);
    tester.semantics.tap(find.semantics.byLabel(first));
    await tester.pump();
    expect(valueOf(first), '가능');

    await press(tester, [ctrl, z]);

    expect(valueOf(first), isEmpty);
    semantics.dispose();
  });

  testWidgets('시트의 글 칸에 초점이 있으면 Ctrl+Z는 글 칸이 받고, 시트를 닫으면 다시 칠한 것을 되돌린다', (
    tester,
  ) async {
    meetings.availability = [
      availabilityOf('participant-user-1', name: '지현', userId: 'user-1'),
    ];
    final semantics = tester.ensureSemantics();
    await pumpMeeting(tester);
    await tester.tapAt(cellCenter(tester, first));
    await settleSave(tester);
    expect(meetings.puts, hasLength(1));

    await tester.ensureVisible(find.text('편집'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('편집'));
    await tester.pumpAndSettle();
    // 글 칸은 바뀐 글을 잠시 뒤에 자기 되돌리기 기록에 남긴다
    await tester.pump(const Duration(seconds: 1));
    await tester.enterText(find.byType(TextFormField), '새 이름');
    await tester.pump(const Duration(seconds: 1));

    await press(tester, [ctrl, z]);
    expect(find.widgetWithText(TextFormField, '지현'), findsOneWidget);
    await settleSave(tester);
    expect(meetings.puts, hasLength(1), reason: '칠한 것은 되돌리지 않았다');

    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    await press(tester, [ctrl, z]);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, 5000));
    await tester.pumpAndSettle();

    expect(valueOf(first), isEmpty);
    semantics.dispose();
  });
}
