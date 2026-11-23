import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/domain/meeting_board.dart';
import 'package:momeet/features/meeting/presentation/utils/meeting_run_highlight.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_availability_section.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_name_chip.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_slot_card.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_slots_panel.dart';
import 'package:momeet/shared/ui/ui.dart';
import 'package:timezone/data/latest.dart' as tz;

import '../../meeting_fixtures.dart';
import '../../meeting_grid_finders.dart';
import 'meeting_panels_test.dart' show threePeople;

/// 아무도 되지 않는 칸(칠해도 추천 시간이 바뀌지 않는다)
const quiet = '3월 4일 (목) 17:00 ~ 17:30';

void main() {
  late MeetingRunHighlight highlight;

  setUpAll(tz.initializeTimeZones);

  /// 넓은 화면처럼 왼쪽에 격자, 오른쪽에 추천 시간(남은 높이를 채우고 그 안에서 굴린다)을 두고 같은 강조를 쓴다
  Future<void> pumpBoard(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    highlight = MeetingRunHighlight();
    addTearDown(highlight.dispose);
    var board = MeetingBoard(
      meeting: makeMeeting(),
      availability: threePeople(),
      userId: 'user-1',
      selfName: '지현',
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: MeetingAvailabilitySection(
                    meeting: board.meeting,
                    shading: board,
                    highlight: highlight,
                    onPaint: (changes) => setState(() {
                      board = board.withMine(
                        board.mine.paint({
                          for (final MapEntry(key: cell, value: answer)
                              in changes.entries)
                            cell.span: answer,
                        }),
                      );
                    }),
                  ),
                ),
                SizedBox(
                  width: 380,
                  height: 300,
                  child: MeetingSlotsPanel(
                    board: board,
                    onAddToCalendar: null,
                    highlight: highlight,
                    fill: true,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder card(int i) => find.byType(MeetingSlotCard).at(i);

  ScrollPosition panelScroll(WidgetTester tester) => tester
      .state<ScrollableState>(
        find.descendant(
          of: find.byType(MeetingSlotsPanel),
          matching: find.byType(Scrollable),
        ),
      )
      .position;

  Future<TestGesture> pressMouse(WidgetTester tester, Offset at) =>
      tester.startGesture(
        at,
        kind: PointerDeviceKind.mouse,
        buttons: kPrimaryMouseButton,
      );

  testWidgets('칠하는 동안 마우스가 카드 위를 지나도 이름을 띄우지 않고 격자 강조도 바뀌지 않는다', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pumpBoard(tester);

    final gesture = await pressMouse(tester, cellCenter(tester, quiet));
    await gesture.moveTo(tester.getCenter(card(0)));
    await tester.pumpAndSettle();

    expect(find.byType(MeetingNameChip), findsNothing);
    expect(highlight.hovered, isNull);
    expect(highlight.shown, isNull);
    await gesture.moveTo(cellCenter(tester, quiet));
    await gesture.up();
    await tester.pumpAndSettle();
    semantics.dispose();
  });

  testWidgets('고정해 펼친 카드는 칠해도 풀리지 않고, 끄는 동안만 격자 강조를 감췄다가 손을 떼면 다시 보인다', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pumpBoard(tester);
    await tester.tap(card(0));
    await tester.pumpAndSettle();
    final pinned = highlight.pinned;
    expect(pinned, isNotNull);
    final names = find.byType(MeetingNameChip).evaluate().length;
    expect(names, greaterThan(0));

    final gesture = await pressMouse(tester, cellCenter(tester, quiet));
    await tester.pump();
    expect(highlight.shown, isNull, reason: '끄는 동안은 강조를 감춘다');
    expect(highlight.pinned, pinned);
    await gesture.up();
    await tester.pumpAndSettle();

    expect(cellData(quiet).value, '가능');
    expect(highlight.pinned, pinned);
    expect(highlight.shown, pinned);
    expect(
      find.byType(MeetingNameChip),
      findsNWidgets(names),
      reason: '펼친 그대로',
    );

    // 터치로 칸 하나를 눌러도 그대로다
    await tester.tapAt(cellCenter(tester, quiet));
    await tester.pumpAndSettle();
    expect(highlight.pinned, pinned);
    semantics.dispose();
  });

  testWidgets('칠하는 동안 다른 손가락으로 카드를 눌러도 고정되지 않고 목록도 휠에 굴러가지 않는다', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pumpBoard(tester);
    final list = panelScroll(tester);
    expect(list.maxScrollExtent, greaterThan(0), reason: '목록이 상자보다 길다');

    final gesture = await pressMouse(tester, cellCenter(tester, quiet));
    await tester.pump();
    await tester.tapAt(tester.getCenter(card(0)));
    await tester.pump();
    tester.binding.handlePointerEvent(
      PointerScrollEvent(
        position: tester.getCenter(card(0)),
        scrollDelta: const Offset(0, 80),
      ),
    );
    await tester.pumpAndSettle();

    expect(highlight.pinned, isNull);
    expect(list.pixels, 0);
    await gesture.up();
    await tester.pumpAndSettle();
    semantics.dispose();
  });

  testWidgets('칠하고 저장해도 추천 시간 목록은 굴린 자리에 있다', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpBoard(tester);
    final list = panelScroll(tester);
    list.jumpTo(40);
    await tester.pumpAndSettle();

    final gesture = await pressMouse(tester, cellCenter(tester, quiet));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(cellData(quiet).value, '가능');
    expect(panelScroll(tester).pixels, 40);
    semantics.dispose();
  });
}
