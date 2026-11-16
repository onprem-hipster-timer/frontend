// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'availability_cell.freezed.dart';
part 'availability_cell.g.dart';

/// 결과 그리드의 칸 [start_time, end_time)과 그 칸을 모두 덮는 가능 시간을 가진 참여자 수
@Freezed()
abstract class AvailabilityCell with _$AvailabilityCell {
  const factory AvailabilityCell({
    @JsonKey(name: 'start_time') required DateTime startTime,
    @JsonKey(name: 'end_time') required DateTime endTime,
    required int count,
  }) = _AvailabilityCell;

  factory AvailabilityCell.fromJson(Map<String, Object?> json) =>
      _$AvailabilityCellFromJson(json);
}
