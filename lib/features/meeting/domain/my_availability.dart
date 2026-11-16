import 'package:flutter/foundation.dart';
import 'package:momeet/features/meeting/domain/time_span.dart';

/// 내 가능 시간. 저장된 구간([saved]) 위에 이번에 칠하거나 지운 칸([edits])을 덮어 읽는다.
///
/// 칠하거나 지운 칸만 그 칸의 구간을 통째로 바꾸고, 건드리지 않은 시각은 저장된 그대로 둔다.
/// 그래서 격자 밖의 가능 시간이나 칸의 일부만 덮는 가능 시간도 그 칸을 건드리기 전에는 남는다.
///
/// 테스트: test/features/meeting/domain/my_availability_test.dart
@immutable
class MyAvailability {
  MyAvailability({Iterable<TimeSpan> saved = const []})
    : this._(mergeSpans(saved), const {});

  const MyAvailability._(this.saved, this.edits);

  /// 저장된 가능 시간(합친 구간)
  final List<TimeSpan> saved;

  /// 칸 구간마다 칠했으면 true, 지웠으면 false
  final Map<TimeSpan, bool> edits;

  /// [cell] 칸이 내 시간인지. 건드리지 않은 칸은 저장된 구간이 칸을 모두 덮어야 내 시간이다
  bool has(TimeSpan cell) => edits[cell] ?? spansCover(saved, cell);

  /// [cells]를 칠하거나([available]) 지운다
  MyAvailability paint(Iterable<TimeSpan> cells, {required bool available}) =>
      MyAvailability._(
        saved,
        Map.unmodifiable({...edits, for (final cell in cells) cell: available}),
      );

  /// 저장된 가능 시간을 바꾼다. 칠하거나 지운 칸은 그대로 덮는다
  MyAvailability withSaved(Iterable<TimeSpan> saved) =>
      MyAvailability._(mergeSpans(saved), edits);

  /// 저장할 가능 시간 전체(`PUT /availability` 본문). 맞닿은 칸은 한 구간으로 합친다
  List<TimeSpan> get slots => mergeSpans([
    ...subtractSpans(saved, edits.keys),
    for (final MapEntry(key: cell, value: available) in edits.entries)
      if (available) cell,
  ]);
}
