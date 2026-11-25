import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/domain/meeting_board.dart';
import 'package:momeet/features/meeting/domain/meeting_grid.dart';
import 'package:momeet/features/meeting/domain/meeting_runs.dart';
import 'package:momeet/features/meeting/domain/meeting_shading.dart';
import 'package:momeet/features/meeting/domain/my_availability.dart';
import 'package:momeet/features/meeting/presentation/utils/meeting_run_highlight.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:widgetbook/widgetbook.dart';

/// 받는 방식과 그 화면 이름
const gridModes = {
  MeetingMode.hourly: '시간별',
  MeetingMode.daily: '날짜별',
  MeetingMode.weekly: '요일별',
};

/// '받는 방식' 노브
MeetingMode gridModeKnob(BuildContext context, {String? description}) =>
    context.knobs.object.dropdown(
      label: '받는 방식',
      description: description,
      options: gridModes.keys.toList(),
      labelBuilder: (mode) => gridModes[mode]!,
    );

/// 모임 화면을 보는 사람
enum GridViewer {
  owner('모임 주인 (모모)'),
  member('참여자 (토끼)'),
  guest('게스트 (곰돌이)'),
  newcomer('로그인했지만 아직 참여 전'),
  visitor('로그인 전');

  const GridViewer(this.label);

  final String label;
}

/// '보는 사람' 노브. [viewers]에서 고른다
GridViewer gridViewerKnob(
  BuildContext context, {
  List<GridViewer> viewers = GridViewer.values,
  GridViewer? initial,
  String? description,
}) => context.knobs.object.dropdown(
  label: '보는 사람',
  description: description,
  options: viewers,
  initialOption: initial ?? GridViewer.member,
  labelBuilder: (viewer) => viewer.label,
);

/// 시간을 넣은 참여자 수
enum GridAnswers {
  few('5명', 5),
  none('아직 아무도 없음', 0),
  many('14명', 14);

  const GridAnswers(this.label, this.count);

  final String label;
  final int count;
}

/// '답한 사람' 노브
GridAnswers gridAnswersKnob(BuildContext context, {String? description}) =>
    context.knobs.object.dropdown(
      label: '답한 사람',
      description: description,
      options: GridAnswers.values,
      labelBuilder: (answers) => answers.label,
    );

/// 견본 모임. 시간별은 3월 8일(월)부터 [days]일, 날짜별은 3월 1일~21일, 요일별은 3월 8일~14일의 한 주다
MeetingRead gridMeeting(
  MeetingMode mode, {
  int days = 5,
  String startTime = '09:00:00',
  String endTime = '18:00:00',
  String timezone = 'Asia/Seoul',
}) {
  final start = DateTime.utc(2027, 3, mode == MeetingMode.daily ? 1 : 8);
  final last = switch (mode) {
    MeetingMode.daily => DateTime.utc(2027, 3, 21),
    MeetingMode.weekly => DateTime.utc(2027, 3, 14),
    _ => start.add(Duration(days: days - 1)),
  };
  final created = DateTime.utc(2027, 3, 2);
  return MeetingRead(
    id: 'sample-meeting',
    title: '봄맞이 동아리 정기 모임',
    startDate: start,
    endDate: last,
    excludedDates: const [],
    timezone: timezone,
    mode: mode,
    startTime: startTime,
    endTime: endTime,
    timeSlotMinutes: 30,
    createdAt: created,
    updatedAt: created,
    ownerId: 'user-0',
    allowGuests: true,
  );
}

/// 견본 참여자: 되는 요일(1=월)과 그날 되는 시각(시), 안 되는 요일
typedef _Person = ({
  String name,
  String longName,
  bool guest,
  Set<int> weekdays,
  int from,
  int to,
  Set<int> busy,
});

const _people = <_Person>[
  (
    name: '모모',
    longName: '모임 시간을 누구보다 먼저 맞추는 모모',
    guest: false,
    weekdays: {1, 2, 3},
    from: 10,
    to: 15,
    busy: {5},
  ),
  (
    name: '토끼',
    longName: '닉네임이 아주 길어서 한 줄을 넘기는 토끼',
    guest: false,
    weekdays: {2, 3, 4},
    from: 13,
    to: 17,
    busy: {1},
  ),
  (
    name: '곰돌이',
    longName: '게스트로 들어온 이름 긴 곰돌이 손님',
    guest: true,
    weekdays: {1, 2, 4},
    from: 9,
    to: 14,
    busy: {},
  ),
  (
    name: '다람쥐',
    longName: '오늘은 하루 종일 도토리 줍는 다람쥐',
    guest: false,
    weekdays: {2, 3, 4},
    from: 11,
    to: 16,
    busy: {1},
  ),
  (
    name: '펭귄',
    longName: '남극에서 막 도착한 펭귄 손님',
    guest: true,
    weekdays: {3, 5, 6},
    from: 14,
    to: 18,
    busy: {},
  ),
];

const _moreNames = ['고양이', '부엉이', '수달', '판다', '여우', '햄스터', '고슴도치', '너구리', '오리'];

/// [index]번째 견본 참여자. 다섯 명 뒤로는 요일과 시각을 돌려 가며 만든다
_Person _personAt(int index) {
  if (index < _people.length) return _people[index];
  final i = index - _people.length;
  final name = _moreNames[i % _moreNames.length];
  return (
    name: name,
    longName: '이름이 꽤 길게 붙은 $name',
    guest: i.isOdd,
    weekdays: {i % 5 + 1, (i + 2) % 5 + 1},
    from: 9 + i % 5,
    to: 13 + i % 5,
    busy: {(i + 4) % 5 + 1},
  );
}

/// 견본 모임 화면의 값. [viewer]가 나이고, [answers]명이 시간을 넣었다. [mine]이 아니면 내 칸은 비어 있다.
/// [viewer]가 [GridViewer.visitor]면 아무도 내가 아니다([gridShading]으로 사람 수만 보인다)
MeetingBoard gridBoard(
  MeetingRead meeting, {
  GridViewer viewer = GridViewer.member,
  GridAnswers answers = GridAnswers.few,
  bool mine = true,
  bool longNames = false,
}) {
  final grid = MeetingGrid.of(meeting);
  final selfIndex = switch (viewer) {
    GridViewer.owner => 0,
    GridViewer.member => 1,
    GridViewer.guest => 2,
    GridViewer.newcomer || GridViewer.visitor => -1,
  };
  final availability = [
    for (var i = 0; i < answers.count; i++)
      _availabilityOf(
        meeting,
        grid,
        i,
        longNames: longNames,
        empty: i == selfIndex && !mine,
      ),
  ];
  return MeetingBoard(
    meeting: meeting,
    availability: availability,
    userId: switch (viewer) {
      GridViewer.owner => 'user-0',
      GridViewer.member => 'user-1',
      GridViewer.newcomer => 'user-new',
      GridViewer.guest || GridViewer.visitor => null,
    },
    selfId: viewer == GridViewer.guest ? 'participant-2' : null,
    selfName: '새싹',
  );
}

AvailabilityRead _availabilityOf(
  MeetingRead meeting,
  MeetingGrid grid,
  int index, {
  required bool longNames,
  required bool empty,
}) {
  final person = _personAt(index);
  final id = 'participant-$index';
  TimeSlotKind? kindAt(MeetingCell cell) {
    final weekday = cell.day.weekday;
    if (person.busy.contains(weekday)) return TimeSlotKind.unavailable;
    if (!person.weekdays.contains(weekday)) return null;
    // 날짜별은 사람마다 한 주를 비워 날마다 농도가 다르게 보인다
    if (grid.mode == MeetingMode.daily &&
        (cell.day.day - 1) ~/ 7 == index % 3) {
      return null;
    }
    if (grid.mode != MeetingMode.hourly) return TimeSlotKind.available;
    final fits =
        cell.startMinute >= person.from * 60 &&
        cell.endMinute <= person.to * 60;
    return fits ? TimeSlotKind.available : null;
  }

  return AvailabilityRead(
    participant: ParticipantRead(
      id: id,
      meetingId: meeting.id,
      displayName: longNames ? person.longName : person.name,
      createdAt: meeting.createdAt,
      isOwner: index == 0,
      isGuest: person.guest,
      userId: person.guest ? null : 'user-$index',
    ),
    timeSlots: [
      if (!empty)
        for (final cell in grid.cells)
          if (kindAt(cell) case final kind?)
            TimeSlotRead(
              id: '$id-${cell.index}',
              participantId: id,
              startTime: cell.span.start,
              endTime: cell.span.end,
              kind: kind,
            ),
    ],
  );
}

/// [viewer]가 보는 격자 값. 로그인 전이면 이름 없이 칸마다 사람 수만 있다
MeetingShading gridShading(MeetingBoard board, GridViewer viewer) =>
    viewer == GridViewer.visitor ? _Headcount(board) : board;

/// 로그인 전 방문자가 보는 값: 모든 참여자가 다른 사람이고 내 칸은 없다
class _Headcount implements MeetingShading {
  _Headcount(this._board);

  final MeetingBoard _board;

  @override
  MeetingGrid get grid => _board.grid;

  @override
  bool get hasSelf => false;

  @override
  int get othersTotal => _board.othersTotal;

  @override
  int othersCountAt(MeetingCell cell) => _board.othersCountAt(cell);

  @override
  int othersUnavailableCountAt(MeetingCell cell) =>
      _board.othersUnavailableCountAt(cell);

  @override
  MeetingAnswer answerAt(MeetingCell cell) => MeetingAnswer.unanswered;
}

/// 칠하면 칸이 바뀌고 참여자를 빼면 사라지도록 모임 화면 값과 추천 시간 강조를 쥔다. 노브를 바꿔 처음부터
/// 다시 보이려면 부르는 쪽이 [key]를 바꾼다
class GridHost extends StatefulWidget {
  const GridHost({
    super.key,
    required this.board,
    required this.builder,
    this.pinFirst = false,
  });

  final MeetingBoard board;

  /// 처음에 모모밋 추천 첫 카드를 고정해 둔다
  final bool pinFirst;
  final Widget Function(BuildContext context, GridHostState host) builder;

  @override
  State<GridHost> createState() => GridHostState();
}

class GridHostState extends State<GridHost> {
  late var board = widget.board;
  final highlight = MeetingRunHighlight();

  @override
  void initState() {
    super.initState();
    if (!widget.pinFirst) return;
    final runs = board.runs(MeetingRunOrder.recommended);
    if (runs.isNotEmpty) highlight.toggle(meetingRunKey(runs.first));
  }

  @override
  void dispose() {
    highlight.dispose();
    super.dispose();
  }

  /// 앱의 칠하기처럼 내 시간에 [changes]를 덮는다
  void paint(Map<MeetingCell, MeetingAnswer> changes) => setState(
    () => board = board.withMine(
      board.mine.paint({
        for (final MapEntry(key: cell, value: answer) in changes.entries)
          cell.span: answer,
      }),
    ),
  );

  /// 주인이 [participant]를 뺀다
  void remove(ParticipantRead participant) => setState(
    () => board = board.withRemoving({...board.removing, participant.id}),
  );

  @override
  Widget build(BuildContext context) => widget.builder(context, this);
}
