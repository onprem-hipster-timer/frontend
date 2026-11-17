import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/domain/meeting_board.dart';
import 'package:momeet/features/meeting/presentation/utils/meeting_run_highlight.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_name_chip.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_slot_card.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_slots_panel.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/shared/ui/ui.dart';
import 'package:timezone/data/latest.dart' as tz;

import '../../meeting_fixtures.dart';

/// 서울 2027년 3월 [day]일 [hour]시의 UTC 시각
DateTime seoul(int day, int hour) => DateTime.utc(2027, 3, day, hour - 9);

/// [mode] 모임: 민수(주인)·서연이 3월 2일(시간별은 10~12시, 그 밖은 2~3일)에 되고 다현은 그때 안 된다
MeetingBoard boardIn(MeetingMode mode) {
  final hourly = mode == MeetingMode.hourly;
  final when = hourly
      ? (seoul(2, 10), seoul(2, 12))
      : (seoul(2, 0), seoul(4, 0));
  return MeetingBoard(
    meeting: makeMeeting(
      mode: mode,
      endDate: hourly ? null : DateTime.utc(2027, 3, 7),
      startTime: hourly ? '06:00:00' : '00:00:00',
      endTime: hourly ? '18:00:00' : '00:00:00',
    ),
    availability: [
      availabilityOf(
        'a',
        name: '민수',
        userId: 'owner-1',
        owner: true,
        slots: [when],
      ),
      availabilityOf('b', name: '서연', slots: [when]),
      availabilityOf('d', name: '다현', unavailable: [when]),
    ],
    userId: 'user-1',
    selfName: '지현',
  );
}

/// 화면 배치: 넓은 화면 옆 칸(남은 높이를 채우고 그 안에서 굴린다), 좁은 화면의 한 줄·여러 줄 카드
enum Layout { wideSide, narrowPhone, narrowTablet }

Future<void> pumpIn(WidgetTester tester, Layout layout, MeetingBoard board) {
  final (view, panel) = switch (layout) {
    Layout.wideSide => (const Size(1280, 800), (380.0, 500.0)),
    Layout.narrowPhone => (const Size(360, 800), (328.0, null)),
    Layout.narrowTablet => (const Size(700, 800), (668.0, null)),
  };
  tester.view.physicalSize = view;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final slots = MeetingSlotsPanel(
    board: board,
    onAddToCalendar: (_) {},
    highlight: MeetingRunHighlight(),
    fill: layout == Layout.wideSide,
  );
  return tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(
        body: layout == Layout.wideSide
            ? Align(
                alignment: Alignment.topRight,
                child: SizedBox(
                  width: panel.$1,
                  height: panel.$2,
                  child: slots,
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: SizedBox(width: panel.$1, child: slots),
              ),
      ),
    ),
  );
}

/// [box] 안의 마지막 내용(글자, 아이콘, 이름 칩, 단추)의 아래 끝
double contentBottom(WidgetTester tester, Finder box) => [
  for (final element
      in find
          .descendant(
            of: box,
            matching: find.byWidgetPredicate(
              (widget) =>
                  widget is Text ||
                  widget is Icon ||
                  widget is MeetingNameChip ||
                  widget is IconButton,
            ),
          )
          .evaluate())
    tester.getRect(find.byWidget(element.widget)).bottom,
].reduce((a, b) => a > b ? a : b);

void main() {
  setUpAll(tz.initializeTimeZones);

  group('펼친 이름은 내용 높이만큼이다', () {
    for (final mode in MeetingMode.values) {
      for (final layout in Layout.values) {
        testWidgets('${mode.name} ${layout.name}', (tester) async {
          await pumpIn(tester, layout, boardIn(mode));
          final card = find.byType(MeetingSlotCard).first;
          final mouse = await tester.createGesture(
            kind: PointerDeviceKind.mouse,
          );
          addTearDown(mouse.removePointer);
          await mouse.addPointer(location: Offset.zero);

          await mouse.moveTo(tester.getCenter(card));
          await tester.pumpAndSettle();
          final hover = find
              .ancestor(
                of: find.byType(MeetingNameChip).first,
                matching: find.byType(Material),
              )
              .first;
          expect(find.text('불가능 1명 · 다현'), findsOneWidget);
          expect(
            tester.getRect(hover).bottom - contentBottom(tester, hover),
            closeTo(8, 0.5),
            reason: '마우스로 띄운 이름 상자는 안쪽 여백만큼만 더 길다',
          );

          await tester.tap(card);
          await tester.pumpAndSettle();
          await mouse.moveTo(Offset.zero);
          await tester.pumpAndSettle();
          expect(find.text('불가능 1명 · 다현'), findsOneWidget);
          expect(
            tester.getRect(card).bottom - contentBottom(tester, card),
            lessThanOrEqualTo(12),
            reason: '고정해 펼친 카드는 마지막 줄 아래 여백만큼만 더 길다',
          );
        });
      }
    }
  });
}
