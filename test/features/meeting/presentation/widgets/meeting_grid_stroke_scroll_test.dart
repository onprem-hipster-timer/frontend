import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/domain/meeting_board.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_availability_section.dart';
import 'package:timezone/data/latest.dart' as tz;

import '../../meeting_fixtures.dart';
import '../../meeting_grid_finders.dart';

/// 머리띠 높이(본문은 머리띠 뒤로 이어지고 그만큼 위 여백을 둔다)
const header = 56.0;
const view = Size(800, 560);

const first = '3월 1일 (월) 6:00 ~ 6:30';
const last = '3월 1일 (월) 17:30 ~ 18:00';

void main() {
  late ScrollController page;

  setUpAll(tz.initializeTimeZones);

  /// 머리띠 아래에서 굴러가는 화면의 '내 시간 선택하기'(3월 1~5일 6~18시, 30분 칸). 칠하면 그대로 반영한다
  Future<void> pumpSection(WidgetTester tester) async {
    tester.view.physicalSize = view;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    page = ScrollController();
    addTearDown(page.dispose);
    var board = MeetingBoard(
      meeting: makeMeeting(),
      availability: const [],
      userId: 'user-1',
      selfName: '지현',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: view,
            padding: EdgeInsets.only(top: header),
          ),
          child: Scaffold(
            body: SingleChildScrollView(
              controller: page,
              padding: const EdgeInsets.fromLTRB(16, header + 16, 16, 32),
              child: StatefulBuilder(
                builder: (context, setState) => MeetingAvailabilitySection(
                  meeting: board.meeting,
                  shading: board,
                  onPaint: (changes) => setState(() {
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
      ),
    );
    await tester.pumpAndSettle();
  }

  String? valueOf(String label) {
    final value = cellData(label).value;
    return value.isEmpty ? null : value;
  }

  /// [duration] 동안 화면을 그린다(프레임마다)
  Future<void> hold(WidgetTester tester, Duration duration) async {
    const frame = Duration(milliseconds: 16);
    for (var t = Duration.zero; t < duration; t += frame) {
      await tester.pump(frame);
    }
  }

  String row(String time) => '3월 1일 (월) $time';

  /// 3월 1일 열에서 칠한 칸의 시각(위에서부터)
  List<String> paintedTimes() => [
    for (var minute = 6 * 60; minute < 18 * 60; minute += 30)
      if (valueOf(row(_slot(minute))) == '가능') _slot(minute),
  ];

  Future<TestGesture> pressMouse(WidgetTester tester, Offset at) =>
      tester.startGesture(
        at,
        kind: PointerDeviceKind.mouse,
        buttons: kPrimaryMouseButton,
      );

  Future<TestGesture> longPress(WidgetTester tester, Offset at) async {
    final gesture = await tester.startGesture(at);
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));
    return gesture;
  }

  final kinds = <String, Future<TestGesture> Function(WidgetTester, Offset)>{
    '마우스로': pressMouse,
    '터치로 길게 눌러': longPress,
  };

  for (final MapEntry(key: how, value: press) in kinds.entries) {
    testWidgets(
      '$how 끌다 보이는 격자 아래 끝에 닿으면 화면이 부드럽게 굴러 아래 칸까지 칠하고, 격자 끝이 보이면 멈춘다',
      (tester) async {
        final semantics = tester.ensureSemantics();
        await pumpSection(tester);
        final start = cellCenter(tester, first);
        expect(
          start.dy,
          inInclusiveRange(header, view.height),
          reason: '첫 칸이 보인다',
        );
        expect(
          cellCenter(tester, last).dy,
          greaterThan(view.height),
          reason: '끝 칸은 아래에 가려져 있다',
        );

        final gesture = await press(tester, start);
        await gesture.moveTo(Offset(start.dx, view.height - 2));
        await hold(tester, const Duration(milliseconds: 300));
        final early = page.offset;
        expect(early, greaterThan(0), reason: '끝에 닿으면 굴리기 시작한다');
        await hold(tester, const Duration(seconds: 4));
        final stopped = page.offset;
        expect(stopped, greaterThan(early), reason: '한 번에 뛰지 않고 이어서 굴린다');
        final lastCell = cellCenter(tester, last);
        expect(lastCell.dy, lessThan(view.height), reason: '격자 끝 칸이 보인다');
        expect(
          stopped,
          lessThan(page.position.maxScrollExtent),
          reason: '격자 끝이 보이면 화면 끝까지 가지 않고 멈춘다',
        );
        await hold(tester, const Duration(seconds: 1));
        expect(page.offset, stopped);

        await gesture.up();
        await tester.pumpAndSettle();
        expect(paintedTimes(), [
          for (var minute = 6 * 60; minute < 18 * 60; minute += 30)
            _slot(minute),
        ]);
        expect(valueOf('3월 2일 (화) 6:00 ~ 6:30'), isNull);
        semantics.dispose();
      },
    );

    testWidgets('$how 끌다 머리띠 아래 위 끝에 닿으면 위로 굴려 첫 칸까지 칠한다', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpSection(tester);
      page.jumpTo(page.position.maxScrollExtent);
      await tester.pumpAndSettle();
      expect(
        cellCenter(tester, first).dy,
        lessThan(header),
        reason: '첫 칸은 머리띠 뒤나 위에 있다',
      );

      final start = cellCenter(tester, last);
      final gesture = await press(tester, start);
      await gesture.moveTo(Offset(start.dx, header + 2));
      await hold(tester, const Duration(seconds: 4));
      expect(
        cellCenter(tester, first).dy,
        greaterThan(header),
        reason: '첫 칸이 머리띠 아래에 보인다',
      );
      expect(page.offset, greaterThan(0), reason: '격자 첫 칸이 보이면 멈춘다');

      await gesture.up();
      await tester.pumpAndSettle();
      expect(paintedTimes(), hasLength(24));
      semantics.dispose();
    });
  }

  testWidgets('터치로 길게 누른 뒤 끄는 동안 화면은 그 손가락을 따라 굴러가지 않는다', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpSection(tester);
    page.jumpTo(120);
    await tester.pumpAndSettle();
    final from = cellCenter(tester, row('9:00 ~ 9:30'));
    final to = cellCenter(tester, row('7:30 ~ 8:00'));
    expect(to.dy, greaterThan(header + 60), reason: '끝 가까이가 아니다');

    final gesture = await longPress(tester, from);
    await gesture.moveTo(to);
    await hold(tester, const Duration(milliseconds: 500));
    expect(page.offset, 120);
    await gesture.up();
    await tester.pumpAndSettle();

    expect(paintedTimes(), [
      '7:30 ~ 8:00',
      '8:00 ~ 8:30',
      '8:30 ~ 9:00',
      '9:00 ~ 9:30',
    ]);
    semantics.dispose();
  });

  testWidgets('굴러가는 중에 손을 떼면 그때 손 아래 칸에서 붓질이 끝나고 더 굴리지 않는다', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpSection(tester);
    final start = cellCenter(tester, first);

    final gesture = await pressMouse(tester, start);
    await gesture.moveTo(Offset(start.dx, view.height - 2));
    await hold(tester, const Duration(milliseconds: 600));
    final release = cellCenter(tester, row('9:00 ~ 9:30'));
    await gesture.moveTo(release);
    await gesture.up();
    final at = page.offset;
    await hold(tester, const Duration(milliseconds: 500));

    expect(page.offset, at);
    expect(paintedTimes().last, '9:00 ~ 9:30');
    expect(paintedTimes().first, '6:00 ~ 6:30');
    semantics.dispose();
  });

  testWidgets('끄는 동안 휠로 화면을 굴리면 붓질은 손 아래로 온 칸까지 이어진다', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpSection(tester);
    final start = cellCenter(tester, first);

    final gesture = await pressMouse(tester, start);
    await gesture.moveTo(start + const Offset(0, 4));
    await tester.pump();
    tester.binding.handlePointerEvent(
      PointerScrollEvent(
        position: start + const Offset(0, 4),
        scrollDelta: const Offset(0, 130),
      ),
    );
    await tester.pumpAndSettle();
    expect(page.offset, greaterThan(0));
    final under = [
      for (var minute = 6 * 60; minute < 18 * 60; minute += 30)
        if ((cellCenter(tester, row(_slot(minute))).dy - (start.dy + 4)).abs() <
            13)
          _slot(minute),
    ].single;
    await gesture.up();
    await tester.pumpAndSettle();

    expect(paintedTimes().last, under);
    expect(paintedTimes().length, greaterThan(1));
    semantics.dispose();
  });
}

/// [minute]분에 시작하는 30분 칸의 시각 글('9:00 ~ 9:30')
String _slot(int minute) {
  String at(int m) => '${m ~/ 60}:${(m % 60).toString().padLeft(2, '0')}';
  return '${at(minute)} ~ ${at(minute + 30)}';
}
