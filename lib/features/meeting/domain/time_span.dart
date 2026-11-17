import 'package:flutter/foundation.dart';

/// 반열린 시각 구간 [start, end). 두 시각은 UTC로 바꿔 담는다
@immutable
class TimeSpan {
  TimeSpan(DateTime start, DateTime end) : start = _utc(start), end = _utc(end);

  final DateTime start;
  final DateTime end;

  Duration get length => end.difference(start);

  /// 끝이 시작보다 뒤가 아니다
  bool get isEmpty => !end.isAfter(start);

  @override
  bool operator ==(Object other) =>
      other is TimeSpan && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);

  @override
  String toString() =>
      'TimeSpan(${start.toIso8601String()}, ${end.toIso8601String()})';

  /// 시간대 객체(TZDateTime 등)도 같은 순간의 기본 UTC 시각으로 맞춰 == 비교가 되게 한다
  static DateTime _utc(DateTime value) => DateTime.fromMicrosecondsSinceEpoch(
    value.microsecondsSinceEpoch,
    isUtc: true,
  );
}

/// 겹치거나 맞닿은 구간을 합쳐 시작 순으로 돌려준다. 빈 구간은 버린다
List<TimeSpan> mergeSpans(Iterable<TimeSpan> spans) {
  final sorted = spans.where((span) => !span.isEmpty).toList()
    ..sort((a, b) => a.start.compareTo(b.start));
  final merged = <TimeSpan>[];
  for (final span in sorted) {
    final last = merged.isEmpty ? null : merged.last;
    if (last == null || span.start.isAfter(last.end)) {
      merged.add(span);
    } else if (span.end.isAfter(last.end)) {
      merged.last = TimeSpan(last.start, span.end);
    }
  }
  return merged;
}

/// [merged]([mergeSpans]의 결과) 중 하나가 [target]을 모두 덮는지
bool spansCover(List<TimeSpan> merged, TimeSpan target) => merged.any(
  (span) => !span.start.isAfter(target.start) && !span.end.isBefore(target.end),
);

/// [spans]에서 [removed]가 덮는 부분을 뺀 합친 구간
List<TimeSpan> subtractSpans(
  Iterable<TimeSpan> spans,
  Iterable<TimeSpan> removed,
) {
  final cuts = mergeSpans(removed);
  final result = <TimeSpan>[];
  for (final span in mergeSpans(spans)) {
    var from = span.start;
    for (final cut in cuts) {
      if (!cut.end.isAfter(from)) continue;
      if (!cut.start.isBefore(span.end)) break;
      if (cut.start.isAfter(from)) result.add(TimeSpan(from, cut.start));
      from = cut.end;
    }
    if (from.isBefore(span.end)) result.add(TimeSpan(from, span.end));
  }
  return result;
}
