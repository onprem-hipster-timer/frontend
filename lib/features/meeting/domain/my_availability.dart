import 'package:flutter/foundation.dart';
import 'package:momeet/features/meeting/domain/time_span.dart';

/// 내 칸 하나의 답
enum MeetingAnswer {
  /// 아직 답하지 않았다
  unanswered,

  /// 된다
  available,

  /// 안 된다
  unavailable,
}

/// 저장할 내 시간: 되는 구간과 안 되는 구간. 두 목록은 서로 겹치지 않는다(맞닿을 수는 있다)
typedef MeetingSlots = ({List<TimeSpan> available, List<TimeSpan> unavailable});

/// 내 시간. 저장된 구간(되는 [available]·안 되는 [unavailable]) 위에 이번에 칠하거나 지운 칸([edits])을 덮어 읽는다.
///
/// 칠하거나 지운 칸만 그 칸의 구간을 통째로 바꾸고, 건드리지 않은 시각은 저장된 그대로 둔다.
/// 그래서 격자 밖의 시간이나 칸의 일부만 덮는 시간도 그 칸을 건드리기 전에는 남는다.
///
/// 테스트: test/features/meeting/domain/my_availability_test.dart
@immutable
class MyAvailability {
  MyAvailability({
    Iterable<TimeSpan> available = const [],
    Iterable<TimeSpan> unavailable = const [],
  }) : this._(mergeSpans(available), mergeSpans(unavailable), const {});

  const MyAvailability._(this.available, this.unavailable, this.edits);

  /// 저장된 되는 구간(합친 구간)
  final List<TimeSpan> available;

  /// 저장된 안 되는 구간(합친 구간)
  final List<TimeSpan> unavailable;

  /// 칸 구간마다 칠하거나 지운 답
  final Map<TimeSpan, MeetingAnswer> edits;

  /// [cell] 칸의 답. 건드리지 않은 칸은 저장된 구간 하나가 칸을 모두 덮어야 그 답이다(되는 구간이 먼저)
  MeetingAnswer answerAt(TimeSpan cell) =>
      edits[cell] ??
      (spansCover(available, cell)
          ? MeetingAnswer.available
          : spansCover(unavailable, cell)
          ? MeetingAnswer.unavailable
          : MeetingAnswer.unanswered);

  /// 칸마다 [changes]의 답으로 칠하거나 지운다([MeetingAnswer.unanswered])
  MyAvailability paint(Map<TimeSpan, MeetingAnswer> changes) =>
      MyAvailability._(
        available,
        unavailable,
        Map.unmodifiable({...edits, ...changes}),
      );

  /// 저장된 구간을 바꾼다. 칠하거나 지운 칸은 그대로 덮는다
  MyAvailability withSaved({
    required Iterable<TimeSpan> available,
    required Iterable<TimeSpan> unavailable,
  }) => MyAvailability._(mergeSpans(available), mergeSpans(unavailable), edits);

  /// 저장할 시간 전체(`PUT /availability` 본문). 맞닿은 칸은 한 구간으로 합치고, 안 되는 구간은 되는 구간과
  /// 겹치는 부분을 잘라 낸다
  MeetingSlots get slots {
    List<TimeSpan> of(List<TimeSpan> saved, MeetingAnswer answer) =>
        mergeSpans([
          ...subtractSpans(saved, edits.keys),
          for (final MapEntry(key: cell, value: edited) in edits.entries)
            if (edited == answer) cell,
        ]);
    final yes = of(available, MeetingAnswer.available);
    return (
      available: yes,
      unavailable: subtractSpans(
        of(unavailable, MeetingAnswer.unavailable),
        yes,
      ),
    );
  }
}
