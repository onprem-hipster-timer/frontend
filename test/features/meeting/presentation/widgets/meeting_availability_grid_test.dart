import 'dart:ui' show Tristate;

import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/domain/meeting_board.dart';
import 'package:momeet/features/meeting/domain/meeting_grid.dart';
import 'package:momeet/features/meeting/domain/meeting_headcount.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_availability_grid.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:timezone/data/latest.dart' as tz;

import '../../meeting_fixtures.dart';
import '../../meeting_grid_finders.dart';

DateTime march(int day) => DateTime.utc(2027, 3, day);

/// 서울 2027년 3월 [day]일 [hour]시의 UTC 시각
DateTime seoul(int day, int hour, [int minute = 0]) =>
    DateTime.utc(2027, 3, day, hour - 9, minute);

/// 칠하기 호출 (칸 이름을 ', '로 이은 것, 칠하는지)
typedef Painted = (String cells, bool available);

void main() {
  setUpAll(tz.initializeTimeZones);

  late List<Painted> painted;

  setUp(() => painted = []);

  String nameOf(MeetingCell cell) =>
      '${cell.day.month}/${cell.day.day} ${cell.startMinute}';

  /// [meeting]의 격자를 [board]로 띄운다. 굴러가는 화면 안이고 위에 빈 자리가 있다
  Future<ScrollController> pumpGrid(
    WidgetTester tester, {
    MeetingRead? meeting,
    List<AvailabilityRead> availability = const [],
    MeetingBoard Function(MeetingBoard board)? edit,
  }) async {
    var board = MeetingBoard(
      meeting: meeting ?? makeMeeting(),
      availability: availability,
      userId: 'user-1',
      selfName: '지현',
    );
    board = edit?.call(board) ?? board;
    final scroll = ScrollController();
    addTearDown(scroll.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            controller: scroll,
            child: Column(
              children: [
                const SizedBox(height: 200),
                MeetingAvailabilityGrid(
                  shading: board,
                  onPaint: (cells, {required available}) =>
                      painted.add((cells.map(nameOf).join(', '), available)),
                ),
                const SizedBox(height: 1200),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return scroll;
  }

  group('시간별', () {
    testWidgets('위에 요일과 날짜, 왼쪽에 정각 시각을 보이고 칸마다 날짜·시각을 읽어 준다', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpGrid(tester);

      expect(find.text('3.1'), findsOneWidget);
      expect(find.text('3.5'), findsOneWidget);
      expect(find.text('6:00'), findsOneWidget);
      expect(find.text('17:00'), findsOneWidget);
      expect(find.text('17:30'), findsNothing, reason: '정각만 적는다');
      expect(cellData('3월 1일 (월) 6:00 ~ 6:30').value, isEmpty);
      expect(find.semantics.byLabel('3월 5일 (금) 17:30 ~ 18:00'), findsOne);
      semantics.dispose();
    });

    testWidgets('터치로 칸을 누르면 그 칸만 칠하고 내 칸을 누르면 지운다', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpGrid(
        tester,
        availability: [
          availabilityOf(
            'me',
            userId: 'user-1',
            slots: [(seoul(1, 9), seoul(1, 10))],
          ),
        ],
      );

      await tester.tapAt(cellCenter(tester, '3월 2일 (화) 7:00 ~ 7:30'));
      await tester.tapAt(cellCenter(tester, '3월 1일 (월) 9:30 ~ 10:00'));

      expect(painted, [('3/2 420', true), ('3/1 570', false)]);
      semantics.dispose();
    });

    testWidgets('마우스로 누른 채 끌면 시작 칸과 지금 칸을 꼭짓점으로 한 사각형을 놓을 때 한 번 칠한다', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await pumpGrid(tester);

      final gesture = await tester.startGesture(
        cellCenter(tester, '3월 2일 (화) 8:00 ~ 8:30'),
        kind: PointerDeviceKind.mouse,
        buttons: kPrimaryMouseButton,
      );
      await tester.pump();
      await gesture.moveTo(cellCenter(tester, '3월 1일 (월) 9:00 ~ 9:30'));
      await tester.pump();
      expect(painted, isEmpty, reason: '끄는 동안에는 넘기지 않는다');

      await gesture.up();
      await tester.pump();
      expect(painted.single.$2, isTrue);
      expect(
        painted.single.$1,
        '3/1 480, 3/1 510, 3/1 540, 3/2 480, 3/2 510, 3/2 540',
      );
      semantics.dispose();
    });

    testWidgets('내 칸에서 끌기 시작하면 사각형을 지운다', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpGrid(
        tester,
        availability: [
          availabilityOf(
            'me',
            userId: 'user-1',
            slots: [(seoul(1, 9), seoul(1, 10))],
          ),
        ],
      );

      await tester.dragFrom(
        cellCenter(tester, '3월 1일 (월) 9:00 ~ 9:30'),
        const Offset(0, 60),
        kind: PointerDeviceKind.mouse,
        buttons: kPrimaryMouseButton,
      );
      await tester.pump();

      expect(painted.single.$2, isFalse);
      expect(painted.single.$1, startsWith('3/1 540'));
      semantics.dispose();
    });

    testWidgets('터치로 그냥 끌면 화면이 굴러가고 칠하지 않는다', (tester) async {
      final semantics = tester.ensureSemantics();
      final scroll = await pumpGrid(tester);

      await tester.dragFrom(
        cellCenter(tester, '3월 3일 (수) 10:00 ~ 10:30'),
        const Offset(0, -150),
      );
      await tester.pumpAndSettle();

      expect(scroll.offset, greaterThan(100));
      expect(painted, isEmpty);
      semantics.dispose();
    });

    testWidgets('터치로 길게 누른 채 끌면 화면을 굴리지 않고 사각형을 칠한다', (tester) async {
      final semantics = tester.ensureSemantics();
      final scroll = await pumpGrid(tester);

      final gesture = await tester.startGesture(
        cellCenter(tester, '3월 3일 (수) 10:00 ~ 10:30'),
      );
      await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));
      await gesture.moveTo(cellCenter(tester, '3월 4일 (목) 11:00 ~ 11:30'));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      expect(scroll.offset, 0);
      expect(painted.single.$2, isTrue);
      expect(
        painted.single.$1,
        '3/3 600, 3/3 630, 3/3 660, 3/4 600, 3/4 630, 3/4 660',
      );
      semantics.dispose();
    });

    testWidgets('격자 밖으로 끌고 나가면 가장자리 칸까지만 칠한다', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpGrid(tester);

      final gesture = await tester.startGesture(
        cellCenter(tester, '3월 5일 (금) 6:30 ~ 7:00'),
        kind: PointerDeviceKind.mouse,
        buttons: kPrimaryMouseButton,
      );
      await gesture.moveBy(const Offset(300, -150));
      await gesture.up();
      await tester.pump();

      expect(painted.single.$1, '3/5 360, 3/5 390');
      semantics.dispose();
    });

    testWidgets('스크린 리더는 칸마다 내 시간인지와 다른 참여자 수를 읽고, 누르기로 칠한다', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpGrid(
        tester,
        availability: [
          availabilityOf(
            'me',
            userId: 'user-1',
            slots: [(seoul(1, 6), seoul(1, 7))],
          ),
          availabilityOf('a', slots: [(seoul(1, 6), seoul(1, 8))]),
          availabilityOf('b', slots: [(seoul(1, 6), seoul(1, 8))]),
        ],
      );

      final mine = cellData('3월 1일 (월) 6:00 ~ 6:30');
      expect(mine.value, '내 시간');
      expect(mine.hint, '다른 참여자 2명');
      expect(mine.flagsCollection.isSelected, Tristate.isTrue);
      expect(cellData('3월 1일 (월) 7:00 ~ 7:30').value, isEmpty);

      tester.semantics.tap(find.semantics.byLabel('3월 1일 (월) 7:00 ~ 7:30'));
      expect(painted, [('3/1 420', true)]);
      semantics.dispose();
    });

    testWidgets('일광 절약 시간으로 없는 시각의 자리는 칸이 없고 눌러도 칠하지 않는다', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpGrid(
        tester,
        meeting: makeMeeting(
          timezone: 'America/New_York',
          startDate: march(14),
          endDate: march(14),
          availableDays: [6],
          startTime: '01:00:00',
          endTime: '04:00:00',
          timeSlotMinutes: 60,
        ),
      );

      expect(find.semantics.byLabel('3월 14일 (일) 2:00 ~ 3:00'), findsNothing);
      final above = cellCenter(tester, '3월 14일 (일) 1:00 ~ 2:00');
      final below = cellCenter(tester, '3월 14일 (일) 3:00 ~ 4:00');
      await tester.tapAt(Offset(above.dx, (above.dy + below.dy) / 2));

      expect(painted, isEmpty);
      semantics.dispose();
    });
  });

  group('날짜별', () {
    MeetingRead daily() => makeMeeting(
      startDate: march(3),
      endDate: march(16),
      availableDays: [0, 1, 2, 3, 4, 5, 6],
      startTime: '00:00:00',
      endTime: '00:00:00',
    );

    testWidgets('일요일부터의 요일 머리 아래 하루 한 칸이고 첫 칸과 1일에 달을 적는다', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpGrid(tester, meeting: daily());

      for (final head in ['일', '월', '화', '수', '목', '금', '토']) {
        expect(find.text(head), findsOneWidget);
      }
      final first = cellCenter(tester, '3월 3일 (수)');
      final sunday = cellCenter(tester, '3월 7일 (일)');
      final nextWednesday = cellCenter(tester, '3월 10일 (수)');
      expect(sunday.dx, lessThan(first.dx));
      expect(sunday.dy, greaterThan(first.dy));
      expect(nextWednesday.dx, moreOrLessEquals(first.dx));
      expect(find.semantics.byLabel('3월 17일 (수)'), findsNothing);
      semantics.dispose();
    });

    testWidgets('하루를 누르면 그날 칸을 칠하고 끌면 여러 주의 사각형을 칠한다', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpGrid(tester, meeting: daily());

      await tester.tapAt(cellCenter(tester, '3월 4일 (목)'));
      await tester.dragFrom(
        cellCenter(tester, '3월 5일 (금)'),
        cellCenter(tester, '3월 13일 (토)') - cellCenter(tester, '3월 5일 (금)'),
        kind: PointerDeviceKind.mouse,
        buttons: kPrimaryMouseButton,
      );

      expect(painted, [
        ('3/4 0', true),
        ('3/5 0, 3/6 0, 3/12 0, 3/13 0', true),
      ]);
      semantics.dispose();
    });
  });

  group('요일별', () {
    testWidgets('기간이 수요일에 시작해도 월요일부터 일곱 칸이 한 줄이다', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpGrid(
        tester,
        meeting: makeMeeting(
          startDate: march(3),
          endDate: march(9),
          availableDays: [0, 1, 2, 3, 4, 5, 6],
          startTime: '00:00:00',
          endTime: '00:00:00',
        ),
      );

      final centers = [
        for (final day in ['월', '화', '수', '목', '금', '토', '일'])
          cellCenter(tester, '$day요일'),
      ];
      for (var i = 1; i < centers.length; i++) {
        expect(centers[i].dx, greaterThan(centers[i - 1].dx));
        expect(centers[i].dy, moreOrLessEquals(centers[0].dy));
      }

      await tester.tapAt(centers[0]);
      expect(painted, [('3/8 0', true)], reason: '월요일 칸은 기간 안의 월요일(8일)이다');
      semantics.dispose();
    });
  });

  group('색 설명', () {
    testWidgets('다른 참여자가 있으면 1명부터 모두까지의 농도를 보인다', (tester) async {
      await pumpGrid(
        tester,
        availability: [
          availabilityOf('a'),
          availabilityOf('b'),
          availabilityOf('c'),
        ],
      );

      expect(find.text('내 시간'), findsOneWidget);
      expect(find.text('다른 참여자 1명'), findsOneWidget);
      expect(find.text('3명'), findsOneWidget);
    });

    testWidgets('다른 참여자가 없으면 내 시간만 설명한다', (tester) async {
      await pumpGrid(
        tester,
        availability: [availabilityOf('me', userId: 'user-1')],
      );

      expect(find.text('내 시간'), findsOneWidget);
      expect(find.textContaining('다른 참여자'), findsNothing);
    });
  });

  testWidgets('기간 안에 고를 수 있는 날이 없으면 그렇다고 알린다', (tester) async {
    await pumpGrid(
      tester,
      meeting: makeMeeting(
        startDate: march(1),
        endDate: march(2),
        availableDays: [5],
        startTime: '00:00:00',
        endTime: '00:00:00',
      ),
    );

    expect(find.text('이 모임 기간에는 고를 수 있는 날이 없습니다'), findsOneWidget);
  });

  group('로그인하기 전(칠할 수 없는 격자)', () {
    late int locked;

    /// 결과의 사람 수로 칠할 수 없는 격자를 띄운다
    Future<void> pumpLocked(
      WidgetTester tester, {
      List<(DateTime, DateTime, int)> cells = const [],
      int participants = 3,
    }) async {
      locked = 0;
      final meeting = makeMeeting();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: MeetingAvailabilityGrid(
                shading: MeetingHeadcount(
                  MeetingResultRead(
                    meeting: meeting,
                    participantCount: participants,
                    availabilityGrid: [
                      for (final (start, end, count) in cells)
                        AvailabilityCell(
                          startTime: start,
                          endTime: end,
                          count: count,
                        ),
                    ],
                  ),
                ),
                onPaint: null,
                onLocked: () => locked++,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('칸마다 되는 사람 수를 읽고 누르기 동작은 두지 않는다', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpLocked(tester, cells: [(seoul(1, 6), seoul(1, 6, 30), 2)]);

      final cell = cellData('3월 1일 (월) 6:00 ~ 6:30');
      expect(cell.hint, '참여자 2명');
      expect(cell.value, isEmpty);
      expect(cell.flagsCollection.isButton, isFalse);
      expect(cell.flagsCollection.isSelected, Tristate.none);
      expect(cellData('3월 1일 (월) 6:30 ~ 7:00').hint, isEmpty);
      semantics.dispose();
    });

    testWidgets('터치로 누르거나 길게 눌러 끌면 칠하지 않고 알린다', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpLocked(tester);

      await tester.tapAt(cellCenter(tester, '3월 2일 (화) 7:00 ~ 7:30'));
      expect(locked, 1);

      final gesture = await tester.startGesture(
        cellCenter(tester, '3월 1일 (월) 8:00 ~ 8:30'),
      );
      await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));
      await gesture.moveTo(cellCenter(tester, '3월 2일 (화) 9:00 ~ 9:30'));
      await gesture.up();
      await tester.pumpAndSettle();

      expect(locked, 2);
      expect(painted, isEmpty);
      expect(cellData('3월 2일 (화) 9:00 ~ 9:30').value, isEmpty);
      semantics.dispose();
    });

    testWidgets('마우스로 누른 채 끌어도 칠하지 않고 누를 때 한 번 알린다', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpLocked(tester);

      final gesture = await tester.startGesture(
        cellCenter(tester, '3월 2일 (화) 8:00 ~ 8:30'),
        kind: PointerDeviceKind.mouse,
        buttons: kPrimaryMouseButton,
      );
      await tester.pump();
      await gesture.moveTo(cellCenter(tester, '3월 1일 (월) 9:00 ~ 9:30'));
      await tester.pump();
      expect(cellData('3월 1일 (월) 9:00 ~ 9:30').value, isEmpty);
      await gesture.up();
      await tester.pump();

      expect(locked, 1);
      expect(painted, isEmpty);
      semantics.dispose();
    });

    testWidgets('색 설명은 내 시간 없이 참여자 1명부터 모두까지다', (tester) async {
      await pumpLocked(tester);

      expect(find.text('내 시간'), findsNothing);
      expect(find.text('참여자 1명'), findsOneWidget);
      expect(find.text('3명'), findsOneWidget);
    });

    testWidgets('참여자가 없으면 색 설명이 없다', (tester) async {
      await pumpLocked(tester, participants: 0);

      expect(find.text('내 시간'), findsNothing);
      expect(find.textContaining('참여자'), findsNothing);
    });
  });
}
