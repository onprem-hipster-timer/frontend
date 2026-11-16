import 'package:flutter/foundation.dart';
import 'package:momeet/features/meeting/domain/meeting_grid.dart';
import 'package:momeet/features/meeting/domain/meeting_runs.dart';
import 'package:momeet/features/meeting/domain/my_availability.dart';
import 'package:momeet/features/meeting/domain/time_span.dart';
import 'package:momeet/shared/api/rest/export.dart';

/// 모임 화면의 값: 미팅과 격자, 참여자, 칸마다 되는 다른 참여자, 내 가능 시간.
///
/// 아직 참여하지 않았어도 칠하면 내 칸은 [selfName]의 [pendingSelfId]로 사람 수와 후보에 든다.
///
/// 테스트: test/features/meeting/domain/meeting_board_test.dart
@immutable
class MeetingBoard {
  factory MeetingBoard({
    required MeetingRead meeting,
    required List<AvailabilityRead> availability,
    required String? userId,
    required String selfName,
  }) => MeetingBoard._read(
    meeting: meeting,
    grid: MeetingGrid.of(meeting),
    availability: availability,
    userId: userId,
    selfName: selfName,
    edits: null,
  );

  factory MeetingBoard._read({
    required MeetingRead meeting,
    required MeetingGrid grid,
    required List<AvailabilityRead> availability,
    required String? userId,
    required String selfName,
    required MyAvailability? edits,
  }) {
    ParticipantRead? me;
    var mySlots = const <TimeSpan>[];
    final others = [for (final _ in grid.cells) <String>{}];
    for (final entry in availability) {
      final participant = entry.participant;
      final slots = mergeSpans([
        for (final slot in entry.timeSlots)
          TimeSpan(slot.startTime, slot.endTime),
      ]);
      if (userId != null && participant.userId == userId) {
        me = participant;
        mySlots = slots;
        continue;
      }
      for (final cell in grid.cells) {
        if (spansCover(slots, cell.span)) {
          others[cell.index].add(participant.id);
        }
      }
    }
    return MeetingBoard._(
      meeting: meeting,
      grid: grid,
      participants: _ownerFirst([
        for (final entry in availability) entry.participant,
      ], meeting.ownerId),
      me: me,
      others: others,
      mine: edits?.withSaved(mySlots) ?? MyAvailability(saved: mySlots),
      userId: userId,
      selfName: selfName,
    );
  }

  const MeetingBoard._({
    required this.meeting,
    required this.grid,
    required this.participants,
    required this.me,
    required List<Set<String>> others,
    required this.mine,
    required String? userId,
    required this.selfName,
  }) : _others = others,
       _userId = userId;

  /// 아직 참여하지 않은 나를 [peopleAt]에서 가리키는 값
  static const pendingSelfId = '';

  final MeetingRead meeting;
  final MeetingGrid grid;

  /// 참여자. 주인이 맨 앞이고 그다음은 받은 순서다
  final List<ParticipantRead> participants;

  /// 나의 참여자. 아직 참여하지 않았으면 null
  final ParticipantRead? me;

  /// 내 가능 시간(저장된 것 + 이 화면에서 칠하고 지운 것)
  final MyAvailability mine;

  /// 참여하지 않았을 때 쓰는 내 이름
  final String selfName;

  final List<Set<String>> _others;
  final String? _userId;

  /// 나를 뺀 참여자 수
  int get othersTotal => participants.length - (me == null ? 0 : 1);

  /// [cell]에서 되는 다른 참여자
  Set<String> othersAt(MeetingCell cell) => _others[cell.index];

  bool isMine(MeetingCell cell) => mine.has(cell.span);

  /// [cell]에서 되는 사람. 내 칸이면 나도 든다
  Set<String> peopleAt(MeetingCell cell) => {
    ..._others[cell.index],
    if (isMine(cell)) me?.id ?? pendingSelfId,
  };

  /// 두 명 이상 되는 이어진 칸 묶음, [order] 순
  List<MeetingRun> runs(MeetingRunOrder order) =>
      sortMeetingRuns(findMeetingRuns(grid, peopleAt), order);

  bool isSelf(String id) => id == pendingSelfId || id == me?.id;

  bool isOwner(ParticipantRead participant) =>
      participant.userId != null && participant.userId == meeting.ownerId;

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
        selfName: selfName,
        edits: mine,
      );

  MeetingBoard withMine(MyAvailability mine) => _copy(mine: mine);

  /// 참여했거나 이름을 바꾼 나([participant])를 참여자에 넣는다. 이미 있으면 그 자리, 처음이면 맨 뒤다
  MeetingBoard withSelf(ParticipantRead participant) {
    final next = [...participants];
    final at = next.indexWhere((p) => p.id == participant.id);
    if (at < 0) {
      next.add(participant);
    } else {
      next[at] = participant;
    }
    return _copy(
      me: participant,
      participants: _ownerFirst(next, meeting.ownerId),
    );
  }

  MeetingBoard _copy({
    ParticipantRead? me,
    List<ParticipantRead>? participants,
    MyAvailability? mine,
  }) => MeetingBoard._(
    meeting: meeting,
    grid: grid,
    participants: participants ?? this.participants,
    me: me ?? this.me,
    others: _others,
    mine: mine ?? this.mine,
    userId: _userId,
    selfName: selfName,
  );

  /// 주인을 맨 앞으로 옮기고 나머지 순서는 그대로 둔다
  static List<ParticipantRead> _ownerFirst(
    List<ParticipantRead> participants,
    String? ownerId,
  ) {
    if (ownerId == null) return participants;
    final ordered = [...participants];
    final owner = ordered.indexWhere((p) => p.userId == ownerId);
    if (owner > 0) ordered.insert(0, ordered.removeAt(owner));
    return ordered;
  }
}
