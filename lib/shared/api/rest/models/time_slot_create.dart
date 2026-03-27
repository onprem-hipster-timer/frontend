// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'time_slot_create.freezed.dart';
part 'time_slot_create.g.dart';

/// 시간 슬롯 생성 DTO
@Freezed()
abstract class TimeSlotCreate with _$TimeSlotCreate {
  const factory TimeSlotCreate({
    @JsonKey(name: 'slot_date') required DateTime slotDate,
    @JsonKey(name: 'start_time') required String startTime,
    @JsonKey(name: 'end_time') required String endTime,
  }) = _TimeSlotCreate;

  factory TimeSlotCreate.fromJson(Map<String, Object?> json) =>
      _$TimeSlotCreateFromJson(json);
}
