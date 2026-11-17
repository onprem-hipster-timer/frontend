import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/domain/meeting_board.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_availability_section.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_grid_cells.dart';
import 'package:timezone/data/latest.dart' as tz;

import '../../meeting_fixtures.dart';
import '../../meeting_grid_finders.dart';

const upper = '0:00–6:00 · 받지 않는 시간';
const lower = '18:00–24:00 · 받지 않는 시간';

void main() {
  setUpAll(tz.initializeTimeZones);

  late int paints;
  late MeetingBoard board;

  /// 칠하면 내 시간에 반영하는 '내 시간 선택하기'. [startTime]~[endTime]의 시간별 모임이다
  Future<void> pumpSection(
    WidgetTester tester, {
    String startTime = '06:00:00',
    String endTime = '18:00:00',
  }) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    paints = 0;
    board = MeetingBoard(
      meeting: makeMeeting(startTime: startTime, endTime: endTime),
      availability: const [],
      userId: 'user-1',
      selfName: '지현',
    );
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: StatefulBuilder(
              builder: (context, setState) => MeetingAvailabilitySection(
                meeting: board.meeting,
                shading: board,
                onPaint: (changes) => setState(() {
                  paints++;
                  board = board.withMine(
                    board.mine.paint({
                      for (final MapEntry(key: cell, value: answer)
                          in changes.entries)
                        cell.span: answer,
                    }),
                  );
                }),
                onRetry: () {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder band(String text) => find.text(text);

  testWidgets('하루 범위 밖은 위아래에 받지 않는 시간 띠로 보이고 시각을 축에 적는다', (tester) async {
    await pumpSection(tester);

    expect(band(upper), findsOneWidget);
    expect(band(lower), findsOneWidget);
    expect(find.text('0:00'), findsOneWidget);
    expect(find.text('6:00'), findsOneWidget);
    expect(find.text('18:00'), findsOneWidget);
    final cells = tester.getRect(find.byType(MeetingGridCells));
    expect(tester.getRect(band(upper)).bottom, lessThan(cells.top));
    expect(tester.getRect(band(lower)).top, greaterThan(cells.bottom));
    expect(
      tester.getRect(find.text('0:00')).top,
      lessThan(tester.getRect(find.text('6:00')).top),
    );
  });

  testWidgets('범위가 0시에 시작하거나 24시에 끝나면 그쪽 띠는 없다', (tester) async {
    await pumpSection(tester, startTime: '00:00:00');
    expect(find.textContaining('0:00–'), findsNothing);
    expect(band(lower), findsOneWidget);

    await pumpSection(tester, endTime: '00:00:00');
    expect(band(upper), findsOneWidget);
    expect(find.textContaining('–24:00'), findsNothing);

    await pumpSection(tester, startTime: '00:00:00', endTime: '00:00:00');
    expect(find.textContaining('받지 않는 시간'), findsNothing);
  });

  testWidgets('띠가 있어도 칸의 높이와 간격은 그대로다', (tester) async {
    await pumpSection(tester, startTime: '00:00:00', endTime: '00:00:00');
    final whole = tester.getSize(find.byType(MeetingGridCells));
    await pumpSection(tester);
    final ranged = tester.getSize(find.byType(MeetingGridCells));

    expect(ranged.width, whole.width);
    expect(ranged.height / 24, whole.height / 48, reason: '30분 줄 높이가 같다');
  });

  testWidgets('스크린 리더는 띠마다 이름 하나를 읽는다', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpSection(tester);

    expect(find.bySemanticsLabel(upper), findsOneWidget);
    expect(find.bySemanticsLabel(lower), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('띠를 누르거나 끌어도 칠하지 않는다', (tester) async {
    await pumpSection(tester);
    for (final text in [upper, lower]) {
      final rect = tester.getRect(band(text));
      await tester.tapAt(rect.center);
      await tester.pumpAndSettle();
      await tester.dragFrom(
        rect.centerLeft + const Offset(4, 0),
        const Offset(200, 0),
        kind: PointerDeviceKind.mouse,
        buttons: kPrimaryMouseButton,
      );
      await tester.pumpAndSettle();
    }

    expect(paints, 0);
    final gridPaint = tester.renderObject(
      find
          .descendant(
            of: find.byType(MeetingGridCells),
            matching: find.byType(CustomPaint),
          )
          .first,
    );
    for (final text in [upper, lower]) {
      final path = tester.hitTestOnBinding(tester.getCenter(band(text))).path;
      expect(path.any((entry) => entry.target == gridPaint), isFalse);
      expect(
        path.any((entry) => entry.target == tester.renderObject(band(text))),
        isFalse,
        reason: '띠는 누를 자리가 아니다',
      );
    }
  });

  testWidgets('칸에서 띠로 끌면 범위 끝 칸에서 멈춘다', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpSection(tester);

    await tester.dragFrom(
      cellCenter(tester, '3월 1일 (월) 17:00 ~ 17:30'),
      tester.getCenter(band(lower)) -
          cellCenter(tester, '3월 1일 (월) 17:00 ~ 17:30') +
          const Offset(0, 20),
      kind: PointerDeviceKind.mouse,
      buttons: kPrimaryMouseButton,
    );
    await tester.pumpAndSettle();

    expect(paints, 1);
    expect(cellData('3월 1일 (월) 17:00 ~ 17:30').value, '가능');
    expect(cellData('3월 1일 (월) 17:30 ~ 18:00').value, '가능');
    expect(cellData('3월 1일 (월) 16:30 ~ 17:00').value, isEmpty);
    expect(
      board.mine.slots.available.single.end,
      DateTime.utc(2027, 3, 1, 9),
      reason: '18시(서울)에서 멈춘다',
    );
    semantics.dispose();
  });
}
