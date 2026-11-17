import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:momeet/features/meeting/domain/meeting_grid.dart';
import 'package:momeet/features/meeting/domain/meeting_shading.dart';
import 'package:momeet/features/meeting/domain/my_availability.dart';
import 'package:momeet/shared/api/rest/export.dart';

/// 로그인하지 않은 방문자가 보는 격자 값: 결과(`GET /result`)의 칸마다 되는(`count`)·안 되는(`unavailable_count`)
/// 사람 수와 참여자 수. 이름은 없다.
///
/// 격자 칸은 결과 칸과 같은 미팅 규칙으로 만든다. 날짜별·요일별 칸(하루 범위 전체)처럼 결과 칸 여럿을 덮는
/// 칸은 그 안의 결과 칸 중 가장 적은 되는 사람 수(하루 전체가 되는 사람만)와 가장 많은 안 되는 사람 수(하루의
/// 일부라도 안 되는 사람)다.
///
/// 테스트: test/features/meeting/domain/meeting_headcount_test.dart
@immutable
class MeetingHeadcount implements MeetingShading {
  factory MeetingHeadcount(MeetingResultRead result) {
    final grid = MeetingGrid.of(result.meeting);
    final cells = result.availabilityGrid;
    return MeetingHeadcount._(
      meeting: result.meeting,
      grid: grid,
      participantCount: result.participantCount,
      counts: [
        for (final cell in grid.cells)
          _within(cells, cell)
                  .map((counted) => counted.count)
                  .fold<int?>(
                    null,
                    (least, count) =>
                        least == null ? count : math.min(least, count),
                  ) ??
              0,
      ],
      unavailableCounts: [
        for (final cell in grid.cells)
          _within(
            cells,
            cell,
          ).map((counted) => counted.unavailableCount).fold(0, math.max),
      ],
    );
  }

  /// [cell] 안에 드는 결과 칸
  static Iterable<AvailabilityCell> _within(
    List<AvailabilityCell> cells,
    MeetingCell cell,
  ) => cells.where(
    (counted) =>
        !counted.startTime.isBefore(cell.span.start) &&
        !counted.endTime.isAfter(cell.span.end),
  );

  const MeetingHeadcount._({
    required this.meeting,
    required this.grid,
    required this.participantCount,
    required List<int> counts,
    required List<int> unavailableCounts,
  }) : _counts = counts,
       _unavailableCounts = unavailableCounts;

  final MeetingRead meeting;

  @override
  final MeetingGrid grid;

  /// 참여자 수. 가능 시간을 넣지 않은 참여자도 든다
  final int participantCount;

  final List<int> _counts;
  final List<int> _unavailableCounts;

  @override
  bool get hasSelf => false;

  @override
  int get othersTotal => participantCount;

  @override
  int othersCountAt(MeetingCell cell) => _counts[cell.index];

  @override
  int othersUnavailableCountAt(MeetingCell cell) =>
      _unavailableCounts[cell.index];

  @override
  MeetingAnswer answerAt(MeetingCell cell) => MeetingAnswer.unanswered;
}
