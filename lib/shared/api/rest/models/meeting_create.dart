// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'meeting_create.freezed.dart';
part 'meeting_create.g.dart';

/// 일정 조율 생성 DTO
@Freezed()
abstract class MeetingCreate with _$MeetingCreate {
  const factory MeetingCreate({
    required String title,
    @JsonKey(name: 'start_date') required DateTime startDate,
    @JsonKey(name: 'end_date') required DateTime endDate,
    @JsonKey(name: 'available_days') required List<int> availableDays,
    @JsonKey(name: 'start_time') required String startTime,
    @JsonKey(name: 'end_time') required String endTime,
    @JsonKey(name: 'time_slot_minutes') @Default(30) int timeSlotMinutes,
    String? description,
  }) = _MeetingCreate;

  factory MeetingCreate.fromJson(Map<String, Object?> json) =>
      _$MeetingCreateFromJson(json);
}
