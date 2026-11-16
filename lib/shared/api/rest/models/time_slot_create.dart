// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'time_slot_create.freezed.dart';
part 'time_slot_create.g.dart';

/// 가능 시간 생성 DTO: 반열린 구간 [start_time, end_time). 시간대가 없는 값은 UTC로 읽는다
@Freezed()
abstract class TimeSlotCreate with _$TimeSlotCreate {
  const factory TimeSlotCreate({
    @JsonKey(name: 'start_time') required DateTime startTime,
    @JsonKey(name: 'end_time') required DateTime endTime,
  }) = _TimeSlotCreate;

  factory TimeSlotCreate.fromJson(Map<String, Object?> json) =>
      _$TimeSlotCreateFromJson(json);
}
