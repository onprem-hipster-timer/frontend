// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'time_slot_read.freezed.dart';
part 'time_slot_read.g.dart';

/// 시간 슬롯 조회 DTO
@Freezed()
abstract class TimeSlotRead with _$TimeSlotRead {
  const factory TimeSlotRead({
    required String id,
    @JsonKey(name: 'participant_id') required String participantId,
    @JsonKey(name: 'slot_date') required DateTime slotDate,
    @JsonKey(name: 'start_time') required String startTime,
    @JsonKey(name: 'end_time') required String endTime,
  }) = _TimeSlotRead;

  factory TimeSlotRead.fromJson(Map<String, Object?> json) =>
      _$TimeSlotReadFromJson(json);
}
