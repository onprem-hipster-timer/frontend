import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/domain/meeting_board.dart';
import 'package:momeet/features/meeting/domain/meeting_headcount.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_availability_section.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:timezone/data/latest.dart' as tz;

import '../../meeting_fixtures.dart';
import '../../meeting_grid_finders.dart';

/// 서울 2027년 3월 [day]일 [hour]시의 UTC 시각
DateTime seoul(int day, int hour, [int minute = 0]) =>
    DateTime.utc(2027, 3, day, hour - 9, minute);

void main() {
  setUpAll(tz.initializeTimeZones);

  /// 칠하면 그대로 내 시간에 반영하는 모임 화면의 '내 시간 선택하기'
  Future<void> pumpSection(
    WidgetTester tester, {
    MeetingRead? meeting,
    List<AvailabilityRead> availability = const [],
    bool reduceMotion = false,
    Size size = const Size(800, 1600),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    var board = MeetingBoard(
      meeting: meeting ?? makeMeeting(),
      availability: availability,
      userId: 'user-1',
      selfName: '지현',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: size, disableAnimations: reduceMotion),
          child: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: StatefulBuilder(
                builder: (context, setState) => MeetingAvailabilitySection(
                  meeting: board.meeting,
                  shading: board,
                  onPaint: (changes) => setState(
                    () => board = board.withMine(
                      board.mine.paint({
                        for (final MapEntry(key: cell, value: answer)
                            in changes.entries)
                          cell.span: answer,
                      }),
                    ),
                  ),
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

  Future<void> tapCell(WidgetTester tester, String label) async {
    await tester.tapAt(cellCenter(tester, label));
    await tester.pumpAndSettle();
  }

  Future<void> pickBrush(WidgetTester tester, String label) async {
    await tester.tap(find.text(label));
    await tester.pumpAndSettle();
  }

  testWidgets('붓은 가능으로 시작하고 한 줄 안내와 함께 가능·불가능을 고른다', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpSection(tester);

    expect(find.text("바쁜 날은 '가능'만, 한가한 날은 '불가능'만 칠하세요"), findsOneWidget);
    expect(tester.getSemantics(find.text('가능')), isSemantics(isSelected: true));
    await pickBrush(tester, '불가능');
    expect(
      tester.getSemantics(find.text('불가능')),
      isSemantics(isSelected: true),
    );
    expect(
      tester.getSemantics(find.text('가능')),
      isSemantics(isSelected: false),
    );
    semantics.dispose();
  });

  testWidgets('아무것도 칠하지 않은 날에 불가능을 누르면 그 칸은 불가능, 그날 나머지는 가능이 된다', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pumpSection(tester);
    await pickBrush(tester, '불가능');

    await tapCell(tester, '3월 1일 (월) 9:00 ~ 9:30');

    expect(valueOf('3월 1일 (월) 9:00 ~ 9:30'), '불가능');
    expect(valueOf('3월 1일 (월) 6:00 ~ 6:30'), '가능');
    expect(valueOf('3월 1일 (월) 17:30 ~ 18:00'), '가능');
    expect(valueOf('3월 2일 (화) 9:00 ~ 9:30'), isNull, reason: '다른 날은 그대로');

    await tapCell(tester, '3월 1일 (월) 11:00 ~ 11:30');
    expect(valueOf('3월 1일 (월) 11:00 ~ 11:30'), '불가능');

    await tapCell(tester, '3월 1일 (월) 9:00 ~ 9:30');
    expect(
      valueOf('3월 1일 (월) 9:00 ~ 9:30'),
      isNull,
      reason: '불가능 칸에서 시작하면 지운다',
    );
    expect(valueOf('3월 1일 (월) 6:00 ~ 6:30'), '가능');
    semantics.dispose();
  });

  testWidgets('이미 칠한 날에 불가능을 누르면 그 칸만 바뀐다', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpSection(tester);

    await tapCell(tester, '3월 2일 (화) 6:00 ~ 6:30');
    await pickBrush(tester, '불가능');
    await tapCell(tester, '3월 2일 (화) 9:00 ~ 9:30');

    expect(valueOf('3월 2일 (화) 9:00 ~ 9:30'), '불가능');
    expect(valueOf('3월 2일 (화) 7:00 ~ 7:30'), isNull);
    semantics.dispose();
  });

  testWidgets('날짜 머리를 누르면 그날 전체를 붓으로 칠하고 다시 누르면 지운다', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpSection(tester);
    final head = find.bySemanticsLabel('3월 3일 (수) 하루 전체');

    expect(
      tester.getSemantics(head),
      isSemantics(isButton: true, hint: '하루 전체를 가능으로 칠합니다'),
    );
    await tester.tap(head);
    await tester.pumpAndSettle();
    expect(valueOf('3월 3일 (수) 6:00 ~ 6:30'), '가능');
    expect(valueOf('3월 3일 (수) 17:30 ~ 18:00'), '가능');
    expect(tester.getSemantics(head), isSemantics(hint: '하루 전체를 지웁니다'));

    await tester.tap(head);
    await tester.pumpAndSettle();
    expect(valueOf('3월 3일 (수) 6:00 ~ 6:30'), isNull);

    await pickBrush(tester, '불가능');
    await tester.tap(head);
    await tester.pumpAndSettle();
    expect(valueOf('3월 3일 (수) 12:00 ~ 12:30'), '불가능');
    semantics.dispose();
  });

  testWidgets('날짜별은 아무 날도 칠하지 않았을 때 불가능을 누르면 나머지 날이 가능이 된다', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpSection(
      tester,
      meeting: makeMeeting(
        endDate: DateTime.utc(2027, 3, 10),
        mode: MeetingMode.daily,
        startTime: '00:00:00',
        endTime: '00:00:00',
      ),
    );
    await pickBrush(tester, '불가능');

    await tapCell(tester, '3월 4일 (목)');

    expect(valueOf('3월 4일 (목)'), '불가능');
    expect(valueOf('3월 1일 (월)'), '가능');
    expect(valueOf('3월 10일 (수)'), '가능');
    semantics.dispose();
  });

  testWidgets('다른 참여자의 불가능은 칸 안내에 인원수로만 읽는다', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpSection(
      tester,
      availability: [
        availabilityOf('a', slots: [(seoul(1, 6), seoul(1, 7))]),
        availabilityOf('b', unavailable: [(seoul(1, 6), seoul(1, 7))]),
      ],
    );

    expect(cellData('3월 1일 (월) 6:00 ~ 6:30').hint, '다른 참여자 1명, 1명 불가');
    semantics.dispose();
  });

  testWidgets('누른 칸은 짧게 바뀌고, 애니메이션을 줄였으면 바로 바뀐다', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpSection(tester);
    await tester.tapAt(cellCenter(tester, '3월 1일 (월) 6:00 ~ 6:30'));
    await tester.pump();
    expect(tester.hasRunningAnimations, isTrue);
    await tester.pumpAndSettle();

    await pumpSection(tester, reduceMotion: true);
    await tester.tapAt(cellCenter(tester, '3월 1일 (월) 7:00 ~ 7:30'));
    await tester.pump();
    expect(tester.hasRunningAnimations, isFalse);
    semantics.dispose();
  });

  testWidgets('시간별인데 날이 많은 모임은 시각을 둔 채 날짜를 옆으로 굴리고 모든 날을 칠할 수 있다', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pumpSection(
      tester,
      meeting: makeMeeting(endDate: DateTime.utc(2027, 3, 21)),
      size: const Size(360, 1600),
    );

    expect(tester.takeException(), isNull);
    final horizontal = find.byWidgetPredicate(
      (widget) =>
          widget is SingleChildScrollView &&
          widget.scrollDirection == Axis.horizontal,
    );
    expect(horizontal, findsOneWidget);
    expect(find.semantics.byLabel('3월 21일 (일) 6:00 ~ 6:30'), findsOne);

    await tester.drag(horizontal, const Offset(-2000, 0));
    await tester.pumpAndSettle();
    await tapCell(tester, '3월 21일 (일) 6:00 ~ 6:30');
    expect(valueOf('3월 21일 (일) 6:00 ~ 6:30'), '가능');
    expect(find.text('6:00'), findsOneWidget, reason: '시각은 굴러가지 않는다');
    semantics.dispose();
  });

  testWidgets('제외 날짜가 많은 긴 날짜별 모임도 남은 날만 그린다', (tester) async {
    final semantics = tester.ensureSemantics();
    final start = DateTime.utc(2027, 3, 1);
    await pumpSection(
      tester,
      meeting: makeMeeting(
        startDate: start,
        endDate: DateTime.utc(2027, 5, 31),
        excludedDates: [
          for (var i = 1; i < 91; i++)
            if (i.isOdd) start.add(Duration(days: i)),
        ],
        mode: MeetingMode.daily,
        startTime: '00:00:00',
        endTime: '00:00:00',
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.semantics.byLabel('3월 3일 (수)'), findsOne);
    expect(find.semantics.byLabel('3월 2일 (화)'), findsNothing);
    expect(find.semantics.byLabel('5월 31일 (월)'), findsOne);
    semantics.dispose();
  });

  testWidgets('로그인 전 방문자에게는 붓이 없고 안 되는 사람 수를 칸 안내로 읽는다', (tester) async {
    final semantics = tester.ensureSemantics();
    final meeting = makeMeeting();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: MeetingAvailabilitySection(
              meeting: meeting,
              shading: MeetingHeadcount(
                MeetingResultRead(
                  meeting: meeting,
                  participantCount: 3,
                  availabilityGrid: [
                    AvailabilityCell(
                      startTime: seoul(1, 6),
                      endTime: seoul(1, 6, 30),
                      count: 2,
                      unavailableCount: 1,
                    ),
                  ],
                ),
              ),
              onLocked: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('불가능'), findsNothing);
    expect(cellData('3월 1일 (월) 6:00 ~ 6:30').hint, '참여자 2명, 1명 불가');
    semantics.dispose();
  });
}
