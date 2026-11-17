import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/domain/meeting_board.dart';
import 'package:momeet/features/meeting/domain/meeting_grid.dart';
import 'package:momeet/features/meeting/domain/meeting_runs.dart';
import 'package:momeet/features/meeting/presentation/utils/meeting_run_highlight.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_availability_section.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_grid_geometry.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_grid_painter.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_slot_card.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_slots_panel.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/shared/ui/ui.dart';
import 'package:timezone/data/latest.dart' as tz;

import '../../meeting_fixtures.dart';
import '../../meeting_grid_finders.dart';

/// 서울 2027년 3월 [day]일 [hour]시의 UTC 시각
DateTime seoul(int day, int hour) => DateTime.utc(2027, 3, day, hour - 9);

void main() {
  setUpAll(tz.initializeTimeZones);

  group('강조할 칸의 사각형', () {
    MeetingGridGeometry geometryOf(
      MeetingRead meeting,
      MeetingCellShape shape,
    ) => MeetingGridGeometry(
      MeetingGrid.of(meeting),
      shape,
      700,
      TextScaler.noScaling,
    );

    test('날짜별은 한 주를 넘어 이어지면 줄마다 하나씩 모두 두른다', () {
      final geometry = geometryOf(
        makeMeeting(
          endDate: DateTime.utc(2027, 3, 14),
          mode: MeetingMode.daily,
          startTime: '00:00:00',
          endTime: '00:00:00',
        ),
        MeetingCellShape.daily,
      );
      final grid = geometry.grid;
      // 3월 5일(금)~9일(화): 첫 줄의 금·토, 다음 줄의 일~화
      final first = grid.cells.firstWhere((c) => c.day.day == 5).index;
      final last = grid.cells.firstWhere((c) => c.day.day == 9).index;
      final rects = geometry.runRects(first, last);

      expect(rects, hasLength(2));
      expect(rects.first.top, lessThan(rects.last.top));
      final cells = grid.cells.sublist(first, last + 1);
      for (final cell in cells) {
        final rect = geometry.rectOf(cell.column, cell.row);
        expect(
          rects.any((r) => r.contains(rect.center)),
          isTrue,
          reason: '${cell.day}',
        );
      }
    });

    test('요일별은 이어진 요일을 한 줄로 두르고, 시간별은 열 하나로 두른다', () {
      final weekly = geometryOf(
        makeMeeting(
          endDate: DateTime.utc(2027, 3, 7),
          mode: MeetingMode.weekly,
          startTime: '00:00:00',
          endTime: '00:00:00',
        ),
        MeetingCellShape.weekly,
      );
      expect(weekly.runRects(1, 4), hasLength(1));

      final hourly = geometryOf(
        makeMeeting(),
        MeetingCellShape.hourly(slotMinutes: 30, columnGap: 6),
      );
      final rects = hourly.runRects(2, 5);
      expect(rects, hasLength(1));
      expect(rects.single.height, closeTo(4 * hourly.cellHeight, 0.01));
    });
  });

  group('카드와 격자', () {
    late MeetingRunHighlight highlight;
    late MeetingBoard board;

    setUp(() => highlight = MeetingRunHighlight());
    tearDown(() => highlight.dispose());

    /// 3월 1일 9~12시에 셋, 3월 2일 10~11시에 둘이 되는 모임의 격자와 추천 시간
    Future<void> pumpBoth(
      WidgetTester tester, {
      Size size = const Size(800, 2200),
    }) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      board = MeetingBoard(
        meeting: makeMeeting(),
        availability: [
          availabilityOf('a', slots: [(seoul(1, 9), seoul(1, 12))]),
          availabilityOf(
            'b',
            slots: [(seoul(1, 9), seoul(1, 12)), (seoul(2, 10), seoul(2, 11))],
          ),
          availabilityOf(
            'c',
            slots: [(seoul(1, 9), seoul(1, 12)), (seoul(2, 10), seoul(2, 11))],
          ),
        ],
        userId: 'user-1',
        selfName: '지현',
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: StatefulBuilder(
                builder: (context, setState) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    MeetingAvailabilitySection(
                      meeting: board.meeting,
                      shading: board,
                      highlight: highlight,
                      onPaint: (changes) => setState(
                        () => board = board.withMine(
                          board.mine.paint({
                            for (final MapEntry(key: cell, value: answer)
                                in changes.entries)
                              cell.span: answer,
                          }),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    MeetingSlotsPanel(
                      board: board,
                      highlight: highlight,
                      onAddToCalendar: null,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    MeetingRun runAt(int day) => board
        .runs(MeetingRunOrder.date)
        .firstWhere((run) => run.first.day.day == day);

    Finder card(int index) => find.byType(MeetingSlotCard).at(index);

    /// [index] 카드가 스크린 리더에 고른(고정한) 카드로 읽히는지
    bool? selected(WidgetTester tester, int index) => tester
        .widget<Semantics>(
          find.descendant(
            of: card(index),
            matching: find.byWidgetPredicate(
              (widget) =>
                  widget is Semantics && widget.properties.expanded != null,
            ),
          ),
        )
        .properties
        .selected;

    testWidgets('마우스를 올리면 그 카드의 칸을 정확히 강조하고 떠나면 지운다', (tester) async {
      await pumpBoth(tester);
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(mouse.removePointer);
      await mouse.addPointer(location: Offset.zero);

      await mouse.moveTo(tester.getCenter(card(0)));
      await tester.pump();
      final run = runAt(1);
      expect(highlight.shown, meetingRunKey(run));
      expect(
        board.grid.cells.sublist(
          highlight.shown!.first,
          highlight.shown!.last + 1,
        ),
        run.cells,
      );
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is CustomPaint && widget.painter is MeetingGridPainter,
        ),
        paints..something(
          (method, args) =>
              method == #drawRRect &&
              (args[1] as Paint).style == PaintingStyle.stroke &&
              (args[1] as Paint).strokeWidth == 3,
        ),
      );

      await mouse.moveTo(Offset.zero);
      await tester.pump();
      expect(highlight.shown, isNull);
    });

    testWidgets('누르면 고정하고 이름을 펼치며, 다시 누르면 풀고, 다른 카드를 누르면 옮긴다', (tester) async {
      await pumpBoth(tester);

      await tester.tap(card(0));
      await tester.pumpAndSettle();
      expect(highlight.pinned, meetingRunKey(runAt(1)));
      expect(selected(tester, 0), isTrue);

      await tester.tap(card(1));
      await tester.pumpAndSettle();
      expect(highlight.pinned, meetingRunKey(runAt(2)));
      expect(selected(tester, 0), isFalse);
      expect(selected(tester, 1), isTrue);

      await tester.tap(card(1));
      await tester.pumpAndSettle();
      expect(highlight.pinned, isNull);
    });

    testWidgets('칠하기 시작하면 고정을 푼다', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpBoth(tester);
      await tester.tap(card(0));
      await tester.pumpAndSettle();
      expect(highlight.pinned, isNotNull);

      await tester.ensureVisible(find.text('3.4'));
      await tester.tapAt(cellCenter(tester, '3월 4일 (목) 6:00 ~ 6:30'));
      await tester.pumpAndSettle();

      expect(highlight.pinned, isNull);
      semantics.dispose();
    });

    testWidgets('격자 아래의 카드를 누르면 그 칸이 보이게 화면을 굴린다', (tester) async {
      await pumpBoth(tester, size: const Size(400, 700));
      final scroll = tester.state<ScrollableState>(
        find.byType(Scrollable).first,
      );
      await tester.ensureVisible(card(0));
      await tester.pumpAndSettle();
      final before = scroll.position.pixels;
      expect(before, greaterThan(0));

      await tester.tap(card(0));
      await tester.pumpAndSettle();

      expect(scroll.position.pixels, lessThan(before));
    });
  });
}
