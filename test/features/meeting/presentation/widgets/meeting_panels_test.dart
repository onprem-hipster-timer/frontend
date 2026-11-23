import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/domain/meeting_board.dart';
import 'package:momeet/features/meeting/domain/meeting_runs.dart';
import 'package:momeet/features/meeting/domain/my_availability.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_crown.dart';
import 'package:momeet/features/meeting/presentation/utils/meeting_run_highlight.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_name_chip.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_participants_panel.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_slots_panel.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/shared/ui/ui.dart';
import 'package:timezone/data/latest.dart' as tz;

import '../../meeting_fixtures.dart';

DateTime march(int day) => DateTime.utc(2027, 3, day);

/// 서울 2027년 3월 [day]일 [hour]시의 UTC 시각
DateTime seoul(int day, int hour) => DateTime.utc(2027, 3, day, hour - 9);

/// 3월 1일: 민수(주인) 9~12시, 서연 9~11시, 하준 10~12시. 3월 2일: 서연·하준 10~11시
List<AvailabilityRead> threePeople() => [
  availabilityOf(
    'a',
    name: '민수',
    userId: 'owner-1',
    owner: true,
    slots: [(seoul(1, 9), seoul(1, 12))],
  ),
  availabilityOf(
    'b',
    name: '서연',
    slots: [(seoul(1, 9), seoul(1, 11)), (seoul(2, 10), seoul(2, 11))],
  ),
  availabilityOf(
    'c',
    name: '하준',
    slots: [(seoul(1, 10), seoul(1, 12)), (seoul(2, 10), seoul(2, 12))],
  ),
];

MeetingBoard boardOf(
  List<AvailabilityRead> availability, {
  MeetingRead? meeting,
}) => MeetingBoard(
  meeting: meeting ?? makeMeeting(),
  availability: availability,
  userId: 'user-1',
  selfName: '지현',
);

/// 이름이 [name]인 참여자 칩
Finder chip(
  String name, {
  bool owner = false,
  bool guest = false,
  bool self = false,
}) => find.byWidgetPredicate(
  (widget) =>
      widget is MeetingNameChip &&
      widget.name == name &&
      widget.owner == owner &&
      widget.guest == guest &&
      widget.self == self,
);

Future<void> pumpPanel(
  WidgetTester tester,
  Widget panel, {
  double width = 420,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(
        body: SingleChildScrollView(
          child: Center(
            child: SizedBox(width: width, child: panel),
          ),
        ),
      ),
    ),
  );
}

void main() {
  setUpAll(tz.initializeTimeZones);

  group('추천 시간', () {
    late List<MeetingRun> added;

    setUp(() => added = []);

    Future<void> pumpSlots(WidgetTester tester, MeetingBoard board) =>
        pumpPanel(
          tester,
          MeetingSlotsPanel(
            board: board,
            onAddToCalendar: added.add,
            highlight: MeetingRunHighlight(),
          ),
        );

    /// 카드의 둘째 줄(시각)을 화면 위에서 아래 순서로
    List<String> detailsInOrder(WidgetTester tester) {
      final details = find.textContaining(RegExp(r'^\d+:\d\d ~ \d+:\d\d$'));
      final texts =
          [
            for (final element in details.evaluate())
              (
                (element.widget as Text).data!,
                tester.getTopLeft(find.byWidget(element.widget)),
              ),
          ]..sort(
            (a, b) => a.$2.dy != b.$2.dy
                ? a.$2.dy.compareTo(b.$2.dy)
                : a.$2.dx.compareTo(b.$2.dx),
          );
      return [for (final (text, _) in texts) text];
    }

    testWidgets('처음 열면 모모밋 추천이고 많이 모이며 오래 되는 시간부터, 같으면 날짜 순으로 보인다', (
      tester,
    ) async {
      await pumpSlots(tester, boardOf(threePeople()));

      expect(find.text('모모밋 추천'), findsOneWidget);
      expect(detailsInOrder(tester), [
        '10:00 ~ 11:00',
        '9:00 ~ 10:00',
        '11:00 ~ 12:00',
        '10:00 ~ 11:00',
      ]);
      expect(find.text('3월 2일 (화)'), findsOneWidget);
      expect(find.text('3'), findsOneWidget, reason: '인원수');
      expect(find.text('2'), findsNWidgets(3));
    });

    testWidgets('정렬 목록은 모모밋 추천이 맨 위이고 그다음 인원 많은 순·날짜 순·시간 긴 순이다', (
      tester,
    ) async {
      await pumpSlots(tester, boardOf(threePeople()));

      await tester.tap(find.text('모모밋 추천'));
      await tester.pumpAndSettle();

      final labels = ['모모밋 추천', '인원 많은 순', '날짜 순', '시간 긴 순'];
      final tops = [
        for (final label in labels) tester.getTopLeft(find.text(label).last).dy,
      ];
      expect(tops, [...tops]..sort());
    });

    testWidgets('인원 많은 순을 골라도 그 순서로 보인다', (tester) async {
      await pumpSlots(tester, boardOf(threePeople()));

      await tester.tap(find.text('모모밋 추천'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('인원 많은 순').last);
      await tester.pumpAndSettle();

      expect(find.text('인원 많은 순'), findsOneWidget);
      expect(detailsInOrder(tester), [
        '10:00 ~ 11:00',
        '9:00 ~ 10:00',
        '11:00 ~ 12:00',
        '10:00 ~ 11:00',
      ]);
    });

    testWidgets('정렬을 날짜 순으로 바꾸면 화면 순서다', (tester) async {
      await pumpSlots(tester, boardOf(threePeople()));

      await tester.tap(find.text('모모밋 추천'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('날짜 순').last);
      await tester.pumpAndSettle();

      expect(detailsInOrder(tester), [
        '9:00 ~ 10:00',
        '10:00 ~ 11:00',
        '11:00 ~ 12:00',
        '10:00 ~ 11:00',
      ]);
    });

    testWidgets('요일별은 요일 순·기간 긴 순으로 부른다', (tester) async {
      final meeting = makeMeeting(
        startDate: march(1),
        endDate: march(7),
        mode: MeetingMode.weekly,
        startTime: '00:00:00',
        endTime: '00:00:00',
      );
      await pumpSlots(tester, boardOf(const [], meeting: meeting));
      await tester.tap(find.text('모모밋 추천'));
      await tester.pumpAndSettle();

      expect(find.text('요일 순'), findsOneWidget);
      expect(find.text('기간 긴 순'), findsOneWidget);
      expect(find.text('날짜 순'), findsNothing);
    });

    testWidgets('후보가 없으면 두 명 이상 겹치면 보인다고 알린다', (tester) async {
      await pumpSlots(tester, boardOf([threePeople().first]));

      expect(find.text('두 명 이상 함께 되는 시간이 생기면 여기에 추천해 드려요'), findsOneWidget);
    });

    testWidgets('카드를 누르면 이름을 카드 안에 고정하고 다시 누르면 접는다', (tester) async {
      await pumpSlots(tester, boardOf(threePeople()));
      final card = find.ancestor(
        of: find.text('3'),
        matching: find.byType(InkWell),
      );
      expect(find.byType(MeetingNameChip), findsNothing);

      await tester.tap(card);
      await tester.pumpAndSettle();
      expect(chip('민수', owner: true), findsOneWidget);
      expect(chip('서연'), findsOneWidget);
      expect(chip('하준'), findsOneWidget);

      await tester.tap(card);
      await tester.pumpAndSettle();
      expect(find.byType(MeetingNameChip), findsNothing);
    });

    testWidgets('펼친 카드와 마우스로 띄운 이름에만 그 시간이 안 되는 사람을 조용히 덧붙인다', (tester) async {
      await pumpSlots(
        tester,
        boardOf([
          ...threePeople(),
          availabilityOf(
            'd',
            name: '다현',
            unavailable: [(seoul(1, 10), seoul(1, 11))],
          ),
          availabilityOf(
            'e',
            name: '은우',
            unavailable: [(seoul(2, 9), seoul(2, 10))],
          ),
        ]),
      );
      final card = find.text('3').first;

      expect(find.textContaining('불가능'), findsNothing, reason: '펼치기 전 카드 겉');
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(mouse.removePointer);
      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(tester.getCenter(card));
      await tester.pumpAndSettle();
      expect(find.text('불가능 1명 · 다현'), findsOneWidget);
      await mouse.moveTo(Offset.zero);
      await tester.pumpAndSettle();

      await tester.tap(card);
      await tester.pumpAndSettle();
      expect(find.text('불가능 1명 · 다현'), findsOneWidget);
      expect(find.textContaining('은우'), findsNothing, reason: '다른 날만 안 된다');
    });

    testWidgets('카드의 게스트 이름은 게스트 칩이다', (tester) async {
      final people = threePeople();
      await pumpSlots(
        tester,
        boardOf([
          people[0],
          people[1].copyWith.participant(isGuest: true, userId: null),
        ]),
      );

      await tester.tap(find.text('2').first);
      await tester.pumpAndSettle();

      expect(chip('민수', owner: true), findsOneWidget);
      expect(chip('서연', guest: true), findsOneWidget);
    });

    testWidgets('마우스를 올리면 이름이 뜨고 떠나면 사라진다', (tester) async {
      await pumpSlots(tester, boardOf(threePeople()));
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(mouse.removePointer);
      await mouse.addPointer(location: Offset.zero);

      await mouse.moveTo(tester.getCenter(find.text('3')));
      await tester.pumpAndSettle();
      expect(find.byType(MeetingNameChip), findsNWidgets(3));

      await mouse.moveTo(Offset.zero);
      await tester.pumpAndSettle();
      expect(find.byType(MeetingNameChip), findsNothing);
    });

    testWidgets('내 달력에 일정 만들기는 그 카드의 묶음을 넘긴다', (tester) async {
      await pumpSlots(tester, boardOf(threePeople()));

      await tester.tap(find.byTooltip('내 달력에 일정 만들기').first);

      expect(added.single.people, {'a', 'b', 'c'});
    });

    testWidgets('참여하기 전에 칠한 칸도 계정 이름으로 카드에 든다', (tester) async {
      var board = boardOf([threePeople()[1]]);
      final cell = board.grid.at(1, 8)!;
      board = board.withMine(
        board.mine.paint({cell.span: MeetingAnswer.available}),
      );
      await pumpSlots(tester, board);

      await tester.tap(find.text('2'));
      await tester.pumpAndSettle();

      expect(chip('서연'), findsOneWidget);
      expect(chip('지현', self: true), findsOneWidget);
    });
  });

  group('일정 참여자', () {
    testWidgets('주인을 맨 앞에 왕관으로, 나는 나로 표시한다', (tester) async {
      final board = boardOf([
        availabilityOf('b', name: '서연'),
        availabilityOf('me', name: '지현', userId: 'user-1'),
        availabilityOf('a', name: '민수', userId: 'owner-1', owner: true),
      ]);
      await pumpPanel(
        tester,
        MeetingParticipantsPanel(
          board: board,
          onRename: () {},
          onRemove: (_) {},
        ),
      );

      final chips = [
        chip('민수', owner: true),
        chip('서연'),
        chip('지현', self: true),
      ].map((finder) => tester.getTopLeft(finder).dx).toList();
      expect(chips, orderedEquals([...chips]..sort()));
      expect(find.bySemanticsLabel('민수, 주인'), findsOneWidget);
      expect(find.bySemanticsLabel('지현, 나'), findsOneWidget);
    });

    testWidgets('게스트는 회원과 이름이 같아도 다른 모양의 게스트 칩이다', (tester) async {
      await pumpPanel(
        tester,
        MeetingParticipantsPanel(
          board: boardOf([
            availabilityOf('m', name: '민수'),
            availabilityOf('g', name: '민수', guest: true),
          ]),
          onRename: () {},
          onRemove: (_) {},
        ),
      );

      expect(chip('민수'), findsOneWidget);
      expect(chip('민수', guest: true), findsOneWidget);
      expect(find.bySemanticsLabel('민수'), findsOneWidget);
      expect(find.bySemanticsLabel('민수, 게스트'), findsOneWidget);
      IconData? iconOf(Finder chip) => tester
          .widget<Icon>(find.descendant(of: chip, matching: find.byType(Icon)))
          .icon;
      expect(iconOf(chip('민수')), isNot(iconOf(chip('민수', guest: true))));
    });

    testWidgets('주인이 참여하지 않았으면 왕관이 없다', (tester) async {
      await pumpPanel(
        tester,
        MeetingParticipantsPanel(
          board: boardOf([
            availabilityOf('b', name: '서연'),
            availabilityOf('g', name: '하준', guest: true),
          ]),
          onRename: () {},
          onRemove: (_) {},
        ),
      );

      expect(find.byType(MeetingCrown), findsNothing);
      expect(chip('서연'), findsOneWidget);
      expect(chip('하준', guest: true), findsOneWidget);
    });

    testWidgets('참여했으면 편집으로 내 닉네임 바꾸기를 연다', (tester) async {
      var edits = 0;
      await pumpPanel(
        tester,
        MeetingParticipantsPanel(
          board: boardOf([availabilityOf('me', name: '지현', userId: 'user-1')]),
          onRename: () => edits++,
          onRemove: (_) {},
        ),
      );

      await tester.tap(find.text('편집'));
      expect(edits, 1);
    });

    testWidgets('아직 참여하지 않았으면 편집을 두지 않는다', (tester) async {
      await pumpPanel(
        tester,
        MeetingParticipantsPanel(
          board: boardOf([availabilityOf('a', name: '민수')]),
          onRename: () {},
          onRemove: (_) {},
        ),
      );

      expect(find.text('편집'), findsNothing);
    });

    testWidgets('아무도 없으면 칠하면 참여한다고 알린다', (tester) async {
      await pumpPanel(
        tester,
        MeetingParticipantsPanel(
          board: boardOf(const []),
          onRename: () {},
          onRemove: (_) {},
        ),
      );

      expect(find.text('아직 참여한 사람이 없습니다. 내 시간을 칠하면 참여합니다.'), findsOneWidget);
    });

    testWidgets('긴 이름은 칩 안에서 줄여 보인다', (tester) async {
      await pumpPanel(
        tester,
        MeetingParticipantsPanel(
          board: boardOf([availabilityOf('a', name: '아주긴이름' * 10)]),
          onRename: () {},
          onRemove: (_) {},
        ),
        width: 300,
      );

      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(find.byType(MeetingNameChip)).width,
        lessThanOrEqualTo(300),
      );
    });
  });
}
