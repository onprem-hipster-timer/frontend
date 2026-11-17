import 'package:flutter/foundation.dart';
import 'package:momeet/features/meeting/domain/meeting_grid.dart';
import 'package:momeet/features/meeting/domain/meeting_runs.dart';
import 'package:momeet/features/meeting/domain/meeting_shading.dart';
import 'package:momeet/features/meeting/domain/my_availability.dart';
import 'package:momeet/features/meeting/domain/time_span.dart';
import 'package:momeet/shared/api/rest/export.dart';

/// 모임 화면의 값: 미팅과 격자, 참여자, 칸마다 되는·안 되는 다른 참여자, 내 시간.
///
/// 나는 회원이면 [userId]가 같은 참여자, 게스트면 참여해 받은 참여자 id([selfId])다(게스트가 받는 응답에는 회원
/// id가 없다). 아직 참여하지 않았어도 칠하면 내 칸은 [selfName]의 [pendingSelfId]로 사람 수와 후보에 든다.
/// 빼는 중인 참여자([removing])는 참여자·칸·후보 어디에도 들지 않는다.
///
/// 테스트: test/features/meeting/domain/meeting_board_test.dart
@immutable
class MeetingBoard implements MeetingShading {
  factory MeetingBoard({
    required MeetingRead meeting,
    required List<AvailabilityRead> availability,
    required String? userId,
    required String selfName,
    String? selfId,
  }) => MeetingBoard._read(
    meeting: meeting,
    grid: MeetingGrid.of(meeting),
    availability: availability,
    userId: userId,
    selfId: selfId,
    selfName: selfName,
    edits: null,
    removing: const {},
  );

  factory MeetingBoard._read({
    required MeetingRead meeting,
    required MeetingGrid grid,
    required List<AvailabilityRead> availability,
    required String? userId,
    required String? selfId,
    required String selfName,
    required MyAvailability? edits,
    required Set<String> removing,
  }) {
    ParticipantRead? me;
    var mine = MyAvailability();
    final others = [for (final _ in grid.cells) <String>{}];
    final othersUnavailable = [for (final _ in grid.cells) <String>{}];
    for (final entry in availability) {
      final participant = entry.participant;
      List<TimeSpan> spansOf(TimeSlotKind kind) => mergeSpans([
        for (final slot in entry.timeSlots)
          if (slot.kind == kind) TimeSpan(slot.startTime, slot.endTime),
      ]);
      final yes = spansOf(TimeSlotKind.available);
      final no = spansOf(TimeSlotKind.unavailable);
      if ((userId != null && participant.userId == userId) ||
          (selfId != null && participant.id == selfId)) {
        me = participant;
        mine = MyAvailability(available: yes, unavailable: no);
        continue;
      }
      for (final cell in grid.cells) {
        if (spansCover(yes, cell.span)) {
          others[cell.index].add(participant.id);
        } else if (spansCover(no, cell.span)) {
          othersUnavailable[cell.index].add(participant.id);
        }
      }
    }
    return MeetingBoard._(
      meeting: meeting,
      grid: grid,
      participants: _ownerFirst([
        for (final entry in availability) entry.participant,
      ]),
      me: me,
      others: others,
      othersUnavailable: othersUnavailable,
      mine:
          edits?.withSaved(
            available: mine.available,
            unavailable: mine.unavailable,
          ) ??
          mine,
      userId: userId,
      selfId: selfId,
      selfName: selfName,
      removing: removing,
    );
  }

  MeetingBoard._({
    required this.meeting,
    required this.grid,
    required List<ParticipantRead> participants,
    required this.me,
    required List<Set<String>> others,
    required List<Set<String>> othersUnavailable,
    required this.mine,
    required String? userId,
    required String? selfId,
    required this.selfName,
    required this.removing,
  }) : _all = participants,
       participants = removing.isEmpty
           ? participants
           : [
               for (final participant in participants)
                 if (!removing.contains(participant.id)) participant,
             ],
       _others = others,
       _othersUnavailable = othersUnavailable,
       _userId = userId,
       _selfId = selfId;

  /// 아직 참여하지 않은 나를 [peopleAt]에서 가리키는 값
  static const pendingSelfId = '';

  final MeetingRead meeting;
  @override
  final MeetingGrid grid;

  /// 참여자. 주인이 맨 앞이고 그다음은 받은 순서다
  final List<ParticipantRead> participants;

  /// 빼는 중인(되돌릴 수 있는) 참여자 id
  final Set<String> removing;

  /// 나의 참여자. 아직 참여하지 않았으면 null
  final ParticipantRead? me;

  /// 내 시간(저장된 것 + 이 화면에서 칠하고 지운 것)
  final MyAvailability mine;

  /// 참여하지 않았을 때 쓰는 내 이름
  final String selfName;

  /// 빼는 중인 참여자도 든 참여자
  final List<ParticipantRead> _all;
  final List<Set<String>> _others;
  final List<Set<String>> _othersUnavailable;
  final String? _userId;
  final String? _selfId;

  /// 로그인한 내가 만든 모임인지. 로그인하지 않은 방문자와 게스트는 주인 id를 받지 않아 늘 false다
  bool get ownedByMe => _userId != null && meeting.ownerId == _userId;

  @override
  bool get hasSelf => true;

  /// 나를 뺀 참여자 수
  @override
  int get othersTotal => participants.length - (me == null ? 0 : 1);

  /// [cell]에서 되는 다른 참여자
  Set<String> othersAt(MeetingCell cell) => removing.isEmpty
      ? _others[cell.index]
      : _others[cell.index].difference(removing);

  @override
  int othersCountAt(MeetingCell cell) => othersAt(cell).length;

  /// [cell]이 안 된다고 한 다른 참여자
  Set<String> othersUnavailableAt(MeetingCell cell) => removing.isEmpty
      ? _othersUnavailable[cell.index]
      : _othersUnavailable[cell.index].difference(removing);

  @override
  int othersUnavailableCountAt(MeetingCell cell) =>
      othersUnavailableAt(cell).length;

  @override
  MeetingAnswer answerAt(MeetingCell cell) => mine.answerAt(cell.span);

  /// [cell]에서 되는 사람. 내 칸이 가능이면 나도 든다
  Set<String> peopleAt(MeetingCell cell) => {
    ...othersAt(cell),
    if (answerAt(cell) == MeetingAnswer.available) me?.id ?? pendingSelfId,
  };

  /// [run]의 칸 중 하나라도 안 된다고 한 사람. 내 칸이 불가능이면 나도 든다
  Set<String> unavailableIn(MeetingRun run) => {
    for (final cell in run.cells) ...[
      ...othersUnavailableAt(cell),
      if (answerAt(cell) == MeetingAnswer.unavailable) me?.id ?? pendingSelfId,
    ],
  };

  /// 두 명 이상 되는 이어진 칸 묶음, [order] 순
  List<MeetingRun> runs(MeetingRunOrder order) =>
      sortMeetingRuns(findMeetingRuns(grid, peopleAt), order);

  bool isSelf(String id) => id == pendingSelfId || id == me?.id;

  /// [id] 참여자의 이름
  String nameOf(String id) {
    if (id == pendingSelfId) return selfName;
    for (final participant in participants) {
      if (participant.id == id) return participant.displayName;
    }
    return '';
  }

  /// 다시 받은 참여자와 가능 시간으로 바꾼다. 칠하고 지운 칸은 그대로 덮는다
  MeetingBoard withAvailability(List<AvailabilityRead> availability) =>
      MeetingBoard._read(
        meeting: meeting,
        grid: grid,
        availability: availability,
        userId: _userId,
        selfId: _selfId,
        selfName: selfName,
        edits: mine,
        removing: removing,
      );

  MeetingBoard withMine(MyAvailability mine) => _copy(mine: mine);

  /// 빼는 중인 참여자를 [ids]로 바꾼다
  MeetingBoard withRemoving(Set<String> ids) => _copy(removing: ids);

  /// 참여했거나 이름을 바꾼 나([participant])를 참여자에 넣는다. 이미 있으면 그 자리, 처음이면 맨 뒤다
  MeetingBoard withSelf(ParticipantRead participant) {
    final next = [..._all];
    final at = next.indexWhere((p) => p.id == participant.id);
    if (at < 0) {
      next.add(participant);
    } else {
      next[at] = participant;
    }
    return _copy(me: participant, participants: _ownerFirst(next));
  }

  MeetingBoard _copy({
    ParticipantRead? me,
    List<ParticipantRead>? participants,
    MyAvailability? mine,
    Set<String>? removing,
  }) => MeetingBoard._(
    meeting: meeting,
    grid: grid,
    participants: participants ?? _all,
    me: me ?? this.me,
    others: _others,
    othersUnavailable: _othersUnavailable,
    mine: mine ?? this.mine,
    userId: _userId,
    selfId: _selfId,
    selfName: selfName,
    removing: removing ?? this.removing,
  );

  /// 주인(`is_owner`)을 맨 앞으로 옮기고 나머지 순서는 그대로 둔다. 회원 id는 받는 사람에 따라 비어 있어
  /// 비교하지 않는다
  static List<ParticipantRead> _ownerFirst(List<ParticipantRead> participants) {
    final ordered = [...participants];
    final owner = ordered.indexWhere((p) => p.isOwner);
    if (owner > 0) ordered.insert(0, ordered.removeAt(owner));
    return ordered;
  }
}
