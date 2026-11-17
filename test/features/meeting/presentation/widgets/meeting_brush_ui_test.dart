import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/domain/meeting_board.dart';
import 'package:momeet/features/meeting/domain/meeting_grid.dart';
import 'package:momeet/features/meeting/domain/meeting_headcount.dart';
import 'package:momeet/features/meeting/presentation/utils/meeting_formatters.dart';
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

  Future<void> tapCell(WidgetTester tester, String label) async {
    await tester.tapAt(cellCenter(tester, label));
    await tester.pumpAndSettle();
  }

  Future<void> pickBrush(WidgetTester tester, String label) async {
    await tester.tap(find.text(label));
    await tester.pumpAndSettle();
  }

  /// 줄바꿈용 단어 잇기 문자를 뺀 글이 [text]인 글자
  Finder plain(String text) => find.byWidgetPredicate(
    (widget) => widget is Text && widget.data?.replaceAll('\u2060', '') == text,
  );

  /// 줄바꿈용 단어 잇기 문자를 뺀 글에 [part]가 든 글자
  Finder plainContaining(String part) => find.byWidgetPredicate(
    (widget) =>
        widget is Text &&
        (widget.data?.replaceAll('\u2060', '').contains(part) ?? false),
  );

  const hourlyYes = '확실히 되는 시간을 칠해 주세요';
  const hourlyNo = '절대 안 되는 시간을 칠해 주세요';

  MeetingRead dayMeeting(MeetingMode mode) => makeMeeting(
    endDate: DateTime.utc(2027, 3, 7),
    mode: mode,
    startTime: '00:00:00',
    endTime: '00:00:00',
  );

  testWidgets('붓은 가능으로 시작하고, 붓 옆 한 줄은 고른 붓을 따르며 스크린 리더가 읽는다', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpSection(tester);

    expect(tester.getSemantics(find.text('가능')), isSemantics(isSelected: true));
    expect(plain(hourlyYes), findsOneWidget);
    expect(
      tester.getSemantics(plain(hourlyYes)),
      isSemantics(isLiveRegion: true),
    );
    await pickBrush(tester, '불가능');
    expect(
      tester.getSemantics(find.text('불가능')),
      isSemantics(isSelected: true),
    );
    expect(plain(hourlyYes), findsNothing);
    expect(plain(hourlyNo), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('방식마다 그 방식의 말만 보인다', (tester) async {
    for (final (mode, unit) in [
      (MeetingMode.daily, '날'),
      (MeetingMode.weekly, '요일'),
    ]) {
      await tester.pumpWidget(const SizedBox());
      await pumpSection(tester, meeting: dayMeeting(mode));
      expect(plain('확실히 되는 $unit을 칠해 주세요'), findsOneWidget);
      expect(plainContaining('시간을'), findsNothing);
      await pickBrush(tester, '불가능');
      expect(plain('절대 안 되는 $unit을 칠해 주세요'), findsOneWidget);
    }
  });

  testWidgets('도움말은 끌어 칠하기를 알리고 한 가지로 표시하라는 말은 없다', (tester) async {
    for (final mode in [
      MeetingMode.hourly,
      MeetingMode.daily,
      MeetingMode.weekly,
    ]) {
      await tester.pumpWidget(const SizedBox());
      await pumpSection(tester, meeting: dayMeeting(mode));
      final help = tester
          .widgetList<Tooltip>(find.byType(Tooltip))
          .map((tooltip) => tooltip.message ?? '')
          .firstWhere((message) => message.contains('칠해요'));
      expect(help, contains('길게 누른 채 끌면 여러 칸을 한 번에 칠해요'));
      expect(help, isNot(contains('한 가지')));
      expect(help, isNot(contains('초기화하기')));
    }
  });

  testWidgets('한 날에 두 붓을 섞어 칠하고, 칠하지 않은 칸은 답하지 않은 채로 둔다', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpSection(tester);
    await tapCell(tester, '3월 1일 (월) 6:00 ~ 6:30');
    await pickBrush(tester, '불가능');
    await tapCell(tester, '3월 1일 (월) 9:00 ~ 9:30');

    expect(valueOf('3월 1일 (월) 6:00 ~ 6:30'), '가능');
    expect(valueOf('3월 1일 (월) 9:00 ~ 9:30'), '불가능');
    expect(valueOf('3월 1일 (월) 7:00 ~ 7:30'), isNull, reason: '채우지 않는다');
    expect(valueOf('3월 1일 (월) 17:30 ~ 18:00'), isNull);
    expect(find.byType(SnackBar), findsNothing, reason: '막는 알림이 없다');

    await tapCell(tester, '3월 1일 (월) 6:00 ~ 6:30');
    expect(valueOf('3월 1일 (월) 6:00 ~ 6:30'), '불가능', reason: '다른 답은 덮어쓴다');
    await tapCell(tester, '3월 1일 (월) 9:00 ~ 9:30');
    expect(valueOf('3월 1일 (월) 9:00 ~ 9:30'), isNull, reason: '같은 답이면 지운다');
    semantics.dispose();
  });

  testWidgets('여러 날에 걸친 붓질은 지나간 칸만 칠하고 다른 답의 칸도 덮어쓴다', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpSection(tester);
    await tapCell(tester, '3월 2일 (화) 9:00 ~ 9:30');
    await pickBrush(tester, '불가능');

    await tester.dragFrom(
      cellCenter(tester, '3월 1일 (월) 9:00 ~ 9:30'),
      cellCenter(tester, '3월 5일 (금) 9:00 ~ 9:30') -
          cellCenter(tester, '3월 1일 (월) 9:00 ~ 9:30'),
      kind: PointerDeviceKind.mouse,
      buttons: kPrimaryMouseButton,
    );
    await tester.pumpAndSettle();

    for (final day in ['1일 (월)', '2일 (화)', '3일 (수)', '5일 (금)']) {
      expect(valueOf('3월 $day 9:00 ~ 9:30'), '불가능');
    }
    expect(valueOf('3월 1일 (월) 6:00 ~ 6:30'), isNull);
    expect(find.byType(SnackBar), findsNothing);
    semantics.dispose();
  });

  testWidgets('붓의 답인 칸에서 끌기 시작하면 지나간 칸을 모두 지운다', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpSection(tester);
    await tapCell(tester, '3월 1일 (월) 9:00 ~ 9:30');
    await pickBrush(tester, '불가능');
    await tapCell(tester, '3월 1일 (월) 9:30 ~ 10:00');
    await pickBrush(tester, '가능');

    await tester.dragFrom(
      cellCenter(tester, '3월 1일 (월) 9:00 ~ 9:30'),
      cellCenter(tester, '3월 1일 (월) 10:00 ~ 10:30') -
          cellCenter(tester, '3월 1일 (월) 9:00 ~ 9:30'),
      kind: PointerDeviceKind.mouse,
      buttons: kPrimaryMouseButton,
    );
    await tester.pumpAndSettle();

    expect(valueOf('3월 1일 (월) 9:00 ~ 9:30'), isNull);
    expect(valueOf('3월 1일 (월) 9:30 ~ 10:00'), isNull);
    expect(valueOf('3월 1일 (월) 10:00 ~ 10:30'), isNull);
    semantics.dispose();
  });

  testWidgets('날짜 머리: 빈 날은 하루 전체를 가능으로, 답한 날은 지우고 되돌릴 수 있다', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpSection(tester);
    final head = find.bySemanticsLabel('3월 3일 (수) 하루 전체');

    expect(
      tester.getSemantics(head),
      isSemantics(isButton: true, hint: '하루 전체를 되는 시간으로 칠합니다'),
    );
    await tester.tap(head);
    await tester.pumpAndSettle();
    expect(valueOf('3월 3일 (수) 6:00 ~ 6:30'), '가능');
    expect(valueOf('3월 3일 (수) 17:30 ~ 18:00'), '가능');
    expect(tester.getSemantics(head), isSemantics(hint: '그날 일정을 초기화합니다'));

    await tester.tap(head);
    await tester.pumpAndSettle();
    expect(valueOf('3월 3일 (수) 6:00 ~ 6:30'), isNull);
    expect(find.text('3/3 일정을 초기화했어요'), findsOneWidget);
    await tester.tap(find.text('되돌리기'));
    await tester.pumpAndSettle();
    expect(valueOf('3월 3일 (수) 6:00 ~ 6:30'), '가능');

    await pickBrush(tester, '불가능');
    await tapCell(tester, '3월 4일 (목) 9:00 ~ 9:30');
    await tester.tap(find.bySemanticsLabel('3월 4일 (목) 하루 전체'));
    await tester.pumpAndSettle();
    expect(valueOf('3월 4일 (목) 9:00 ~ 9:30'), isNull, reason: '불가능만 칠한 날도 지운다');
    semantics.dispose();
  });

  for (final mode in [MeetingMode.daily, MeetingMode.weekly]) {
    testWidgets('$mode: 두 붓을 섞어 칠하고 채우지 않으며 초기화 단추가 없다', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpSection(tester, meeting: dayMeeting(mode));
      final grid = MeetingGrid.of(dayMeeting(mode));
      String label(int day) => meetingCellLabel(
        grid,
        grid.cells.firstWhere((cell) => cell.day.day == day),
      );

      expect(find.textContaining('초기화'), findsNothing);
      await tapCell(tester, label(2));
      await pickBrush(tester, '불가능');
      await tapCell(tester, label(4));

      expect(valueOf(label(2)), '가능');
      expect(valueOf(label(4)), '불가능');
      expect(valueOf(label(1)), isNull);
      expect(valueOf(label(7)), isNull);
      expect(find.byType(SnackBar), findsNothing);
      semantics.dispose();
    });
  }

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
