import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/calendar/presentation/pages/schedule_detail_page.dart';
import 'package:momeet/features/calendar/presentation/providers/schedule_detail_providers.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/shared/providers/api_providers.dart';
import 'package:momeet/shared/providers/friend_providers.dart';

import '../../../../helpers/fake_rest_clients.dart';
import '../../../../helpers/pump_app.dart';
import '../../../../helpers/schedule_fixtures.dart';
import '../../../../helpers/timer_fixtures.dart';

/// 일정 상세의 공유 설정
void main() {
  setUpAll(() async {
    await initializeDateFormatting('ko');
  });

  late FakeSchedulesClient schedules;
  late FakeVisibilityClient visibility;

  ScheduleRead schedule({VisibilityLevel? level, String? sourceTodoId}) =>
      makeSchedule(
        id: 'schedule-1',
        title: '팀 회의',
        sourceTodoId: sourceTodoId,
      ).copyWith(visibilityLevel: level, ownerId: 'me');

  Future<void> pumpDetail(WidgetTester tester, ScheduleRead item) async {
    schedules = FakeSchedulesClient([item]);
    visibility = FakeVisibilityClient()
      ..onWrite = (type, id, level) {
        final index = schedules.schedules.indexWhere((s) => s.id == id);
        schedules.schedules[index] = schedules.schedules[index].copyWith(
          visibilityLevel: level,
        );
      };
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      pumpApp(
        const ScheduleDetailPage(scheduleId: 'schedule-1'),
        overrides: [
          schedulesApiProvider.overrideWithValue(schedules),
          visibilityApiProvider.overrideWithValue(visibility),
          scheduleTimersProvider(
            'schedule-1',
          ).overrideWith((ref) async => const []),
          friendsProvider.overrideWith(
            (ref) async => [makeFriend('friend-1', displayName: '영희')],
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder tile() => find.widgetWithText(ListTile, '공유 설정');

  Future<void> openSheet(WidgetTester tester) async {
    await tester.ensureVisible(tile());
    await tester.tap(tile());
    await tester.pumpAndSettle();
  }

  Future<void> tapInSheet(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  IconData? tileIcon(WidgetTester tester) => tester
      .widget<Icon>(
        find.descendant(of: tile(), matching: find.byType(Icon)).first,
      )
      .icon;

  testWidgets('설정이 없으면 공유 설정 줄에 비공개를 보인다', (tester) async {
    await pumpDetail(tester, schedule());

    expect(
      find.descendant(of: tile(), matching: find.text('비공개')),
      findsOneWidget,
    );
    expect(tileIcon(tester), Icons.lock_outline);
  });

  testWidgets('지금 범위를 타이머와 같은 아이콘과 이름으로 보인다', (tester) async {
    await pumpDetail(tester, schedule(level: VisibilityLevel.allowedEmails));

    expect(
      find.descendant(of: tile(), matching: find.text('이메일·도메인 허용')),
      findsOneWidget,
    );
    expect(tileIcon(tester), Icons.alternate_email);
  });

  testWidgets('누르면 전체 공개 없이 네 범위를 고르는 시트를 연다', (tester) async {
    await pumpDetail(tester, schedule());
    await openSheet(tester);

    expect(
      tester
          .widgetList<RadioListTile<VisibilityLevel>>(
            find.byType(RadioListTile<VisibilityLevel>),
          )
          .map((tile) => tile.value),
      [
        VisibilityLevel.private,
        VisibilityLevel.friends,
        VisibilityLevel.selected,
        VisibilityLevel.allowedEmails,
      ],
    );
    expect(find.text('전체 공개'), findsNothing);
    expect(find.textContaining('마감으로 만든 일정'), findsNothing);
    expect(visibility.calls, ['get:schedule/schedule-1']);
  });

  testWidgets('할 일 마감으로 만든 일정은 할 일 내용이 함께 보인다고 저장 전에 알린다', (tester) async {
    await pumpDetail(tester, schedule(sourceTodoId: 'todo-1'));
    await openSheet(tester);

    expect(
      find.text(
        '할 일의 마감으로 만든 일정이라 할 일의 제목·설명·태그·마감 시각도 함께 보입니다. '
        '할 일 자체는 따로 공유해야 보입니다.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('저장하면 그 일정의 설정을 보내고 공유 설정 줄이 새 범위를 보인다', (tester) async {
    await pumpDetail(tester, schedule());
    await openSheet(tester);
    await tapInSheet(
      tester,
      find.widgetWithText(RadioListTile<VisibilityLevel>, '친구 공개'),
    );
    await tapInSheet(tester, find.widgetWithText(FilledButton, '저장'));

    expect(visibility.calls, [
      'get:schedule/schedule-1',
      'put:schedule/schedule-1',
    ]);
    expect(find.byType(BottomSheet), findsNothing);
    expect(
      find.descendant(of: tile(), matching: find.text('친구 공개')),
      findsOneWidget,
    );
    expect(tileIcon(tester), Icons.group_outlined);
  });

  testWidgets('비공개로 되돌리면 설정을 지우고 줄이 비공개를 보인다', (tester) async {
    await pumpDetail(tester, schedule(level: VisibilityLevel.friends));
    visibility.put(
      ResourceType.schedule,
      'schedule-1',
      const VisibilityUpdate(level: VisibilityLevel.friends),
    );
    await openSheet(tester);
    await tapInSheet(
      tester,
      find.widgetWithText(RadioListTile<VisibilityLevel>, '비공개'),
    );
    await tapInSheet(tester, find.widgetWithText(FilledButton, '저장'));

    expect(visibility.calls.last, 'delete:schedule/schedule-1');
    expect(
      find.descendant(of: tile(), matching: find.text('비공개')),
      findsOneWidget,
    );
  });

  testWidgets('저장에 실패하면 시트를 연 채 두고 줄은 그대로다', (tester) async {
    await pumpDetail(tester, schedule());
    visibility.writeError = Exception('서버 오류');
    await openSheet(tester);
    await tapInSheet(
      tester,
      find.widgetWithText(RadioListTile<VisibilityLevel>, '친구 공개'),
    );
    await tapInSheet(tester, find.widgetWithText(FilledButton, '저장'));

    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.text('공유 설정 저장 실패: Exception: 서버 오류'), findsOneWidget);
    Navigator.of(tester.element(find.byType(BottomSheet))).pop();
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: tile(), matching: find.text('비공개')),
      findsOneWidget,
    );
  });
}
