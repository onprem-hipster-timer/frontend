// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'meeting_update.freezed.dart';
part 'meeting_update.g.dart';

/// 일정 조율 업데이트 DTO
@Freezed()
abstract class MeetingUpdate with _$MeetingUpdate {
  const factory MeetingUpdate({
    String? title,
    String? description,
    @JsonKey(name: 'start_date') DateTime? startDate,
    @JsonKey(name: 'end_date') DateTime? endDate,
    @JsonKey(name: 'available_days') List<int>? availableDays,
    @JsonKey(name: 'start_time') String? startTime,
    @JsonKey(name: 'end_time') String? endTime,
    @JsonKey(name: 'time_slot_minutes') int? timeSlotMinutes,
  }) = _MeetingUpdate;

  factory MeetingUpdate.fromJson(Map<String, Object?> json) =>
      _$MeetingUpdateFromJson(json);
}
